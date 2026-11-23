import 'package:flutter/material.dart';
import '../../../models/client_model.dart';
import '../../../models/quotation.dart';

class HubFinancialGrid extends StatelessWidget {
  final Client client;
  final Quotation? quotation;
  final String? clientName;
  final double? totalContractOverride;
  final double? paidAmountOverride;
  final double? balanceDueOverride;

  const HubFinancialGrid({
    super.key,
    required this.client,
    this.quotation,
    this.clientName,
    this.totalContractOverride,
    this.paidAmountOverride,
    this.balanceDueOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Contract Total: ₹${(totalContractOverride ?? client.totalContractAmount).toStringAsFixed(2)}'),
      ),
    );
  }
}
