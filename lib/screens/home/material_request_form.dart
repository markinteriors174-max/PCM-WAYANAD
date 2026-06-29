// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/quotation.dart';

class MaterialRequestForm extends StatefulWidget {
  final String? activeSiteName;
  const MaterialRequestForm({super.key, this.activeSiteName});

  @override
  State<MaterialRequestForm> createState() => _MaterialRequestFormState();
}

class _MaterialRequestFormState extends State<MaterialRequestForm> {
  final Map<String, int> _requests = {
    'Gypsum Board (Ultra Steel)': 0,
    'Gyproc Board': 0,
    'Main Channel': 0,
    'Perimeter Channel': 0,
    'Wall Angle': 0,
    'Drywall Screws': 0,
  };

  String? _selectedSite;
  List<Quotation> _sites = [];
  bool _isLoadingSites = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSite = widget.activeSiteName;
    _loadSites();
  }

  Future<void> _loadSites() async {
    setState(() => _isLoadingSites = true);
    try {
      final sites = await DatabaseService.instance.getQuotations();
      setState(() => _sites = sites);
    } catch (e) {
      debugPrint('Error loading sites: $e');
    } finally {
      setState(() => _isLoadingSites = false);
    }
  }

  Future<void> _submitRequest() async {
    final user = AuthService.instance.userData;
    if (user == null) return;

    if (_selectedSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PLEASE SELECT A SITE FIRST'),
        backgroundColor: AppColors.alertRed,
      ));
      return;
    }

    final filteredRequests = Map.fromEntries(_requests.entries.where((e) => e.value > 0));
    if (filteredRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PLEASE SELECT AT LEAST ONE ITEM'),
        backgroundColor: AppColors.alertRed,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance.collection('material_requests').add({
        'workerId': user.uid,
        'workerName': user.name,
        'siteName': _selectedSite,
        'items': filteredRequests,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material Request Sent!'), backgroundColor: AppColors.primaryButton));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.alertRed));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('REQUEST STOCK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SELECT SITE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: AppColors.border)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSite,
                  hint: const Text('CHOOSE PROJECT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  isExpanded: true,
                  items: _sites.map((s) => DropdownMenuItem(
                    value: s.unitNumber,
                    child: Text(s.unitNumber.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedSite = val),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text('SELECT ITEMS & QUANTITY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: AppColors.border)),
            const SizedBox(height: 25),
            ..._requests.keys.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
              child: Row(
                children: [
                  Expanded(child: Text(item.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.labelColor))),
                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.border), onPressed: () => setState(() => _requests[item] = (_requests[item]! - 1).clamp(0, 100))),
                  Text('${_requests[item]}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryButton)),
                  IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryButton), onPressed: () => setState(() => _requests[item] = _requests[item]! + 1)),
                ],
              ),
            )),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _isSubmitting ? null : _submitRequest,
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: AppStyles.neumorphicDecoration(color: AppColors.primaryButton, hasThickBorder: true),
                alignment: Alignment.center,
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SUBMIT REQUEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
