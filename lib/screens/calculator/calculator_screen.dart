import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/language_provider.dart';
import 'calculator_controller.dart';
import 'project_edit_controller.dart';
import 'widgets/calculator_client_info_widget.dart';
import 'widgets/calculator_inputs_widget.dart';
import 'widgets/quick_add/quick_add_multi_rate_tiers_widget.dart';
import 'widgets/calculator_table_widget.dart';
import 'widgets/calculator_summary_widget.dart';
import 'widgets/calculator_payments_widget.dart';
import 'widgets/calculator_revision_widget.dart';
import '../../utils/calculator_utils.dart';
import '../../models/client_model.dart';
import '../../models/quotation.dart';
import '../../services/client_service.dart';
import '../calculator_editing_page.dart';

typedef CalculatorEditingScreen = CalculatorEditingPage;

class CalculatorScreen extends StatefulWidget {
  final Client? client;
  final Quotation? quotation;
  final String? projectId;
  final bool isEditing;
  final dynamic siteData;
  final bool isSheet;
  final VoidCallback? onClose;

  const CalculatorScreen({
    super.key,
    this.client,
    this.quotation,
    this.projectId,
    this.isEditing = false,
    this.siteData,
    this.isSheet = false,
    this.onClose,
  });

  @override
  State<CalculatorScreen> createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => !widget.isSheet;

  late CalculatorController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CalculatorController();

