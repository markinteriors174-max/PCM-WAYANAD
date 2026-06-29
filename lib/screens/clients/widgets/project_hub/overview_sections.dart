// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/client_model.dart';

Widget overviewSection({
  required String title,
  required IconData icon,
  required Color color,
  required List<Widget> children,
}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 11,
                color: color, letterSpacing: 1,
              )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    ),
  );
}

Widget finRow(String label, String value, {bool bold = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      Text(value, style: TextStyle(
        fontSize: bold ? 13 : 11,
        fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
        color: bold ? AppColors.border : AppColors.labelColor,
      )),
    ],
  );
}

class ClientProfileSection extends StatelessWidget {
  final TextEditingController emailController;
  final String customerType;
  final bool gstEnabled;
  final TextEditingController gstinController;
  final bool isAdmin;
  final bool isSaving;
  final Function(String) onCustomerTypeChanged;
  final Function(bool) onGstToggled;
  final VoidCallback onSave;

  const ClientProfileSection({
    super.key,
    required this.emailController,
    required this.customerType,
    required this.gstEnabled,
    required this.gstinController,
    required this.isAdmin,
    required this.isSaving,
    required this.onCustomerTypeChanged,
    required this.onGstToggled,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return overviewSection(
      title: 'CLIENT PROFILE',
      icon: Icons.person_outline,
      color: Colors.blueGrey,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: AppStyles.inputDecoration('Client Email').copyWith(
            hintText: 'e.g. client@gmail.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.border),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('CUSTOMER TYPE:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.labelColor)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4), width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: customerType,
                    isExpanded: true,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.border),
                    items: ['Direct Customer', 'Builder', 'Architect', 'Interior Designer', 'Other']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => onCustomerTypeChanged(v!),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ENABLE GST BILLING', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.labelColor)),
            Switch(
              value: gstEnabled,
              activeColor: AppColors.primaryButton,
              onChanged: onGstToggled,
            ),
          ],
        ),
        if (gstEnabled) ...[  
          const SizedBox(height: 8),
          TextField(
            controller: gstinController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 15,
            decoration: AppStyles.inputDecoration('GSTIN (15 digits)').copyWith(
              counterText: '',
              prefixIcon: const Icon(Icons.receipt_long, size: 18, color: AppColors.border),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save, size: 16),
            label: Text(isSaving ? 'SAVING...' : 'SAVE PROFILE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: (isAdmin && !isSaving) ? onSave : null,
          ),
        ),
      ],
    );
  }
}

class FinancialsSection extends StatelessWidget {
  final Client client;
  final double discountAmount;
  final TextEditingController discountController;
  final DateTime? nextPaymentDueDate;
  final String upiId;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final Function(String) onDiscountChanged;
  final VoidCallback onSetPaymentDate;
  final bool isAdmin;

