import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart' as ncp;
import '../../../theme/app_theme.dart';
import '../../../models/quotation.dart';
import '../../../services/database_service.dart';
import '../../../services/client_service.dart';
import '../../calculator/calculator_controller.dart';
import '../../../providers/language_provider.dart';
import '../project_edit_controller.dart';
import '../helpers/location_picker_helper.dart';
import 'qr_scanner_screen.dart';

class CalculatorClientInfoWidget extends StatefulWidget {
  final CalculatorController ctrl;
  final LanguageProvider lang;

  const CalculatorClientInfoWidget({
    super.key,
    required this.ctrl,
    required this.lang,
  });

  @override
  State<CalculatorClientInfoWidget> createState() => _CalculatorClientInfoWidgetState();
}

class _CalculatorClientInfoWidgetState extends State<CalculatorClientInfoWidget> {
  final ncp.FlutterNativeContactPicker _contactPicker = ncp.FlutterNativeContactPicker();
  bool _isFetchingGps = false;

  Future<void> _pickContact(BuildContext context) async {
    if (kIsWeb) {
      _showSavedClientsSheet(context);
      return;
    }

    try {
      final contact = await _contactPicker.selectContact();
      if (contact != null) {
        String? phone;
        if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
          phone = contact.phoneNumbers!.first.trim();
        }

        final String name = (contact.fullName ?? '').trim();

        if (phone != null && phone.isNotEmpty) {
          // Normalize formatting while keeping full international or local digits
          final cleanedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
          widget.ctrl.clientPhoneController.text = cleanedPhone.isNotEmpty ? cleanedPhone : phone;
          widget.ctrl.onClientInfoChanged(widget.ctrl.clientPhoneController.text, 'phone');
        }

        if (name.isNotEmpty) {
          widget.ctrl.clientNameController.text = name;
          widget.ctrl.onClientInfoChanged(name, 'name');
        }

        widget.ctrl.triggerAutoSave();
        widget.ctrl.notifyUI();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Contact loaded: $name ${widget.ctrl.clientPhoneController.text}'),
              backgroundColor: const Color(0xFF15803D),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Native contact picker error: $e');
      if (context.mounted) {
        _showSavedClientsSheet(context);
      }
    }
  }

