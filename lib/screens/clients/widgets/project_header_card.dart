import 'package:flutter/material.dart';
import '../../../models/client_model.dart';
import '../../../theme/app_theme.dart';
import '../../call_screen.dart';

class ProjectHeaderCard extends StatelessWidget {
  final Client client;
  final bool isEditing;
  final TextEditingController nameController, phoneController, locationController;
  final String status;
  final List<String> selectedWorkers;
  final VoidCallback onAssignWorkers, onToggleEdit;
  final ValueChanged<String?> onStatusChanged;
  final bool isSaving;

  const ProjectHeaderCard({
    super.key,
    required this.client,
    required this.isEditing,
    required this.nameController,
    required this.phoneController,
    required this.locationController,
    required this.status,
    required this.selectedWorkers,
    required this.onAssignWorkers,
    required this.onStatusChanged,
    required this.onToggleEdit,
    required this.isSaving,
  });

  void _startCall(BuildContext context, String channel, bool isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channel,
          isVideoCall: isVideo,
        ),
      ),
    );
  }

  void _showCallOptionDialog(BuildContext context, String channel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SELECT CALL TYPE',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.border),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryButton,
                child: Icon(Icons.phone, color: Colors.white),
              ),
              title: const Text('VOICE CALL', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Free Internet Voice Call'),
              onTap: () {
                Navigator.pop(context);
                _startCall(context, channel, false);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.border,
                child: Icon(Icons.videocam, color: Colors.white),
              ),
              title: const Text('VIDEO CALL', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('High-Quality Video Call'),
              onTap: () {
                Navigator.pop(context);
                _startCall(context, channel, true);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = client.latitude != null && client.longitude != null;
    final hasSelfie = client.clientSelfie.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(5)),
                    child: Text('SITE: ${client.unitNumber}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: status,
                        isExpanded: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.border, fontSize: 10),
                        items: ['Pending', 'Active', 'Completed']
                            .map((st) => DropdownMenuItem(value: st, child: Text(st.toUpperCase(), overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: isEditing ? null : onStatusChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: Icon(isEditing ? Icons.save : Icons.edit, color: AppColors.border, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: isSaving ? null : onToggleEdit),
                const SizedBox(width: 6),
                Icon(hasPin ? Icons.gps_fixed : Icons.gps_off,
                    size: 12, color: hasPin ? AppColors.resultGreen : AppColors.alertRed),
                const SizedBox(width: 3),
                Text(hasPin ? 'PINNED' : 'NO GPS',
                    style: TextStyle(
                        color: hasPin ? AppColors.resultGreen : AppColors.alertRed,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: hasSelfie ? NetworkImage(client.clientSelfie) : null,
              child: !hasSelfie ? const Icon(Icons.person, color: AppColors.border) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isEditing
                  ? Column(children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', isDense: true)),
                      TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', isDense: true)),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(client.clientName.toUpperCase(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.border)),
                      Text('Phone: ${client.phoneNumber}',
                          style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
            ),
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.phone_in_talk, color: AppColors.resultGreen, size: 24),
                onPressed: () => _showCallOptionDialog(context, client.unitNumber),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.location_on, size: 14, color: AppColors.labelColor),
          const SizedBox(width: 4),
          Expanded(
            child: isEditing
                ? TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location', isDense: true))
                : Text(client.siteLocation,
                    style: const TextStyle(color: AppColors.labelColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        Row(children: [
          const Icon(Icons.engineering, size: 14, color: AppColors.border),
          const SizedBox(width: 4),
          Expanded(
              child: Text(
                  selectedWorkers.isEmpty ? 'NO ASSIGNED WORKERS' : 'WORKERS: ${selectedWorkers.join(', ').toUpperCase()}',
                  style: const TextStyle(color: AppColors.border, fontSize: 10, fontWeight: FontWeight.bold))),
          if (!isEditing)
            IconButton(
                icon: const Icon(Icons.group_add, color: AppColors.border, size: 18), onPressed: onAssignWorkers),
        ]),
      ],
    );
  }
}
