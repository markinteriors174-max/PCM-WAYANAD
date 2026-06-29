import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/client_model.dart';
import '../../../services/client_service.dart';

class WorkerClientHubCard extends StatelessWidget {
  final Client client;

  const WorkerClientHubCard({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, color: AppColors.border, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.clientName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.border)),
                    Text(client.siteLocation, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(5)),
                child: const Text('ACTIVE SITE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9)),
              ),
            ],
          ),
          const Divider(height: 30),
          const Text('RECENT MESSAGES', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.labelColor, fontSize: 10)),
          const SizedBox(height: 10),
          _buildClientMessagesList(),
          const SizedBox(height: 20),
          const Text('SITE PHOTOS', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.labelColor, fontSize: 10)),
          const SizedBox(height: 10),
          _buildClientPhotosGrid(),
        ],
      ),
    );
  }

  Widget _buildClientMessagesList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ClientService.instance.fetchChatMessages(client.unitNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator(color: AppColors.border);
        final messages = snapshot.data ?? [];
        if (messages.isEmpty) return const Text('No messages from client.', style: TextStyle(fontSize: 11, color: Colors.grey));

        return Column(
          children: messages.take(3).map((m) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
            child: Text(m['message'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          )).toList(),
        );
      },
    );
  }

  Widget _buildClientPhotosGrid() {
    return FutureBuilder<List<String>>(
      future: ClientService.instance.fetchProjectPhotos(client.unitNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
        final photos = snapshot.data ?? [];
        if (photos.isEmpty) return const Text('No site photos uploaded.', style: TextStyle(fontSize: 11, color: Colors.grey));

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(right: 10),
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(image: NetworkImage(photos[index]), fit: BoxFit.cover),
              ),
            ),
          ),
        );
      },
    );
  }
}
