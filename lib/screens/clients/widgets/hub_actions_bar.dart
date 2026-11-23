import 'package:flutter/material.dart';
import '../../../models/client_model.dart';
import '../../../models/quotation.dart';

class HubActionsBar extends StatelessWidget {
  final Client client;
  final Quotation? quotation;

  const HubActionsBar({super.key, required this.client, this.quotation});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