  const FinancialsSection({
    super.key,
    required this.client,
    required this.discountAmount,
    required this.discountController,
    required this.nextPaymentDueDate,
    required this.upiId,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.onDiscountChanged,
    required this.onSetPaymentDate,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final balanceDue = client.totalContractAmount - client.advanceReceived - discountAmount;

    return Column(
      children: [
        // Branded Client Summary Cards (3-column layout)
        Row(
          children: [
            Expanded(child: _buildFinCard('TOTAL CONTRACT', currencyFmt.format(client.totalContractAmount), Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildFinCard('PAID TO DATE', currencyFmt.format(client.advanceReceived), Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _buildFinCard('BALANCE DUE', currencyFmt.format(balanceDue.clamp(0, double.infinity)), AppColors.alertRed)),
          ],
        ),
        const SizedBox(height: 14),
        if (isAdmin)
          overviewSection(
            title: 'FINANCIAL SETTINGS (ADMIN ONLY)',
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.blueGrey,
            children: [
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: AppStyles.inputDecoration('Discount Amount (₹)').copyWith(
                  prefixIcon: const Icon(Icons.discount_outlined, size: 18, color: AppColors.border),
                ),
                onChanged: onDiscountChanged,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onSetPaymentDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 18, color: AppColors.border),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nextPaymentDueDate != null
                              ? 'Next Payment Due: ${DateFormat('dd MMM yyyy').format(nextPaymentDueDate!)}'
                              : 'TAP TO SET PAYMENT DUE DATE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12,
                            color: nextPaymentDueDate != null ? AppColors.labelColor : Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        else if (nextPaymentDueDate != null)
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.orange.shade50,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.orange.shade300),
             ),
             child: Row(
               children: [
                 const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                 const SizedBox(width: 10),
                 Text(
                   'NEXT PAYMENT DUE: ${DateFormat('dd MMM yyyy').format(nextPaymentDueDate!)}',
                   style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 11),
                 ),
               ],
             ),
           ),
        
        if (upiId.isNotEmpty) ...[  
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner, size: 14),
                  label: const Text('PAY NOW (UPI)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final amount = balanceDue.clamp(0, double.infinity);
                    final upiLink = 'upi://pay?pa=$upiId&pn=PCM+WAYANAD&am=${amount.toStringAsFixed(2)}&cu=INR&tn=Balance+${client.unitNumber}';
                    Clipboard.setData(ClipboardData(text: upiLink));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('📋 UPI payment link copied to clipboard!'),
                      backgroundColor: Colors.deepPurple,
                    ));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.account_balance, size: 14),
                  label: const Text('BANK DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final amount = balanceDue.clamp(0, double.infinity);
                    final text = '💰 Payment Details — PCM WAYANAD\n'
                        'Amount Due: ${currencyFmt.format(amount)}\n'
                        'Project: ${client.unitNumber}\n\n'
                        '🏦 Bank: $bankName\n'
                        'A/C: $accountNumber\n'
                        'IFSC: $ifscCode\n'
                        'UPI: $upiId';
                    Share.share(text, subject: 'PCM WAYANAD Payment Details');
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFinCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5), textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.border), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class ProgressTrackerSection extends StatelessWidget {
  final Map<String, int> stageProgress;
  final bool isAdmin;
  final bool isUpdating;
  final Function(String, int) onProgressChanged;
  final VoidCallback onUpdate;

  const ProgressTrackerSection({
    super.key,
    required this.stageProgress,
    required this.isAdmin,
    required this.isUpdating,
    required this.onProgressChanged,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return overviewSection(
      title: 'LIVE PROGRESS TRACKER',
      icon: Icons.track_changes,
      color: Colors.orange.shade700,
      children: [
        ...stageProgress.entries.map((entry) {
          return Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.labelColor)),
                  ),
                  Expanded(
                    child: (isAdmin) 
                      ? SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryButton,
                            thumbColor: AppColors.border,
                            inactiveTrackColor: Colors.black12,
                            overlayShape: SliderComponentShape.noOverlay,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: entry.value.toDouble(),
                            min: 0, max: 100, divisions: 10,
                            onChanged: (v) => onProgressChanged(entry.key, v.toInt()),
                          ),
                        )
                      : LinearProgressIndicator(
                          value: entry.value / 100,
                          backgroundColor: Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(entry.value == 100 ? AppColors.resultGreen : AppColors.primaryButton),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    alignment: Alignment.centerRight,
                    child: Text('${entry.value}%',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.border)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          );
        }),
        const SizedBox(height: 8),
        // Overall Progress Bar for both Admin and Client
        Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: stageProgress.values.fold(0, (a, b) => a + b) / (stageProgress.length * 100),
                backgroundColor: Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.resultGreen),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'OVERALL COMPLETION: ${(stageProgress.values.fold(0, (a, b) => a + b) / stageProgress.length).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.resultGreen, letterSpacing: 1.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isAdmin)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: isUpdating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload, size: 16),
              label: Text(isUpdating ? 'UPDATING...' : 'UPDATE PROGRESS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: (isAdmin && !isUpdating) ? onUpdate : null,
            ),
          ),
      ],
    );
  }
}

class ContractManagementSection extends StatelessWidget {
  final Map<String, dynamic>? contractData;
  final bool isAdmin;
  final bool isSending;
  final String clientName;
  final String unitNumber;
  final VoidCallback onSend;
  final Function(String, String) onDownload;
  final Function(String, String) onShareLink;

