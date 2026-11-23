import 'package:flutter/material.dart';
import '../../../models/client_model.dart';

class HubHeaderCard extends StatelessWidget {
  final Client client;
  final bool initialFolderOpen;

  const HubHeaderCard({super.key, required this.client, this.initialFolderOpen = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Header: ${client.clientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
