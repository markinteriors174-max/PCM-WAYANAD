import 'package:flutter/material.dart';
import '../models/quotation.dart';

class SiteFolderDeleteDialog extends StatelessWidget {
  final String title;
  final Quotation quotation;
  final Future<void> Function() onDelete;

  const SiteFolderDeleteDialog({
    super.key,
    required this.title,
    required this.quotation,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final clientName = quotation.clientName.isEmpty ? 'Site Project' : quotation.clientName;
    return AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
      content: Text('Are you sure you want to delete "$clientName" (${quotation.unitNumber})? This operation cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.of(context).pop();
            await onDelete();
          },
          child: const Text('DELETE'),
        ),
      ],
    );
  }
}