  void _showSavedClientsSheet(BuildContext context) async {
    List<Quotation> quotations = [];
    try {
      quotations = await DatabaseService.instance.getQuotations();
    } catch (e) {
      debugPrint('Error loading saved clients: $e');
    }

    // Filter unique clients with non-empty phone or name, prioritizing entries with saved items
    final Map<String, Quotation> uniqueClients = {};
    for (final q in quotations) {
      final key = q.clientPhone.trim().isNotEmpty ? q.clientPhone.trim() : q.clientName.trim();
      if (key.isNotEmpty) {
        if (!uniqueClients.containsKey(key) || (uniqueClients[key]!.items.isEmpty && q.items.isNotEmpty)) {
          uniqueClients[key] = q;
        }
      }
    }

    final clientList = uniqueClients.values.toList();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = clientList.where((c) {
              final q = query.toLowerCase();
              return c.clientName.toLowerCase().contains(q) ||
                  c.clientPhone.contains(q) ||
                  c.clientLocation.toLowerCase().contains(q);
            }).toList();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.lang.isMalayalam ? 'ക്ലയന്റ് തിരഞ്ഞെടുക്കുക' : 'Select Customer',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: widget.lang.isMalayalam ? 'പേരോ ഫോൺ നമ്പറോ തിരയുക...' : 'Search name or phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setSheetState(() => query = val.trim());
                    },
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          widget.lang.isMalayalam ? 'ക്ലയന്റുകൾ കണ്ടെത്തിയില്ല' : 'No customers found',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE0F2FE),
                              child: Text(
                                c.clientName.isNotEmpty ? c.clientName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              c.clientName.isNotEmpty ? c.clientName : 'Unknown Client',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${c.clientPhone.isNotEmpty ? c.clientPhone : 'No Phone'} • ${c.clientLocation.isNotEmpty ? c.clientLocation : 'No Location'}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            onTap: () {
                              if (c.clientName.isNotEmpty) {
                                widget.ctrl.clientNameController.text = c.clientName;
                              }
                              if (c.clientPhone.isNotEmpty) {
                                widget.ctrl.clientPhoneController.text = c.clientPhone;
                              }
                              if (c.clientLocation.isNotEmpty) {
                                widget.ctrl.clientLocationController.text = c.clientLocation;
                              }
                              if (c.unitNumber.isNotEmpty) {
                                widget.ctrl.unitNumberController.text = ClientService.normalizeUnitNumber(c.unitNumber);
                              }
                              final target = c.unitNumber.isNotEmpty ? c.unitNumber : (c.id?.toString() ?? c.clientPhone);
                              if (target.isNotEmpty) {
                                widget.ctrl.loadProject(target, () {});
                              } else {
                                widget.ctrl.loadQuotationState(c, force: true);
                              }
                              widget.ctrl.triggerAutoSave();
                              widget.ctrl.notifyUI();
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchGpsLocation(BuildContext context) async {
    final placeName = await LocationPickerHelper.fetchCurrentPlaceName(
      context: context,
      onLoadingChanged: (loading) {
        if (mounted) setState(() => _isFetchingGps = loading);
      },
    );

    if (placeName != null && placeName.isNotEmpty) {
      widget.ctrl.clientLocationController.text = placeName;
      widget.ctrl.onClientInfoChanged(placeName, 'location');
      widget.ctrl.triggerAutoSave();
      widget.ctrl.notifyUI();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Location: $placeName'),
            backgroundColor: const Color(0xFF0284C7),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ctrl.clientLocationController.text.toLowerCase().contains('thrissur') ||
        widget.ctrl.clientLocationController.text.contains(RegExp(r'\(\s*-?\d+')) ||
        widget.ctrl.clientLocationController.text.contains(RegExp(r'-?\d{1,3}\.\d{3,}'))) {
      widget.ctrl.clientLocationController.text = LocationPickerHelper.sanitizePlaceString(widget.ctrl.clientLocationController.text);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Project ID Field with QR Scanner
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.ctrl.unitNumberController,
                decoration: AppStyles.inputDecoration('Project ID').copyWith(
                  prefixIcon: const Icon(Icons.tag, color: Color(0xFF0284C7), size: 20),
                ),
                onChanged: (val) => widget.ctrl.onClientInfoChanged(val, 'id'),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF0284C7), size: 22),
                tooltip: 'Scan Project QR Code',
                onPressed: () async {
                  final String? scannedValue = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                  );
                  if (scannedValue == null || scannedValue.isEmpty) return;

                  if (context.mounted) {
                    ProjectEditController.handleScannedQRCode(context, scannedValue);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Customer Name Field
        TextField(
          controller: widget.ctrl.clientNameController,
          decoration: AppStyles.inputDecoration(
            widget.lang.isMalayalam ? 'കസ്റ്റമർ പേര് (Customer Name)' : 'Customer Name',
          ).copyWith(
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0284C7), size: 20),
          ),
          onChanged: (val) => widget.ctrl.onClientInfoChanged(val, 'name'),
        ),
        const SizedBox(height: 12),

        // 3. Phone Field (Full width to show complete phone number without being squished)
        TextField(
          controller: widget.ctrl.clientPhoneController,
          keyboardType: TextInputType.phone,
          decoration: AppStyles.inputDecoration(
            widget.lang.isMalayalam ? 'ഫോൺ നമ്പർ (Phone)' : 'Phone Number',
          ).copyWith(
            prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF0284C7), size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.contact_phone, color: Color(0xFF0284C7), size: 22),
              tooltip: widget.lang.isMalayalam ? 'ഫോൺ കോൺടാക്ട്സിൽ നിന്ന് എടുക്കുക' : 'Select from Contacts',
              onPressed: () => _pickContact(context),
            ),
          ),
          onChanged: (val) => widget.ctrl.onClientInfoChanged(val, 'phone'),
        ),
        const SizedBox(height: 12),

        // 4. Location Field (Full width with GPS Auto-Fetch Icon)
        TextField(
          controller: widget.ctrl.clientLocationController,
          decoration: AppStyles.inputDecoration(
            widget.lang.isMalayalam ? 'സ്ഥലം (Location / GPS)' : 'Location / GPS',
          ).copyWith(
            prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0284C7), size: 20),
            suffixIcon: _isFetchingGps
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.my_location, color: Color(0xFF0284C7), size: 22),
                    tooltip: widget.lang.isMalayalam ? 'ജിപിഎസ് ലൊക്കേഷൻ എടുക്കുക' : 'Auto-fetch GPS Location',
                    onPressed: () => _fetchGpsLocation(context),
                  ),
          ),
          onChanged: (val) => widget.ctrl.onClientInfoChanged(val, 'location'),
        ),
      ],
    );
  }
}
