import 'package:flutter/material.dart';
import '../../../models/client_model.dart';
import '../../../models/quotation.dart';

class AdminDesignReviewCard extends StatelessWidget {
  final Client client;
  final Quotation? quotation;
  final VoidCallback? onQuotationApproved;

  const AdminDesignReviewCard({
    super.key,
    required this.client,
    this.quotation,
    this.onQuotationApproved,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