    if (widget.quotation != null) {
      _ctrl.loadQuotationState(widget.quotation!, force: true);
      if (widget.quotation!.items.isEmpty) {
        final targetUnit = widget.quotation!.unitNumber.isNotEmpty
            ? widget.quotation!.unitNumber
            : (widget.projectId ?? widget.client?.unitNumber ?? '');
        if (targetUnit.isNotEmpty) {
          _ctrl.loadProject(targetUnit, () {}, client: widget.client, quotation: widget.quotation);
        }
      }
    } else if (widget.siteData != null) {
      final dynamic data = widget.siteData;
      try {
        if (data is Quotation) {
          _ctrl.loadQuotationState(data, force: true);
          if (data.items.isEmpty && data.unitNumber.isNotEmpty) {
            _ctrl.loadProject(data.unitNumber, () {}, client: widget.client, quotation: data);
          }
        } else if (data is Client) {
          _ctrl.clientNameController.text = data.clientName;
          _ctrl.clientPhoneController.text = data.phoneNumber;
          _ctrl.clientLocationController.text = data.siteLocation;
          _ctrl.unitNumberController.text = ClientService.normalizeUnitNumber(data.unitNumber);
          _ctrl.loadProject(data.unitNumber, () {}, client: data);
        } else if (data is String) {
          _ctrl.loadProject(data, () {}, client: widget.client);
        } else {
          try {
            final dynamic entries = data.savedEntries ?? data.savedRoomsEntries;
            if (entries != null && entries is List && entries.isNotEmpty) {
              _ctrl.currentItems.clear();
              for (var entry in entries) {
                if (entry is QuotationItem) {
                  _ctrl.currentItems.add(entry);
                }
              }
              _ctrl.updateProjectTotals();
              _ctrl.notifyUI();
            } else if (data.quotation != null && data.quotation is Quotation) {
              final q = data.quotation as Quotation;
              _ctrl.loadQuotationState(q, force: true);
              if (q.items.isEmpty && q.unitNumber.isNotEmpty) {
                _ctrl.loadProject(q.unitNumber, () {}, client: widget.client, quotation: q);
              }
            } else if (widget.client != null) {
              _ctrl.loadProject(widget.client!.unitNumber, () {}, client: widget.client);
            }
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('siteData load notice: $e');
      }
    } else if (widget.client != null) {
      _ctrl.clientNameController.text = widget.client!.clientName;
      _ctrl.clientPhoneController.text = widget.client!.phoneNumber;
      _ctrl.clientLocationController.text = widget.client!.siteLocation;
      _ctrl.unitNumberController.text = ClientService.normalizeUnitNumber(widget.client!.unitNumber);
      _ctrl.loadProject(widget.client!.unitNumber, () {}, client: widget.client);
    } else if (widget.projectId != null) {
      _ctrl.loadProject(widget.projectId!, () {}, client: widget.client);
    } else {
      _ctrl.initLoad(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer Data Synced!'), backgroundColor: AppColors.primaryButton),
          );
        }
      });
    }

    _ctrl.addListener(() => setState(() {}));
    ProjectEditController.instance.addListener(_handleProjectEditRequest);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ProjectEditController.instance.pendingProjectId != null ||
          ProjectEditController.instance.pendingQuotation != null) {
        _handleProjectEditRequest();
      }
    });
  }

  void _handleProjectEditRequest() {
    if (widget.isSheet && widget.quotation != null && _ctrl.currentItems.isNotEmpty) {
      return;
    }

    final pendingId = ProjectEditController.instance.pendingProjectId;
    final pendingClient = ProjectEditController.instance.pendingClient;
    final pendingQuotation = ProjectEditController.instance.pendingQuotation;

    if (mounted) {
      if (pendingQuotation != null && pendingQuotation.items.isNotEmpty) {
        _ctrl.loadQuotationState(pendingQuotation, force: true);
        ProjectEditController.instance.clearRequest();
        return;
      }

      if (pendingClient != null) {
        _ctrl.clientNameController.text = pendingClient.clientName;
        _ctrl.clientPhoneController.text = pendingClient.phoneNumber;
        _ctrl.clientLocationController.text = pendingClient.siteLocation;
        _ctrl.unitNumberController.text = ClientService.normalizeUnitNumber(pendingClient.unitNumber);
      }

      final String targetId = (pendingId != null && pendingId.isNotEmpty && pendingId != '0')
          ? pendingId
          : (pendingQuotation?.unitNumber.isNotEmpty == true
              ? pendingQuotation!.unitNumber
              : (pendingClient?.unitNumber ?? pendingClient?.id ?? ''));
      if (targetId.isNotEmpty) {
        _ctrl.loadProject(targetId, () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Project Loaded!'), backgroundColor: AppColors.primaryButton),
            );
          }
        }, client: pendingClient, quotation: pendingQuotation);
      }
      ProjectEditController.instance.clearRequest();
    }
  }

  /// Restores saved rooms and entries into list state when passing or editing site data
  void loadSavedSiteData(Quotation quotation) {
    _ctrl.loadSavedSiteData(quotation);
  }

  @override
  void dispose() {
    ProjectEditController.instance.removeListener(_handleProjectEditRequest);
    _ctrl.disposeAll();
    _ctrl.dispose();
    super.dispose();
  }

  void _showClearConfirmation() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Reset Everything?'),
      content: const Text('This will clear the current site progress.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(onPressed: () { 
          _ctrl.startNewProject(); 
          Navigator.pop(context); 
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed), child: const Text('RESET')),
      ],
    ));
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: AppColors.labelColor)),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
          child: child,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = context.watch<LanguageProvider>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (widget.isSheet) {
          widget.onClose?.call();
          if (context.mounted) Navigator.of(context).pop();
          return;
        }
        final bool? shouldPop = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(lang.translate('CALCULATOR'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Exit current session? All work is auto-saved locally.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('STAY')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton, foregroundColor: Colors.white), child: const Text('EXIT')),
          ],
        ));
        if (shouldPop == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true, 
        appBar: widget.isSheet
            ? AppBar(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 3,
                automaticallyImplyLeading: false,
                titleSpacing: 16,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.calculate_rounded, color: Color(0xFFD4AF37), size: 18),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.client?.clientName ??
                                (_ctrl.clientNameController.text.isNotEmpty
                                    ? _ctrl.clientNameController.text
                                    : 'Site Calculator'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unit #${widget.projectId ?? widget.client?.unitNumber ?? _ctrl.unitNumberController.text} • Interactive Measurement Sheet',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                actions: [
                  if (_ctrl.showSavedIndicator) 
                    const Center(child: Padding(padding: EdgeInsets.only(right: 8), child: Row(children: [
                      Icon(Icons.check_circle, color: AppColors.resultGreen, size: 16),
                      SizedBox(width: 4),
                      Text('SAVED', style: TextStyle(color: AppColors.resultGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]))),
                  IconButton(
                    icon: const Icon(Icons.language, color: Colors.white),
                    tooltip: 'Toggle Language',
                    onPressed: () => lang.toggleLanguage(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cleaning_services, color: Colors.white),
                    tooltip: 'Reset Project',
                    onPressed: _showClearConfirmation,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    tooltip: 'Close & Save',
                    onPressed: () {
                      widget.onClose?.call();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              )
            : CustomAppBar(
                title: lang.translate('REGISTER'),
                actions: [
                  if (_ctrl.showSavedIndicator) 
                    const Center(child: Padding(padding: EdgeInsets.only(right: 8), child: Row(children: [
                      Icon(Icons.check_circle, color: AppColors.resultGreen, size: 16),
                      SizedBox(width: 4),
                      Text('SAVED', style: TextStyle(color: AppColors.resultGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]))),
                  IconButton(icon: const Icon(Icons.language, color: Colors.white), onPressed: () => lang.toggleLanguage()),
                  IconButton(icon: const Icon(Icons.cleaning_services, color: Colors.white), onPressed: _showClearConfirmation),
                ],
              ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 20, right: 20, top: 20, 
              bottom: 120, // FIX: Removed MediaQuery.of(context).viewInsets.bottom to prevent double-pushing content when keyboard is open
            ), 
            child: Column(
              children: [
                _buildSection(title: 'SITE & CLIENT', child: CalculatorClientInfoWidget(ctrl: _ctrl, lang: lang)),
                const SizedBox(height: 20),
                if (!widget.isEditing) ...[
                  QuickAddMultiRateTiersWidget(ctrl: _ctrl, currentRoomName: 'Main Project'),
                  const SizedBox(height: 15),
                ],
                _buildSection(title: 'DIMENSIONS & RATES', child: CalculatorInputsWidget(ctrl: _ctrl, lang: lang, onStateChanged: () {})),
                const SizedBox(height: 30),
                CalculatorTableWidget(ctrl: _ctrl, onStateChanged: () {}),
                const SizedBox(height: 30),
                CalculatorSummaryWidget(ctrl: _ctrl, lang: lang, onStateChanged: () {}),
                const SizedBox(height: 30),
                CalculatorPaymentsWidget(ctrl: _ctrl, lang: lang),
                const SizedBox(height: 30),
                CalculatorRevisionWidget(ctrl: _ctrl, lang: lang),
                const SizedBox(height: 30),
                CalculatorStickyActionsWidget(ctrl: _ctrl, lang: lang),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) {
            final hasEntries = _ctrl.currentItems.isNotEmpty || _ctrl.projectTotalAmount > 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Dark Slate
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                              ),
                              child: const Text(
                                'OVERALL GRAND TOTAL',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${_ctrl.currentItems.length} Entries)',
                              style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasEntries
                              ? '${_ctrl.projectTotalAreaSqFt.toStringAsFixed(2)} SQFT • ആകെ മൊത്തം തുക'
                              : '0.00 SQFT • ഇതുവരെയുള്ള എല്ലാ എൻട്രികളും',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                    Text(
                      '₹${CalculatorUtils.formatIndianCurrency(_ctrl.projectTotalAmount)}',
                      style: const TextStyle(
                        color: Color(0xFF4ADE80), // Vibrant Mint Green
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
