import 'package:flutter/material.dart';
import '../../../models/client_model.dart';

class HubClientDetailsCard extends StatelessWidget {
  final Client client;

  const HubClientDetailsCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Location: ${client.siteLocation} | Phone: ${client.phoneNumber}'),
      ),
    );
  }
}
