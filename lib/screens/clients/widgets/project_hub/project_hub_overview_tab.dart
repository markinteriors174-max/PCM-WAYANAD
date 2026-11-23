import 'package:flutter/material.dart';
import '../../../../models/client_model.dart';
import 'overview_sections.dart';

class ProjectHubOverviewTab extends StatelessWidget {
  final bool isLoading;
  final Client client;
  final double discountAmount;
  final TextEditingController discountController;
  final TextEditingController emailController;
  final String customerType;
  final bool gstEnabled;
  final TextEditingController gstinController;
  final bool isAdmin;
  final bool isSavingProfile;
  final DateTime? nextPaymentDueDate;
  final String upiId;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final Map<String, int> stageProgress;
  final bool isUpdatingStage;
  final Map<String, dynamic>? contractData;
  final bool isSendingContract;
  final List<Map<String, dynamic>> changeOrders;
  final TextEditingController changeDescController;
  final TextEditingController changeAmtController;
  final bool isSendingChangeOrder;
  final bool isCheckingInGps;
  final TextEditingController receiptAmtController;
  final bool isGeneratingReceipt;
  final List<Map<String, dynamic>> paymentReceipts;

  final Function(String) onCustomerTypeChanged;
  final Function(bool) onGstToggled;
  final VoidCallback onSaveProfile;
  final Function(String) onDiscountChanged;
  final VoidCallback onSetPaymentDate;
  final Function(String, int) onStageProgressChanged;
  final VoidCallback onUpdateProgress;
  final VoidCallback onSendContract;
  final Function(String, String) onDownloadSignedContract;
  final Function(String, String) onShareContractLink;
  final VoidCallback onSendChangeOrder;
  final VoidCallback onGpsCheckIn;
  final VoidCallback onGenerateReceipt;
  final Function(String) onDownloadDoc;

  const ProjectHubOverviewTab({
    super.key,
    required this.isLoading,
    required this.client,
    required this.discountAmount,
    required this.discountController,
    required this.emailController,
    required this.customerType,
    required this.gstEnabled,
    required this.gstinController,
    required this.isAdmin,
    required this.isSavingProfile,
    required this.nextPaymentDueDate,
    required this.upiId,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.stageProgress,
    required this.isUpdatingStage,
    required this.contractData,
    required this.isSendingContract,
    required this.changeOrders,
    required this.changeDescController,
    required this.changeAmtController,
    required this.isSendingChangeOrder,
    required this.isCheckingInGps,
    required this.receiptAmtController,
    required this.isGeneratingReceipt,
    required this.paymentReceipts,
    required this.onCustomerTypeChanged,
    required this.onGstToggled,
    required this.onSaveProfile,
    required this.onDiscountChanged,
    required this.onSetPaymentDate,
    required this.onStageProgressChanged,
    required this.onUpdateProgress,
    required this.onSendContract,
    required this.onDownloadSignedContract,
    required this.onShareContractLink,
    required this.onSendChangeOrder,
    required this.onGpsCheckIn,
    required this.onGenerateReceipt,
    required this.onDownloadDoc,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          ClientProfileSection(
            emailController: emailController,
            customerType: customerType,
            gstEnabled: gstEnabled,
            gstinController: gstinController,
            isAdmin: isAdmin,
            isSaving: isSavingProfile,
            onCustomerTypeChanged: onCustomerTypeChanged,
            onGstToggled: onGstToggled,
            onSave: onSaveProfile,
          ),
          const SizedBox(height: 14),
          FinancialsSection(
            client: client,
            discountAmount: discountAmount,
            discountController: discountController,
            nextPaymentDueDate: nextPaymentDueDate,
            upiId: upiId,
            bankName: bankName,
            accountNumber: accountNumber,
            ifscCode: ifscCode,
            onDiscountChanged: onDiscountChanged,
            onSetPaymentDate: onSetPaymentDate,
            isAdmin: isAdmin,
          ),
          const SizedBox(height: 14),
          ProgressTrackerSection(
            stageProgress: stageProgress,
            isAdmin: isAdmin,
            isUpdating: isUpdatingStage,
            onProgressChanged: onStageProgressChanged,
            onUpdate: onUpdateProgress,
          ),
          const SizedBox(height: 14),
          ContractManagementSection(
            contractData: contractData,
            isAdmin: isAdmin,
            isSending: isSendingContract,
            clientName: client.clientName,
            unitNumber: client.unitNumber,
            onSend: onSendContract,
            onDownload: onDownloadSignedContract,
            onShareLink: onShareContractLink,
          ),
          const SizedBox(height: 14),
          ChangeOrdersSection(
            changeOrders: changeOrders,
            descriptionController: changeDescController,
            amountController: changeAmtController,
            isAdmin: isAdmin,
            isSending: isSendingChangeOrder,
            onSend: onSendChangeOrder,
          ),
          const SizedBox(height: 14),
          GpsCheckinSection(
            isCheckingIn: isCheckingInGps,
            onCheckIn: onGpsCheckIn,
          ),
          const SizedBox(height: 14),
          PaymentReceiptsSection(
            amountController: receiptAmtController,
            paymentReceipts: paymentReceipts,
            isAdmin: isAdmin,
            isGenerating: isGeneratingReceipt,
            onGenerate: onGenerateReceipt,
          ),
          const SizedBox(height: 14),
          DocumentsHistorySection(
            contractData: contractData,
            changeOrders: changeOrders,
            paymentReceipts: paymentReceipts,
            onDownload: onDownloadDoc,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
