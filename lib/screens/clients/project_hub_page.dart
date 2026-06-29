// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../../services/customer_sync_service.dart';
import '../../services/workflow_service.dart';
import '../../services/contract_service.dart';
import '../../services/pdf_utils/receipt_builder.dart';
import '../../theme/app_theme.dart';
import '../../services/whatsapp_service.dart';
import '../../services/photo_notification_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'widgets/project_hub/project_hub_header.dart';
import 'widgets/project_hub/project_hub_chat_tab.dart';
import 'widgets/project_hub/project_hub_photos_tab.dart';
import 'widgets/project_hub/project_hub_overview_tab.dart';
import 'widgets/project_hub/project_hub_worker_rating.dart';
import 'package:flutter/services.dart';

class ProjectHubPage extends StatefulWidget {
  final Client client;

  const ProjectHubPage({
    super.key,
    required this.client,
  });

  @override
  State<ProjectHubPage> createState() => _ProjectHubPageState();
}

class _ProjectHubPageState extends State<ProjectHubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  List<String> _photos = [];
  bool _isLoadingChat = true;
  bool _isLoadingPhotos = true;
  bool _isUploading = false;
  Timer? _chatPollTimer;
  bool _isUpdatingStage = false;
  String _currentStage = 'Planning';

  // ── Overview Tab State ────────────────────────────────────────
  bool _isLoadingOverview = false;
  bool _isSavingProfile = false;
  bool _isSendingContract = false;
  bool _isGeneratingReceipt = false;
  bool _isSendingChangeOrder = false;
  bool _isCheckingInGps = false;

  // Client extensions
  String _customerType = 'Direct Customer';
  bool _gstEnabled = false;
  DateTime? _nextPaymentDueDate;
  double _discountAmount = 0.0;
  String _upiId = '';
  String _bankName = '';
  String _accountNumber = '';
  String _ifscCode = '';

  // Stage progress (stage → 0..100)
  final Map<String, int> _stageProgress = {
    'Framing': 0, 'Boarding': 0, 'Finishing': 0, 'Painting': 0, 'Cleanup': 0,
  };

  // Workflow data
  Map<String, dynamic>? _contractData;
  List<Map<String, dynamic>> _changeOrders = [];
  List<Map<String, dynamic>> _paymentReceipts = [];

  // Text controllers
  final TextEditingController _emailController     = TextEditingController();
  final TextEditingController _gstinController     = TextEditingController();
  final TextEditingController _discountController  = TextEditingController();
  final TextEditingController _changeDescController = TextEditingController();
  final TextEditingController _changeAmtController  = TextEditingController();
  final TextEditingController _receiptAmtController = TextEditingController();

  Timer? _workflowPollTimer;

  bool get isAdmin => AuthService.instance.userData?.role == UserRole.admin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        final role = AuthService.instance.userData?.role.name ?? 'admin';
        ClientService.instance.markMessagesAsRead(widget.client.unitNumber, role);
      }
    });

    _fetchMessages(initial: true);
    _fetchPhotos();
    _fetchProjectStage();
    _loadOverviewData();

    SharedPreferences.getInstance().then((prefs) {
      if (mounted) setState(() {
        _upiId         = prefs.getString('bank_upi_id')         ?? '';
        _bankName      = prefs.getString('bank_name')           ?? '';
        _accountNumber = prefs.getString('bank_account_number') ?? '';
        _ifscCode      = prefs.getString('bank_ifsc')           ?? '';
      });
    });

    _chatPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) _fetchMessages();
    });

    _workflowPollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _pollWorkflowData();
    });
  }

  @override
  void dispose() {
    _chatPollTimer?.cancel();
    _workflowPollTimer?.cancel();
    _messageController.dispose();
    _chatScrollController.dispose();
    _tabController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _discountController.dispose();
    _changeDescController.dispose();
    _changeAmtController.dispose();
    _receiptAmtController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool initial = false}) async {
    if (initial) setState(() => _isLoadingChat = true);
    try {
      final msgs = await ClientService.instance.fetchChatMessages(widget.client.unitNumber);
      if (mounted) {
        final wasEmpty = _messages.isEmpty;
        setState(() {
          _messages = msgs;
          _isLoadingChat = false;
        });
        if (initial || wasEmpty || msgs.length > _messages.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
        if (msgs.isNotEmpty) {
          final bool hasUnread = msgs.any((m) => m['sender'] == 'client' && m['status'] != 'read');
          if (hasUnread) {
            if (_tabController.index == 0) {
              ClientService.instance.markMessagesAsRead(widget.client.unitNumber, 'admin');
            } else {
              ClientService.instance.markMessagesAsDelivered(widget.client.unitNumber, 'admin');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChat = false);
    }
  }

  Future<void> _fetchPhotos() async {
    setState(() => _isLoadingPhotos = true);
    try {
      final imgs = await ClientService.instance.fetchProjectPhotos(widget.client.unitNumber);
      if (mounted) {
        setState(() {
          _photos = imgs;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _fetchProjectStage() async {
    try {
      final quotation = await CustomerSyncService.instance.getQuotationFromCloud(widget.client.unitNumber);
      if (quotation != null && mounted) {
        setState(() => _currentStage = quotation.projectStatus);
      }
    } catch (e) {
      debugPrint('Error loading project stage: $e');
    }
  }

  Future<void> _updateStage(String? newStage) async {
    if (newStage == null || newStage == _currentStage) return;
    setState(() => _isUpdatingStage = true);
    try {
      await ClientService.instance.updateProjectStatus(widget.client.unitNumber, newStage);
      if (mounted) {
        setState(() => _currentStage = newStage);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project stage updated to $newStage successfully!'), backgroundColor: AppColors.resultGreen));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update project stage. Please retry.'), backgroundColor: AppColors.alertRed));
    } finally {
      if (mounted) setState(() => _isUpdatingStage = false);
    }
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(_chatScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final user = AuthService.instance.userData;
    final sender = user?.role == UserRole.admin ? 'admin' : (user?.role == UserRole.worker ? 'worker' : 'client');
    _messageController.clear();
    try {
      final success = await ClientService.instance.sendChatMessage(widget.client.unitNumber, sender, text);
      if (success) {
        _fetchMessages();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message. Please retry.'), backgroundColor: AppColors.alertRed));
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _uploadProgressPhoto(ImageSource source) async {
    final picker = ImagePicker();
    try {
      List<XFile> images = [];
      if (source == ImageSource.camera) {
        final image = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1200);
        if (image != null) images.add(image);
      } else {
        final pickedImages = await picker.pickMultiImage(imageQuality: 75, maxWidth: 1200);
        if (pickedImages.isNotEmpty) images.addAll(pickedImages);
      }
      if (images.isEmpty) return;
      setState(() => _isUploading = true);
      int successCount = 0;
      for (int i = 0; i < images.length; i++) {
        final bytes = await images[i].readAsBytes();
        final cleanId = widget.client.unitNumber.toLowerCase();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'progress_${cleanId}_${timestamp}_$i.jpg';
        final publicUrl = await CustomerSyncService.instance.uploadProjectPhoto(bytes, fileName, folder: widget.client.unitNumber);
        if (publicUrl != null) successCount++;
      }
      if (successCount > 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$successCount photo(s) uploaded successfully!'), backgroundColor: AppColors.resultGreen));
        _fetchPhotos();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Please check network and permissions.'), backgroundColor: AppColors.alertRed));
      }
    } catch (e) {
      debugPrint('Photo upload exception: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showUploadBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('UPLOAD SITE PROGRESS PHOTO', style: TextStyle(color: AppColors.labelColor, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUploadOption(icon: Icons.camera_alt, label: 'CAMERA', onTap: () { Navigator.pop(context); _uploadProgressPhoto(ImageSource.camera); }),
                  _buildUploadOption(icon: Icons.photo_library, label: 'GALLERY', onTap: () { Navigator.pop(context); _uploadProgressPhoto(ImageSource.gallery); }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: AppColors.border.withValues(alpha: 0.3), width: 1.5), borderRadius: BorderRadius.circular(12), color: Colors.white),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.border),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppColors.labelColor, fontWeight: FontWeight.w900, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall() async {
    final url = Uri.parse('tel:${widget.client.phoneNumber}');
    try {
      if (await canLaunchUrl(url)) await launchUrl(url);
      else throw 'Could not launch dialer';
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to call client: $e'), backgroundColor: AppColors.alertRed));
    }
  }

  Future<void> _openWhatsApp() async {
    final cleanPhone = widget.client.phoneNumber.replaceAll(RegExp(r'\D'), '');
    final phoneWithCountry = cleanPhone.startsWith('91') ? cleanPhone : '91$cleanPhone';
    final whatsappUrl = Uri.parse("whatsapp://send?phone=$phoneWithCountry");
    final httpsUrl = Uri.parse("https://wa.me/$phoneWithCountry");
    try {
      if (await canLaunchUrl(whatsappUrl)) await launchUrl(whatsappUrl);
      else await launchUrl(httpsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open WhatsApp: $e'), backgroundColor: AppColors.alertRed));
    }
  }

  Future<void> _openInMaps() async {
    Uri url;
    if (widget.client.latitude != null && widget.client.longitude != null) {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.client.latitude},${widget.client.longitude}');
    } else {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.client.siteLocation)}');
    }
    try {
      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
      else throw 'Could not launch Maps';
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open Google Maps: $e'), backgroundColor: AppColors.alertRed));
    }
  }

  Future<void> _loadOverviewData() async {
    if (mounted) setState(() => _isLoadingOverview = true);
    final data = await WorkflowService.instance.pollProjectData(widget.client.unitNumber);
    if (!mounted) return;
    setState(() {
      _isLoadingOverview = false;
      final ext = data['extensions'] as Map<String, dynamic>?;
      if (ext != null) {
        _customerType    = ext['customer_type'] as String? ?? 'Direct Customer';
        _gstEnabled      = ext['gstin_enabled'] == true;
        _discountAmount  = (ext['discount_amount'] as num?)?.toDouble() ?? 0.0;
        _emailController.text    = ext['email']  as String? ?? '';
        _gstinController.text    = ext['gstin']  as String? ?? '';
        _discountController.text = _discountAmount > 0 ? _discountAmount.toStringAsFixed(0) : '';
        if (ext['next_payment_due_date'] != null) _nextPaymentDueDate = DateTime.tryParse(ext['next_payment_due_date'] as String);
        if (ext['upi_id'] != null && (ext['upi_id'] as String).isNotEmpty) _upiId = ext['upi_id']!;
        if (ext['bank_name'] != null && (ext['bank_name'] as String).isNotEmpty) _bankName = ext['bank_name']!;
        if (ext['account_number'] != null && (ext['account_number'] as String).isNotEmpty) _accountNumber = ext['account_number']!;
        if (ext['ifsc_code'] != null && (ext['ifsc_code'] as String).isNotEmpty) _ifscCode = ext['ifsc_code']!;
      }
      final stages = data['stages'] as List<Map<String, dynamic>>? ?? [];
      for (final s in stages) {
        final name = s['stage_name'] as String?;
        final pct  = (s['completion_percent'] as num?)?.toInt() ?? 0;
        if (name != null && _stageProgress.containsKey(name)) _stageProgress[name] = pct;
      }
      _contractData = data['contract'] as Map<String, dynamic>?;
      _changeOrders = (data['changeOrders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _paymentReceipts = (data['paymentReceipts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    });
  }

  Future<void> _pollWorkflowData() async {
    final data = await WorkflowService.instance.pollProjectData(widget.client.unitNumber);
    if (!mounted) return;
    final newContract = data['contract'] as Map<String, dynamic>?;
    final wasAwaitingSig = _contractData?['contract_status'] == 'pending_client_signature';
    final nowSigned      = newContract?['contract_status'] == 'signed_by_client';
    setState(() {
      _contractData    = newContract;
      _changeOrders    = (data['changeOrders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _paymentReceipts = (data['paymentReceipts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    });
    if (wasAwaitingSig && nowSigned && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ CONTRACT SIGNED — ${widget.client.clientName} has returned the signed contract!'), backgroundColor: AppColors.resultGreen, duration: const Duration(seconds: 5)));
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) return null;
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) { return null; }
  }

  Future<void> _doGpsCheckin() async {
    if (_isCheckingInGps) return;
    setState(() => _isCheckingInGps = true);
    final pos = await _getCurrentPosition();
    if (pos != null) {
      await WorkflowService.instance.logSiteVisit(unitNumber: widget.client.unitNumber, latitude: pos.latitude, longitude: pos.longitude, actionType: 'manual_checkin', actionDetail: 'Admin checked in manually');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📍 Checked in at ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'), backgroundColor: AppColors.resultGreen));
    } else if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not get GPS location. Check permissions.'), backgroundColor: AppColors.alertRed));
    if (mounted) setState(() => _isCheckingInGps = false);
  }

  Future<void> _saveClientProfile() async {
    setState(() => _isSavingProfile = true);
    final ok = await WorkflowService.instance.saveClientExtensions(widget.client.unitNumber, email: _emailController.text.trim(), customerType: _customerType, gstEnabled: _gstEnabled, gstin: _gstinController.text.trim(), nextPaymentDueDate: _nextPaymentDueDate, discountAmount: double.tryParse(_discountController.text.trim()) ?? 0.0, upiId: _upiId.isNotEmpty ? _upiId : null, bankName: _bankName.isNotEmpty ? _bankName : null, accountNumber: _accountNumber.isNotEmpty ? _accountNumber : null, ifscCode: _ifscCode.isNotEmpty ? _ifscCode : null);
    if (mounted) {
      setState(() { _isSavingProfile = false; _discountAmount = double.tryParse(_discountController.text.trim()) ?? 0.0; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '✅ Profile saved successfully' : 'Failed to save profile. Retry.'), backgroundColor: ok ? AppColors.resultGreen : AppColors.alertRed));
    }
  }

  Future<void> _saveStageProgress() async {
    setState(() => _isUpdatingStage = true);
    _getCurrentPosition().then((pos) {
      if (pos != null) WorkflowService.instance.logSiteVisit(unitNumber: widget.client.unitNumber, latitude: pos.latitude, longitude: pos.longitude, actionType: 'stage_update', actionDetail: _stageProgress.entries.map((e) => '${e.key}:${e.value}%').join(', '));
    });
    final ok = await WorkflowService.instance.saveStageProgress(widget.client.unitNumber, Map<String, int>.from(_stageProgress));
    if (ok) {
      final avg = _stageProgress.values.fold(0, (a, b) => a + b) / _stageProgress.length;
      final milestones = [25, 50, 75, 100];
      for (var m in milestones) {
        if (avg >= m && avg < (m + 10)) {
           WhatsAppService.instance.notifyProgressMilestone(phone: widget.client.phoneNumber, siteName: widget.client.unitNumber, progress: avg);
           PhotoNotificationService.instance.showTextNotification(title: 'Project Milestone: Site ${widget.client.unitNumber}', body: 'Overall progress has reached ${avg.toStringAsFixed(0)}%.');
        }
      }
    }
    if (mounted) {
      setState(() => _isUpdatingStage = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '✅ Stage progress updated — client can see live updates' : 'Stage update failed.'), backgroundColor: ok ? AppColors.resultGreen : AppColors.alertRed));
    }
  }

  Future<void> _sendContractForSignature() async {
    setState(() => _isSendingContract = true);
    final quotation = await CustomerSyncService.instance.getQuotationFromCloud(widget.client.unitNumber);
    if (quotation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No quotation found for this client. Generate one first.'), backgroundColor: AppColors.alertRed));
        setState(() => _isSendingContract = false);
      }
      return;
    }
    final token = await ContractService.instance.uploadUnsignedContract(quotation);
    if (mounted) {
      setState(() => _isSendingContract = false);
      if (token != null) { await ContractService.instance.shareContractLink(token, widget.client.clientName); _pollWorkflowData(); }
      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract upload failed. Check network and retry.'), backgroundColor: AppColors.alertRed));
    }
  }

  Future<void> _sendChangeOrder() async {
    final desc = _changeDescController.text.trim();
    final amount = double.tryParse(_changeAmtController.text.trim());
    if (desc.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a description and a valid amount.'), backgroundColor: AppColors.alertRed));
      return;
    }
    setState(() => _isSendingChangeOrder = true);
    final receiptBytes = await ReceiptBuilder.generateBytes(receiptNumber: 'CHG-${DateTime.now().millisecondsSinceEpoch}', unitNumber: widget.client.unitNumber, clientName: widget.client.clientName, clientPhone: widget.client.phoneNumber, amountReceived: amount, totalPaidToDate: 0, balanceRemaining: amount, paymentMode: 'Other', notes: 'CHANGE ORDER: $desc');
    if (receiptBytes == null) { if (mounted) setState(() => _isSendingChangeOrder = false); return; }
    final row = await WorkflowService.instance.createChangeOrder(unitNumber: widget.client.unitNumber, description: desc, extraAmount: amount, pdfBytes: Uint8List.fromList(receiptBytes));
    if (mounted) {
      setState(() => _isSendingChangeOrder = false);
      if (row != null) { _changeDescController.clear(); _changeAmtController.clear(); _pollWorkflowData(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Change order sent! Client notified on web portal.'), backgroundColor: AppColors.resultGreen)); }
      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send change order. Retry.'), backgroundColor: AppColors.alertRed));
    }
  }

  Future<void> _generatePaymentReceipt() async {
    final amount = double.tryParse(_receiptAmtController.text.trim());
    if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid payment amount.'), backgroundColor: AppColors.alertRed)); return; }
    setState(() => _isGeneratingReceipt = true);
    final totalPaid = widget.client.advanceReceived + amount;
    final balance = widget.client.totalContractAmount - totalPaid - widget.client.discount;
    final receiptNo = 'PCM-RCP-${DateTime.now().millisecondsSinceEpoch}';
    final pdfBytes = await ReceiptBuilder.generateBytes(receiptNumber: receiptNo, unitNumber: widget.client.unitNumber, clientName: widget.client.clientName, clientPhone: widget.client.phoneNumber, amountReceived: amount, totalPaidToDate: totalPaid, balanceRemaining: balance);
    if (pdfBytes == null) { if (mounted) setState(() => _isGeneratingReceipt = false); return; }
    _getCurrentPosition().then((pos) { if (pos != null) WorkflowService.instance.logSiteVisit(unitNumber: widget.client.unitNumber, latitude: pos.latitude, longitude: pos.longitude, actionType: 'payment_logged', actionDetail: 'Rs. $amount received'); });
    final receiptData = await WorkflowService.instance.createPaymentReceipt(unitNumber: widget.client.unitNumber, amountReceived: amount, totalPaidToDate: totalPaid, balanceRemaining: balance, receiptPdfBytes: Uint8List.fromList(pdfBytes));
    if (receiptData != null) WhatsAppService.instance.notifyPaymentReceived(phone: widget.client.phoneNumber, clientName: widget.client.clientName, amount: amount, receiptNo: receiptData['receipt_number'] ?? 'N/A');
    if (mounted) { _receiptAmtController.clear(); setState(() => _isGeneratingReceipt = false); _pollWorkflowData(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Receipt generated and pushed to client portal!'), backgroundColor: AppColors.resultGreen)); }
  }

  String _formatTimestamp(dynamic isoString) {
    if (isoString == null) return '';
    try {
      final parsed = DateTime.parse(isoString.toString()).toLocal();
      final hour = parsed.hour > 12 ? parsed.hour - 12 : parsed.hour;
      final period = parsed.hour >= 12 ? 'PM' : 'AM';
      final min = parsed.minute.toString().padLeft(2, '0');
      return '$hour:$min $period';
    } catch (_) { return ''; }
  }

  void _viewImageFullScreen(String url) {
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: Stack(alignment: Alignment.center, children: [InteractiveViewer(panEnabled: true, minScale: 0.5, maxScale: 4.0, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(url, fit: BoxFit.contain))), Positioned(top: 10, right: 10, child: CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))))])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            if (Navigator.canPop(context)) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              );
            }
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text('SITE HUB: ${widget.client.unitNumber.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.border, foregroundColor: Colors.white, centerTitle: true,
        bottom: TabBar(controller: _tabController, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60, labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8), isScrollable: true, tabAlignment: TabAlignment.center, tabs: const [Tab(text: 'OVERVIEW', icon: Icon(Icons.dashboard_customize)), Tab(text: 'CLIENT CHAT', icon: Icon(Icons.forum)), Tab(text: 'PHOTO VAULT', icon: Icon(Icons.photo_library))]),
      ),
      body: Column(
        children: [
          if (MediaQuery.of(context).viewInsets.bottom == 0) ProjectHubHeader(client: widget.client, currentStage: _currentStage, isAdmin: isAdmin, isUpdatingStage: _isUpdatingStage, onStageChanged: _updateStage, onCall: _makeCall, onWhatsApp: _openWhatsApp, onMaps: _openInMaps),
          ProjectHubWorkerRating(assignedWorkers: widget.client.assignedWorkers, onRatingSubmitted: () => setState(() {})),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ProjectHubOverviewTab(isLoading: _isLoadingOverview, client: widget.client, discountAmount: _discountAmount, discountController: _discountController, emailController: _emailController, customerType: _customerType, gstEnabled: _gstEnabled, gstinController: _gstinController, isAdmin: isAdmin, isSavingProfile: _isSavingProfile, nextPaymentDueDate: _nextPaymentDueDate, upiId: _upiId, bankName: _bankName, accountNumber: _accountNumber, ifscCode: _ifscCode, stageProgress: _stageProgress, isUpdatingStage: _isUpdatingStage, contractData: _contractData, isSendingContract: _isSendingContract, changeOrders: _changeOrders, changeDescController: _changeDescController, changeAmtController: _changeAmtController, isSendingChangeOrder: _isSendingChangeOrder, isCheckingInGps: _isCheckingInGps, receiptAmtController: _receiptAmtController, isGeneratingReceipt: _isGeneratingReceipt, paymentReceipts: _paymentReceipts, onCustomerTypeChanged: (v) => setState(() => _customerType = v), onGstToggled: (v) => setState(() => _gstEnabled = v), onSaveProfile: _saveClientProfile, onDiscountChanged: (v) => setState(() => _discountAmount = double.tryParse(v) ?? 0.0), onSetPaymentDate: () async { final picked = await showDatePicker(context: context, initialDate: _nextPaymentDueDate ?? DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), builder: (ctx, child) => Theme(data: ThemeData(colorScheme: const ColorScheme.light(primary: AppColors.border)), child: child!)); if (picked != null) setState(() => _nextPaymentDueDate = picked); }, onStageProgressChanged: (k, v) => setState(() => _stageProgress[k] = v), onUpdateProgress: _saveStageProgress, onSendContract: _sendContractForSignature, onDownloadSignedContract: ContractService.instance.openSignedContract, onShareContractLink: ContractService.instance.shareContractLink, onSendChangeOrder: _sendChangeOrder, onGpsCheckIn: _doGpsCheckin, onGenerateReceipt: _generatePaymentReceipt, onDownloadDoc: (url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)),
                ProjectHubChatTab(messages: _messages, isLoading: _isLoadingChat, messageController: _messageController, scrollController: _chatScrollController, onSendMessage: _sendMessage, formatTimestamp: _formatTimestamp, currentRole: AuthService.instance.userData?.role == UserRole.admin ? 'admin' : (AuthService.instance.userData?.role == UserRole.worker ? 'worker' : 'client')),
                ProjectHubPhotosTab(photos: _photos, isLoading: _isLoadingPhotos, isUploading: _isUploading, onRefresh: _fetchPhotos, onShowUploadOptions: _showUploadBottomSheet, onViewImage: _viewImageFullScreen, canUpload: AuthService.instance.userData?.role == UserRole.admin || AuthService.instance.userData?.role == UserRole.worker),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
