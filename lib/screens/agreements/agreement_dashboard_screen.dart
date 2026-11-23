import 'package:flutter/material.dart';
import '../../models/quotation.dart';

class AgreementDashboardScreen extends StatelessWidget {
  final Quotation? quotation;
  final Quotation? initialQuotation;
  final String? initialProjectId;

  const AgreementDashboardScreen({
    super.key,
    this.quotation,
    this.initialQuotation,
    this.initialProjectId,
  });

  Quotation? get _effectiveQuotation => quotation ?? initialQuotation;

  @override
  Widget build(BuildContext context) {
    final clientName = _effectiveQuotation?.clientName ?? initialProjectId ?? 'Client';
    return Scaffold(
      appBar: AppBar(title: const Text('AGREEMENT DASHBOARD')),
      body: Center(child: Text('Agreement Dashboard for $clientName')),
    );
  }
}