  const ContractManagementSection({
    super.key,
    required this.contractData,
    required this.isAdmin,
    required this.isSending,
    required this.clientName,
    required this.unitNumber,
    required this.onSend,
    required this.onDownload,
    required this.onShareLink,
  });

  @override
  Widget build(BuildContext context) {
    return overviewSection(
      title: 'CONTRACT MANAGEMENT',
      icon: Icons.draw,
      color: Colors.indigo,
      children: [
        if (contractData == null) ...[  
          const Text('No contract sent yet.',
              style: TextStyle(fontSize: 11, color: Colors.black45)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: isSending
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send, size: 16),
              label: Text(isSending ? 'UPLOADING...' : 'SEND CONTRACT FOR SIGNATURE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: (isAdmin && !isSending) ? onSend : null,
            ),
          ),
        ] else ...[
          _buildContractStatusBadge(contractData!['contract_status'] as String? ?? ''),
          const SizedBox(height: 8),
          if (contractData!['contract_status'] == 'signed_by_client') ...[
            if (contractData!['signed_at'] != null)
              Text(
                '✍️ Signed: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(contractData!['signed_at'] as String).toLocal())}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.resultGreen),
              ),
            const SizedBox(height: 10),
            if (contractData!['signed_pdf_url'] != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('DOWNLOAD SIGNED CONTRACT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.resultGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => onDownload(
                    contractData!['signed_pdf_url'] as String,
                    unitNumber,
                  ),
                ),
              ),
          ] else if (contractData!['contract_status'] == 'pending_client_signature') ...[
            const Text('Awaiting client signature on web portal.',
                style: TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.share, size: 14),
              label: const Text('RESEND SIGNING LINK', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final token = contractData!['access_token'] as String?;
                if (token != null) onShareLink(token, clientName);
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildContractStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'pending_client_signature':
        color = Colors.orange; label = '⏳ AWAITING SIGNATURE'; icon = Icons.hourglass_top;
        break;
      case 'signed_by_client':
        color = AppColors.resultGreen; label = '✅ CONTRACT SIGNED'; icon = Icons.verified;
        break;
      default:
        color = Colors.grey; label = status.toUpperCase(); icon = Icons.info_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class ChangeOrdersSection extends StatelessWidget {
  final List<Map<String, dynamic>> changeOrders;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final bool isAdmin;
  final bool isSending;
  final VoidCallback onSend;

  const ChangeOrdersSection({
    super.key,
    required this.changeOrders,
    required this.descriptionController,
    required this.amountController,
    required this.isAdmin,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.');
    return overviewSection(
      title: 'CHANGE ORDERS',
      icon: Icons.change_circle_outlined,
      color: Colors.deepOrange,
      children: [
        if (changeOrders.isNotEmpty) ...[
          ...changeOrders.take(3).map((co) {
            final status = co['status'] as String? ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: status == 'approved' ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: status == 'approved' ? Colors.green.shade300 : Colors.orange.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(co['description'] as String? ?? '',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  Text(currencyFmt.format((co['extra_amount'] as num?) ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.border)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 'approved' ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: descriptionController,
          decoration: AppStyles.inputDecoration('Extra Work Description'),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: AppStyles.inputDecoration('Extra Amount (Rs.)').copyWith(
            prefixIcon: const Icon(Icons.currency_rupee, size: 18, color: AppColors.border),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: isSending
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_and_archive, size: 16),
            label: Text(isSending ? 'SENDING...' : 'GENERATE & SEND CHANGE ORDER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: (isAdmin && !isSending) ? onSend : null,
          ),
        ),
      ],
    );
  }
}

class GpsCheckinSection extends StatelessWidget {
  final bool isCheckingIn;
  final VoidCallback onCheckIn;

  const GpsCheckinSection({
    super.key,
    required this.isCheckingIn,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return overviewSection(
      title: 'GPS SITE CHECK-IN',
      icon: Icons.location_on,
      color: Colors.teal,
      children: [
        const Text(
          'Log your GPS coordinates to verify physical presence at this site. Auto-triggered on stage updates and photo uploads.',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: isCheckingIn
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.my_location, size: 16),
            label: Text(isCheckingIn ? 'LOCATING...' : '📍 CHECK IN AT SITE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isCheckingIn ? null : onCheckIn,
          ),
        ),
      ],
    );
  }
}

class PaymentReceiptsSection extends StatelessWidget {
  final TextEditingController amountController;
  final List<Map<String, dynamic>> paymentReceipts;
  final bool isAdmin;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const PaymentReceiptsSection({
    super.key,
    required this.amountController,
    required this.paymentReceipts,
    required this.isAdmin,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.');
    return overviewSection(
      title: 'PAYMENT RECEIPTS',
      icon: Icons.receipt_long,
      color: Colors.purple,
      children: [
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: AppStyles.inputDecoration('Amount Received Today (Rs.)').copyWith(
            prefixIcon: const Icon(Icons.currency_rupee, size: 18, color: AppColors.border),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: isGenerating
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf, size: 16),
            label: Text(isGenerating ? 'GENERATING...' : 'GENERATE RECEIPT & PUSH TO CLIENT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: (isAdmin && !isGenerating) ? onGenerate : null,
          ),
        ),
        if (paymentReceipts.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('RECEIPT HISTORY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.labelColor, letterSpacing: 1)),
          const SizedBox(height: 6),
          ...paymentReceipts.take(5).map((rec) {
            final dateStr = rec['payment_date'] as String? ?? '';
            final amount  = (rec['amount_received'] as num?)?.toDouble() ?? 0;
            final pdfUrl  = rec['receipt_pdf_url'] as String?;
            return ListTile(
              dense: true,
              leading: const Icon(Icons.receipt, size: 20, color: Colors.purple),
              title: Text(currencyFmt.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              subtitle: Text(dateStr, style: const TextStyle(fontSize: 10)),
              trailing: pdfUrl != null
                  ? IconButton(
                      icon: const Icon(Icons.download, size: 18, color: Colors.purple),
                      onPressed: () => launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication),
                    )
                  : null,
            );
          }),
        ],
      ],
    );
  }
}

class DocumentsHistorySection extends StatelessWidget {
  final Map<String, dynamic>? contractData;
  final List<Map<String, dynamic>> changeOrders;
  final List<Map<String, dynamic>> paymentReceipts;
  final Function(String) onDownload;

  const DocumentsHistorySection({
    super.key,
    required this.contractData,
    required this.changeOrders,
    required this.paymentReceipts,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.');
    return overviewSection(
      title: 'DOCUMENTS HISTORY',
      icon: Icons.folder_open,
      color: Colors.brown.shade600,
      children: [
        if (contractData == null && changeOrders.isEmpty && paymentReceipts.isEmpty)
          const Text('No documents generated yet.', style: TextStyle(fontSize: 11, color: Colors.black45))
        else ...[
          if (contractData?['unsigned_pdf_url'] != null)
            _docTile('📄 Contract (Unsigned)', contractData!['unsigned_pdf_url'] as String),
          if (contractData?['signed_pdf_url'] != null)
            _docTile('✅ Contract (Signed)', contractData!['signed_pdf_url'] as String),
          ...changeOrders
              .where((o) => o['pdf_url'] != null)
              .map((o) => _docTile('🔄 Change Order — ${currencyFmt.format((o['extra_amount'] as num?) ?? 0)}', o['pdf_url'] as String)),
          ...paymentReceipts
              .where((r) => r['receipt_pdf_url'] != null)
              .map((r) => _docTile('💰 Receipt — ${currencyFmt.format((r['amount_received'] as num?) ?? 0)}', r['receipt_pdf_url'] as String)),
        ],
      ],
    );
  }

  Widget _docTile(String label, String url) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.picture_as_pdf, size: 20, color: AppColors.border),
      title: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      trailing: IconButton(
        icon: const Icon(Icons.download, size: 18, color: AppColors.border),
        onPressed: () => onDownload(url),
      ),
    );
  }
}
