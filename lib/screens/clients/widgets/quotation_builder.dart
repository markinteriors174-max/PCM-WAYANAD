import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/client_model.dart';
import '../../../models/labor_models.dart';
import '../../../services/client_service.dart';
import '../../../theme/app_theme.dart';
import 'project_header_card.dart';
import 'financial_summary_card.dart';
import 'action_buttons_bar.dart';
import 'progress_carousel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../calculator/calculator_screen.dart';
import '../../../services/database_service.dart';
import '../../../models/quotation.dart';
import '../../../services/customer_sync_service.dart';
import '../../../services/photo_notification_service.dart';
import '../project_hub_page.dart';
import '../../call_screen.dart';

class ClientCardWidget extends StatefulWidget {
  final Client client;
  final VoidCallback onRefresh;
  final bool isSelected;
  final ValueChanged<Client>? onSelectClient;

  const ClientCardWidget({
    super.key,
    required this.client,
    required this.onRefresh,
    this.isSelected = false,
    this.onSelectClient,
  });
  @override
  State<ClientCardWidget> createState() => _ClientCardWidgetState();
}

class _ClientCardWidgetState extends State<ClientCardWidget> {
  bool _isEditing = false, _isSaving = false, _isPinning = false;
  late TextEditingController _nameController, _phoneController, _locationController;
  String _status = 'Pending';
  List<String> _selectedWorkers = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.clientName);
    _phoneController = TextEditingController(text: widget.client.phoneNumber);
    _locationController = TextEditingController(text: widget.client.siteLocation);
    _status = widget.client.status;
    _selectedWorkers = widget.client.assignedWorkers.split(',').map((w) => w.trim()).where((w) => w.isNotEmpty).toList();
  }

  @override
  void dispose() {
    _nameController.dispose(); _phoneController.dispose(); _locationController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    setState(() => _isSaving = true);
    final updated = widget.client.copyWith(
      clientName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      siteLocation: _locationController.text.trim(),
      status: _status,
      assignedWorkers: _selectedWorkers.join(','),
    );
    await ClientService.instance.updateClient(updated);
    if (mounted) setState(() { _isEditing = false; _isSaving = false; });
    widget.onRefresh();
  }

  void _pinLocation() async {
    if (_isPinning) return;
    setState(() => _isPinning = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to pin site GPS.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final updated = widget.client.copyWith(latitude: pos.latitude, longitude: pos.longitude);
      await ClientService.instance.updateClient(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS Pinned successfully for ${widget.client.unitNumber}: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'),
            backgroundColor: AppColors.resultGreen,
          ),
        );
      }
      widget.onRefresh();
    } catch (e) {
      debugPrint('Error pinning location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing GPS location: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPinning = false);
    }
  }

  void _openCalculator() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    Quotation? matchedQuota;
    final cleanUnit = ClientService.normalizeUnitNumber(widget.client.unitNumber);

    try {
      matchedQuota = await DatabaseService.instance
          .getQuotationByProjectIdOrUnit(
            cleanUnit,
            altUnit: widget.client.id,
            clientPhone: widget.client.phoneNumber,
          )
          .timeout(const Duration(seconds: 4), onTimeout: () => null);
    } catch (e) {
      debugPrint('Quotation lookup notice: $e');
    }

    // Ensure room items array is fetched from database if matchedQuota has 0 items
    if (matchedQuota == null || matchedQuota.items.isEmpty) {
      try {
        final fetchedItems = await DatabaseService.instance.getQuotationItems(
          cleanUnit,
          altUnit: widget.client.id,
          clientPhone: widget.client.phoneNumber,
          clientName: widget.client.clientName,
          quotationId: matchedQuota?.id,
        ).timeout(const Duration(seconds: 3), onTimeout: () => []);

        if (fetchedItems.isNotEmpty) {
          if (matchedQuota != null) {
            matchedQuota = matchedQuota.copyWith(items: fetchedItems);
          } else {
            matchedQuota = Quotation(
              unitNumber: cleanUnit,
              clientName: widget.client.clientName,
              clientPhone: widget.client.phoneNumber,
              clientLocation: widget.client.siteLocation,
              locationFolder: widget.client.siteLocation,
              date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
              totalAmount: widget.client.totalContractAmount,
              paidAmount: widget.client.advanceReceived,
              balanceAmount: widget.client.balanceDue,
              manualAmount: widget.client.totalContractAmount,
              items: fetchedItems,
              materials: const [],
              rentals: const [],
              payments: widget.client.advanceReceived > 0
                  ? [
                      PaymentRecord(
                        description: 'Advance Received',
                        amount: widget.client.advanceReceived,
                        date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
                      )
                    ]
                  : const [],
              projectStatus: widget.client.status,
            );
          }
        }
      } catch (e) {
        debugPrint('Quotation items lookup notice in _openCalculator: $e');
      }
    }

    // Fallback draft if no quotation exists yet
    matchedQuota ??= Quotation(
      unitNumber: cleanUnit,
      clientName: widget.client.clientName,
      clientPhone: widget.client.phoneNumber,
      clientLocation: widget.client.siteLocation,
      locationFolder: widget.client.siteLocation,
      date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
      totalAmount: widget.client.totalContractAmount,
      paidAmount: widget.client.advanceReceived,
      balanceAmount: widget.client.balanceDue,
      manualAmount: widget.client.totalContractAmount,
      items: const [],
      materials: const [],
      rentals: const [],
      payments: widget.client.advanceReceived > 0
          ? [
              PaymentRecord(
                description: 'Advance Received',
                amount: widget.client.advanceReceived,
                date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
              )
            ]
          : const [],
      projectStatus: widget.client.status,
    );

    // Reuse existing project ID if matchedQuota.id is 0 or null
    final quota = matchedQuota;
    if (quota.id == null || quota.id == 0) {
      try {
        final existing = await DatabaseService.instance.findActiveProjectForClient(
          phone: widget.client.phoneNumber,
          name: widget.client.clientName,
        );
        if (existing != null && existing.id != null) {
          matchedQuota = quota.copyWith(
            id: existing.id,
            items: quota.items.isNotEmpty ? quota.items : existing.items,
          );
        }
      } catch (_) {}
    }

    if (mounted) {
      // Close loading dialog
      Navigator.pop(context);

      final currentQuota = matchedQuota;
      final targetId = (currentQuota?.id != null && currentQuota!.id! > 0)
          ? currentQuota.id.toString()
          : (cleanUnit.isNotEmpty ? cleanUnit : widget.client.id);

      // Open directly as an interactive Editing Window / Sheet linked to that specific project's ID
      // Do not navigate away or switch tabs; remain in place inside the site folder/client card
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (sheetContext) => SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.94,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CalculatorScreen(
                      client: widget.client,
                      quotation: matchedQuota,
                      projectId: targetId,
                      isSheet: true,
                      onClose: () {
                        widget.onRefresh();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      widget.onRefresh();
    }
  }

  void _showWorkersDialog() async {
    final workersSnapshot = await FirebaseFirestore.instance.collection('workers').get();
    final workers = workersSnapshot.docs.map((doc) => Worker.fromMap(doc.data(), doc.id)).toList();
    if (!mounted || workers.isEmpty) return;
    List<String> temp = List.from(_selectedWorkers);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Workers'),
        content: StatefulBuilder(builder: (c, setD) => Column(mainAxisSize: MainAxisSize.min, children: workers.map((w) => CheckboxListTile(title: Text(w.name), value: temp.contains(w.name), onChanged: (val) => setD(() => val == true ? temp.add(w.name) : temp.remove(w.name)))).toList())),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')), TextButton(onPressed: () { setState(() => _selectedWorkers = temp); Navigator.pop(context); _saveChanges(); }, child: const Text('SAVE'))],
      ),
    );
  }

  void _deleteProfile() {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Site Folder?',
                style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete site folder ${widget.client.unitNumber} (${widget.client.clientName})? This action will permanently remove the document from Firestore.',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              // Dismiss confirmation dialog immediately so UI stays responsive
              Navigator.pop(dialogContext);

              try {
                final docId = widget.client.id;
                final unitId = widget.client.unitNumber;

                await ClientService.instance.softDeleteClient(
                  docId,
                  unitNumber: unitId,
                  client: widget.client,
                ).timeout(
                  const Duration(seconds: 8),
                  onTimeout: () {
                    debugPrint('softDeleteClient timed out for $docId');
                  },
                );

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Site folder moved to Trash'),
                    backgroundColor: AppColors.alertRed,
                  ),
                );

                widget.onRefresh();
              } catch (e) {
                debugPrint('Error deleting site folder: $e');
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error deleting site folder: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startCall(bool isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: widget.client.unitNumber,
          isVideoCall: isVideo,
        ),
      ),
    );
  }

  void _showCallOptionDialog() {
    final phone = widget.client.phoneNumber.trim().isNotEmpty
        ? widget.client.phoneNumber.trim()
        : '8606415174';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SELECT CALL METHOD',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.border),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1976D2),
                child: Icon(Icons.dialpad, color: Colors.white),
              ),
              title: const Text('NATIVE DIALER', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Call $phone directly via cellular network'),
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse('tel:$phone');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryButton,
                child: Icon(Icons.phone, color: Colors.white),
              ),
              title: const Text('VOIP VOICE CALL (FREE)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('High-quality audio via Agora Internet Call'),
              onTap: () {
                Navigator.pop(context);
                _startCall(false);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.border,
                child: Icon(Icons.videocam, color: Colors.white),
              ),
              title: const Text('VOIP VIDEO CALL (FREE)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Real-time video via Agora Internet Call'),
              onTap: () {
                Navigator.pop(context);
                _startCall(true);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAttendanceDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final logs = await ClientService.instance.fetchAttendanceLogs(widget.client.unitNumber);
      if (mounted) {
        Navigator.pop(context); // Close loading

        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'SITE ATTENDANCE: ${widget.client.unitNumber.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.border),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: logs.isEmpty
                    ? const Center(child: Text('No attendance records found for this site.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45)))
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final date = log['punch_in'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(log['punch_in'])) : '---';
                          final worker = log['worker_name'] ?? 'Unknown Worker';
                          final days = (log['work_days'] ?? 0.0).toDouble();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: AppStyles.neumorphicDecoration(color: Colors.white),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(worker.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.labelColor)),
                                    Text(date, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.resultGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                                  child: Text('$days DAYS', style: const TextStyle(color: AppColors.resultGreen, fontWeight: FontWeight.w900, fontSize: 11)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error showing attendance: $e');
    }
  }

  void _handleLiveUpdate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final quotations = await DatabaseService.instance.getQuotations();
      Quotation? matchedQuota;
      for (var q in quotations) {
        if (q.unitNumber == widget.client.unitNumber) {
          matchedQuota = q;
          break;
        }
      }

      if (matchedQuota == null) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No quotation found for this client to update.')),
          );
        }
        return;
      }

      await CustomerSyncService.instance.saveQuotationToCloud(matchedQuota);

      int totalPlain = 0;
      int totalDesign = 0;
      int totalCenter = 0;
      final StringBuffer chatMsgBuffer = StringBuffer();

      for (var item in matchedQuota.items) {
        final double quantity = item.quantity;
        final double rate = item.rate;

        final bool isCeiling = item.isCeilingDesign;
        final bool hasCove = item.hasCove;
        final bool hasCentral = item.hasCentralDesign;

        double factor = 1.0;
        if (item.unit == 'Meters' || item.unit == 'SqM') {
          factor = 10.764;
        } else if (item.unit == 'Inches') {
          factor = 1.0 / 144.0;
        } else if (item.unit == 'mm') {
          factor = 10.764 / 1000000.0;
        }

        double ceilingArea = 0.0;
        if (isCeiling) {
          if (item.length == 0.0 && item.width == 0.0 && item.area > 0.0) {
            final double mainArea = (item.area / quantity) - item.coveRft - item.centralArea;
            ceilingArea = mainArea > 0.0 ? mainArea : 0.0;
          } else {
            ceilingArea = item.length * item.width;
          }
        }

        final double plainCost = isCeiling ? (ceilingArea * quantity * factor * rate) : 0.0;

        final double coveRateVal = item.coveRate > 0.0 ? item.coveRate : rate;
        final double designCost = hasCove ? (item.coveRft * quantity * factor * coveRateVal) : 0.0;

        final double centralRateVal = item.centralRate > 0.0 ? item.centralRate : rate;
        final double centerCost = hasCentral ? (item.centralArea * quantity * factor * centralRateVal) : 0.0;

        final int plainRounded = plainCost.round();
        final int designRounded = designCost.round();
        final int centerRounded = centerCost.round();

        totalPlain += plainRounded;
        totalDesign += designRounded;
        totalCenter += centerRounded;

        chatMsgBuffer.writeln('${item.roomName} Cost Updated: Plain: $plainRounded, Design: $designRounded, Center Design: $centerRounded.');
      }

      final String chatMessage = chatMsgBuffer.toString().trim();

      if (chatMessage.isNotEmpty) {
        await ClientService.instance.sendChatMessage(
          widget.client.unitNumber,
          'Admin',
          chatMessage,
        );
      }

      final String notifTitle = 'MARK GYPSUM - WORK PROGRESS UPDATE';
      final String notifBody = 'ROOM DETAILS UPDATED! PLAIN: $totalPlain | DESIGN: $totalDesign | CENTER DESIGN: $totalCenter. TAP TO CHECK YOUR CLIENT HUB.';

      await PhotoNotificationService.instance.showTextNotification(
        title: notifTitle,
        body: notifBody,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live update sent successfully!')),
        );
      }
      widget.onRefresh();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error running Live Update: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onSelectClient != null) {
          widget.onSelectClient!(widget.client);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true).copyWith(
          border: widget.isSelected
              ? Border.all(color: AppColors.border, width: 3.0)
              : Border.all(color: AppColors.border.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              ProjectHeaderCard(
                client: widget.client, isEditing: _isEditing, nameController: _nameController, phoneController: _phoneController, locationController: _locationController,
                status: _status, selectedWorkers: _selectedWorkers, onAssignWorkers: _showWorkersDialog,
                onStatusChanged: (val) { if (val != null) { setState(() { _status = val; }); _saveChanges(); } },
                onToggleEdit: () { if (_isEditing) { _saveChanges(); } else { setState(() { _isEditing = true; }); } }, isSaving: _isSaving,
              ),
              const SizedBox(height: 10),
              ProgressCarousel(siteId: widget.client.unitNumber),
              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 1, color: Colors.black12),
              const SizedBox(height: 10),
              FinancialSummaryCard(totalContract: widget.client.totalContractAmount, advanceReceived: widget.client.advanceReceived, totalLaborCost: widget.client.totalLaborCost, balanceDue: widget.client.balanceDue),
              const SizedBox(height: 15),
              ActionButtonsBar(
                hasPin: widget.client.latitude != null, isPinning: _isPinning, onPinLocation: _pinLocation,
                onOpenCalculator: _openCalculator,
                onLiveUpdate: _handleLiveUpdate,
                onOpenChat: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProjectHubPage(client: widget.client, initialTabIndex: 1)),
                  );
                },
                onVoipCall: _showCallOptionDialog,
                onOpenAttendance: _showAttendanceDialog,
                onDelete: _deleteProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
