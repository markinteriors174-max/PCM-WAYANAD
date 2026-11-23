import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/client_model.dart';
import '../../../services/client_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/brand_logo_overlay_widget.dart';
import '../../../widgets/dynamic_extra_fields_widget.dart';

class AdminClientRequestsHub extends StatelessWidget {
  const AdminClientRequestsHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AdminLiveClientActivitySection(),
        SizedBox(height: 15),
        AdminReceivedPhotosSection(),
        SizedBox(height: 15),
        AdminBudgetInquiriesSection(),
        SizedBox(height: 15),
        AdminSiteMeetingsSection(),
        SizedBox(height: 15),
        AdminRoomPlansSection(),
      ],
    );
  }
}

// 0. REAL-TIME SCHEMA-AGNOSTIC CLIENT ACTIVITY FEED SECTION (ലൈവ് ക്ലയന്റ് സന്ദേശങ്ങൾ)
class AdminLiveClientActivitySection extends StatelessWidget {
  const AdminLiveClientActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('client_activity').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort descending by createdAt / timestamp
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = (aData['createdAt'] ?? aData['timestamp'] ?? aData['time'])?.toString() ?? '';
            final bTime = (bData['createdAt'] ?? bData['timestamp'] ?? bData['time'])?.toString() ?? '';
            return bTime.compareTo(aTime);
          });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.bolt_rounded, color: Colors.blue.shade900, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'REAL-TIME CLIENT ACTIVITY / ലൈവ് സന്ദേശങ്ങൾ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.border,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sortedDocs.length} LIVE UPDATES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Live incoming field updates, custom inputs, & client payloads from Web Portal & App.',
                style: TextStyle(fontSize: 10.5, color: Colors.black54),
              ),
              const Divider(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDocs.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final doc = sortedDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;

                  final String clientName = (data['clientName'] ?? data['client_name'] ?? data['name'] ?? 'Client').toString();
                  final String clientPhone = (data['clientPhone'] ?? data['client_phone'] ?? data['phone'] ?? '').toString();
                  final String siteId = (data['projectId'] ?? data['siteId'] ?? data['unitNumber'] ?? 'Site').toString();
                  final String activityType = (data['type'] ?? data['action'] ?? data['event'] ?? 'CLIENT_UPDATE').toString();
                  final String status = (data['status'] ?? 'new').toString();
                  final String rawTime = (data['createdAt'] ?? data['timestamp'] ?? data['time'])?.toString() ?? '';
                  final String timeStr = rawTime.length >= 16 ? rawTime.substring(0, 16).replaceAll('T', ' ') : rawTime;

                  final bool isReviewed = status.toLowerCase() == 'reviewed' || status.toLowerCase() == 'done';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isReviewed ? Colors.grey.shade50 : Colors.blue.shade50.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isReviewed ? Colors.grey.shade300 : Colors.blue.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isReviewed ? Colors.grey.shade200 : Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isReviewed ? Icons.check_circle_rounded : Icons.notifications_active_rounded,
                                color: isReviewed ? Colors.grey.shade700 : Colors.blue.shade800,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          clientName.toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            color: AppColors.border,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isReviewed ? Colors.grey.shade200 : Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          activityType.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: isReviewed ? Colors.grey.shade800 : Colors.blue.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Site: $siteId ${clientPhone.isNotEmpty ? "• $clientPhone" : ""} ${timeStr.isNotEmpty ? "• $timeStr" : ""}',
                                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: isReviewed ? 'Mark Pending' : 'Mark Reviewed',
                              icon: Icon(isReviewed ? Icons.undo_rounded : Icons.done_all_rounded, color: AppColors.border, size: 18),
                              onPressed: () async {
                                final newStatus = isReviewed ? 'new' : 'reviewed';
                                await FirebaseFirestore.instance.collection('client_activity').doc(docId).update({
                                  'status': newStatus,
                                  'updatedAt': DateTime.now().toIso8601String(),
                                });
                              },
                            ),
                            if (clientPhone.isNotEmpty)
                              IconButton(
                                tooltip: 'Call Client',
                                icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 18),
                                onPressed: () async {
                                  final Uri uri = Uri(scheme: 'tel', path: clientPhone);
                                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                                },
                              ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('client_activity').doc(docId).delete();
                              },
                            ),
                          ],
                        ),

                        // Dynamic Extra Fields (Schema-Agnostic rendering of any incoming new keys)
                        DynamicExtraFieldsWidget(data: data),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// 1. LIVE RECEIVED CLIENT PHOTOS SECTION (അയച്ച ഫോട്ടോകൾ)
class AdminReceivedPhotosSection extends StatelessWidget {
  const AdminReceivedPhotosSection({super.key});

  Widget _buildPhotoThumbnail(String? photoUrl, {double width = 60, double height = 60}) {
    final clean = photoUrl?.trim() ?? '';

    final fallback = Container(
      width: width,
      height: height,
      color: Colors.amber.shade100.withAlpha(120),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_outlined, color: AppColors.border, size: 20),
          SizedBox(height: 2),
          Text('No Photo', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.border)),
        ],
      ),
    );

    // Safely ignore dead blob: URLs on read
    if (clean.isEmpty || clean.startsWith('blob:')) return fallback;

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    try {
      final base64Str = clean.contains(',') ? clean.split(',').last.trim() : clean;
      final bytes = base64Decode(base64Str);
      if (bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
    } catch (_) {}

    return fallback;
  }

  void _showApplyToClientDialog(BuildContext context, String photoData, String defaultSiteId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StreamBuilder<List<Client>>(
        stream: ClientService.instance.getClients(),
        builder: (context, snapshot) {
          final clients = snapshot.data ?? [];

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_ind_rounded, color: AppColors.border, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Apply Photo to Client / Site Folder',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.border),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Select a client profile to attach and set this photo as their active site profile photo.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: BrandLogoOverlayWidget(
                          brandText: 'PCM',
                          logoSize: 10,
                          child: _buildPhotoThumbnail(photoData, width: 60, height: 60),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Source Site ID: $defaultSiteId',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.border),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Expanded(
                  child: clients.isEmpty
                      ? const Center(
                          child: Text('No registered clients found. Register a client first.', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.separated(
                          itemCount: clients.length,
                          separatorBuilder: (_, __) => const Divider(height: 10),
                          itemBuilder: (context, index) {
                            final c = clients[index];
                            final String displayId = c.unitNumber.isNotEmpty ? c.unitNumber : c.id;

                            return Card(
                              color: Colors.white,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.border,
                                  child: Text(
                                    c.clientName.isNotEmpty ? c.clientName[0].toUpperCase() : 'C',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  c.clientName.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.border),
                                ),
                                subtitle: Text(
                                  'Site: $displayId • ${c.phoneNumber}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryButton,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  child: const Text('APPLY PHOTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  onPressed: () async {
                                    final updatedClient = c.copyWith(clientSelfie: photoData);
                                    await ClientService.instance.updateClient(updatedClient);

                                    // Mirror to Firestore client_profiles & submissions
                                    final cleanDocId = displayId.replaceAll('#', '').trim();
                                    final payload = {
                                      'clientSelfie': photoData,
                                      'client_selfie': photoData,
                                      'photoUrl': photoData,
                                      'photo_url': photoData,
                                      'profile_photo': photoData,
                                      'updatedAt': FieldValue.serverTimestamp(),
                                      'updatedAtIso': DateTime.now().toIso8601String(),
                                    };

                                    try {
                                      final db = FirebaseFirestore.instance;
                                      await db.collection('clients').doc(cleanDocId).set(payload, SetOptions(merge: true));
                                      await db.collection('projects').doc(cleanDocId).set(payload, SetOptions(merge: true));
                                      await db.collection('client_profiles').doc(cleanDocId).set(payload, SetOptions(merge: true));
                                      if (c.id.isNotEmpty) {
                                        await db.collection('clients').doc(c.id).set(payload, SetOptions(merge: true)).catchError((_) {});
                                        await db.collection('client_profiles').doc(c.id).set(payload, SetOptions(merge: true)).catchError((_) {});
                                      }
                                    } catch (e) {
                                      debugPrint('Notice syncing photo payload: $e');
                                    }

                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Photo applied to ${c.clientName} ($displayId) & synced to cloud!'),
                                          backgroundColor: const Color(0xFF2E7D32),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFullPreview(BuildContext context, String photoData, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: BrandLogoOverlayWidget(
                brandText: 'PCM WAYANAD',
                logoSize: 16,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 450),
                  child: _buildPhotoThumbnail(photoData, width: double.infinity, height: 350),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('project_photos').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final validDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final url = (data['url'] ?? data['photoUrl'] ?? data['photo_url'])?.toString().trim() ?? '';
          return url.isNotEmpty && !url.startsWith('blob:');
        }).toList();

        if (validDocs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort descending by createdAt
        validDocs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt']?.toString() ?? '';
          final bTime = (b.data() as Map<String, dynamic>)['createdAt']?.toString() ?? '';
          return bTime.compareTo(aTime);
        });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryButton.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryButton, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'RECEIVED CLIENT PHOTOS / അയച്ച ഫോട്ടോകൾ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.border,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryButton.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${validDocs.length} PHOTOS',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryButton,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: validDocs.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final doc = validDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;

                  final String url = (data['url'] ?? data['photoUrl'] ?? data['photo_url'])?.toString().trim() ?? '';
                  final String siteId = (data['siteId'] ?? data['projectId'] ?? data['unitNumber'] ?? 'General').toString();
                  final String name = (data['name'] ?? data['fileName'] ?? 'Photo #${index + 1}').toString();
                  final String timeStr = data['createdAt']?.toString().substring(0, 16).replaceAll('T', ' ') ?? '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _showFullPreview(context, url, '$name ($siteId)'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 58,
                                height: 58,
                                child: BrandLogoOverlayWidget(
                                  brandText: 'PCM',
                                  logoSize: 10,
                                  child: _buildPhotoThumbnail(url, width: 58, height: 58),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Site / Client: $siteId',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.border),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (timeStr.isNotEmpty)
                                  Text('Received: $timeStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryButton,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 1,
                            ),
                            child: const Text('APPLY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            onPressed: () => _showApplyToClientDialog(context, url, siteId),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Preview',
                            icon: const Icon(Icons.visibility_rounded, color: AppColors.border, size: 18),
                            onPressed: () => _showFullPreview(context, url, '$name ($siteId)'),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('project_photos').doc(docId).delete();
                            },
                          ),
                        ],
                      ),
                      // Schema-Agnostic Dynamic Extra Fields
                      DynamicExtraFieldsWidget(data: data),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// 2. LIVE CLIENT BUDGET INQUIRIES SECTION ("ഇതുകൊണ്ട് പണി തീർക്കാൻ പറ്റുമോ?")
class AdminBudgetInquiriesSection extends StatelessWidget {
  const AdminBudgetInquiriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('client_budget_inquiries').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort descending by createdAt
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
          ..sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt']?.toString() ?? '';
            final bTime = (b.data() as Map<String, dynamic>)['createdAt']?.toString() ?? '';
            return bTime.compareTo(aTime);
          });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.account_balance_wallet_rounded, color: Colors.amber.shade900, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'BUDGET CHECK / ബജറ്റ് പരിശോധന',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.border,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sortedDocs.length} INQUIRIES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Client Question: "ഇതുകൊണ്ട് പണി തീർക്കാൻ പറ്റുമോ? (Ask PCM Admin)"',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
              ),
              const Divider(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDocs.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final doc = sortedDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;

                  final double budget = (data['budgetAmount'] as num?)?.toDouble() ?? 0.0;
                  final String clientName = data['clientName']?.toString() ?? 'Client';
                  final String clientPhone = data['clientPhone']?.toString() ?? '';
                  final String projectId = data['projectId']?.toString() ?? 'Site';
                  final String note = (data['note'] ?? data['requirements'])?.toString() ?? '';
                  final String status = data['status']?.toString() ?? 'pending';
                  final String timeStr = data['createdAt']?.toString().substring(0, 16).replaceAll('T', ' ') ?? '';

                  final bool isReviewed = status.toLowerCase() == 'reviewed' || status.toLowerCase() == 'done';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isReviewed ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isReviewed ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                              color: isReviewed ? Colors.green : Colors.amber.shade900,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Budget: ₹ ${budget.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isReviewed ? Colors.green.shade100 : Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isReviewed ? Colors.green.shade900 : Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$clientName • Site: $projectId',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.border),
                                ),
                                if (note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text('Requirements: $note', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                  ),
                                if (timeStr.isNotEmpty)
                                  Text('Submitted: $timeStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: isReviewed ? 'Mark Pending' : 'Mark Reviewed',
                            icon: Icon(isReviewed ? Icons.undo_rounded : Icons.done_all_rounded, color: AppColors.border, size: 18),
                            onPressed: () async {
                              final newStatus = isReviewed ? 'pending' : 'reviewed';
                              await FirebaseFirestore.instance.collection('client_budget_inquiries').doc(docId).update({
                                'status': newStatus,
                                'updatedAt': DateTime.now().toIso8601String(),
                              });
                            },
                          ),
                          if (clientPhone.isNotEmpty)
                            IconButton(
                              tooltip: 'Call Client',
                              icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 18),
                              onPressed: () async {
                                final Uri uri = Uri(scheme: 'tel', path: clientPhone);
                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                              },
                            ),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('client_budget_inquiries').doc(docId).delete();
                            },
                          ),
                        ],
                      ),
                      // Schema-Agnostic Dynamic Extra Fields
                      DynamicExtraFieldsWidget(data: data),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// 3. LIVE SITE MEETING REQUESTS SECTION (സൈറ്റ് മീറ്റിംഗ് / നേരിട്ട് കാണാൻ)
class AdminSiteMeetingsSection extends StatelessWidget {
  const AdminSiteMeetingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('site_meeting_requests').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort descending by createdAt
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
          ..sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt']?.toString() ?? '';
            final bTime = (b.data() as Map<String, dynamic>)['createdAt']?.toString() ?? '';
            return bTime.compareTo(aTime);
          });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pin_drop_rounded, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'SITE MEETING REQUESTS / സൈറ്റ് മീറ്റിംഗ് (നേരിട്ട് കാണാൻ)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.border,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sortedDocs.length} REQUESTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDocs.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final doc = sortedDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;

                  final String clientName = data['clientName']?.toString() ?? 'Client';
                  final String clientPhone = data['clientPhone']?.toString() ?? '';
                  final String projectId = data['projectId']?.toString() ?? 'Site';
                  final double lat = (data['latitude'] as num?)?.toDouble() ?? 11.6854;
                  final double lng = (data['longitude'] as num?)?.toDouble() ?? 76.1320;
                  final String googleMapsUrl = data['googleMapsUrl']?.toString() ??
                      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                  final String status = data['status']?.toString() ?? 'pending';
                  final String timeStr = data['createdAt']?.toString().substring(0, 16).replaceAll('T', ' ') ?? '';

                  final bool isScheduled = status.toLowerCase() == 'scheduled' || status.toLowerCase() == 'completed';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isScheduled ? Colors.blue.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isScheduled ? Icons.event_available_rounded : Icons.location_on_rounded,
                              color: isScheduled ? Colors.blue : Colors.green.shade800,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      clientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.border),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isScheduled ? Colors.blue.shade100 : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isScheduled ? Colors.blue.shade900 : Colors.green.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('Site ID: $projectId • Time: $timeStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: isScheduled ? 'Mark Pending' : 'Mark Scheduled',
                            icon: Icon(isScheduled ? Icons.undo_rounded : Icons.check_circle_outline_rounded, color: AppColors.border, size: 18),
                            onPressed: () async {
                              final newStatus = isScheduled ? 'pending' : 'scheduled';
                              await FirebaseFirestore.instance.collection('site_meeting_requests').doc(docId).update({
                                'status': newStatus,
                                'updatedAt': DateTime.now().toIso8601String(),
                              });
                            },
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('site_meeting_requests').doc(docId).delete();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.map_rounded, size: 15),
                              label: const Text('Open in Google Maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final Uri uri = Uri.parse(googleMapsUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ),
                          if (clientPhone.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green.shade800,
                                side: BorderSide(color: Colors.green.shade700),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.phone_rounded, size: 15),
                              label: const Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final Uri uri = Uri(scheme: 'tel', path: clientPhone);
                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                              },
                            ),
                          ],
                        ],
                      ),
                      // Schema-Agnostic Dynamic Extra Fields
                      DynamicExtraFieldsWidget(data: data),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// 4. LIVE SUBMITTED ROOM DESIGN PLANS SECTION (മുറികളുടെ പ്ലാൻ - സമർപ്പിക്കുക)
class AdminRoomPlansSection extends StatelessWidget {
  const AdminRoomPlansSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('client_room_plans').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort descending by createdAt
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
          ..sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt']?.toString() ?? '';
            final bTime = (b.data() as Map<String, dynamic>)['createdAt']?.toString() ?? '';
            return bTime.compareTo(aTime);
          });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.roofing_rounded, color: AppColors.border, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'SUBMITTED ROOM PLANS / മുറികളുടെ പ്ലാൻ (സമർപ്പിക്കുക)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.border,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sortedDocs.length} PLANS',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.border,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDocs.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final doc = sortedDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;

                  final String clientName = data['clientName']?.toString() ?? 'Client';
                  final String clientPhone = data['clientPhone']?.toString() ?? '';
                  final String projectId = data['projectId']?.toString() ?? 'Site';
                  final String status = data['status']?.toString() ?? 'pending';
                  final String timeStr = data['createdAt']?.toString().substring(0, 16).replaceAll('T', ' ') ?? '';

                  final List<dynamic> roomsList = data['rooms'] is List ? data['rooms'] as List : [];
                  final bool isReviewed = status.toLowerCase() == 'reviewed' || status.toLowerCase() == 'done';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.border)),
                              Text('Site: $projectId • $timeStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isReviewed ? Colors.green.shade100 : Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isReviewed ? Colors.green.shade900 : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: isReviewed ? 'Mark Pending' : 'Mark Reviewed',
                                icon: Icon(isReviewed ? Icons.undo_rounded : Icons.done_all_rounded, color: AppColors.border, size: 18),
                                onPressed: () async {
                                  final newStatus = isReviewed ? 'pending' : 'reviewed';
                                  await FirebaseFirestore.instance.collection('client_room_plans').doc(docId).update({
                                    'status': newStatus,
                                    'updatedAt': DateTime.now().toIso8601String(),
                                  });
                                },
                              ),
                              if (clientPhone.isNotEmpty)
                                IconButton(
                                  tooltip: 'Call Client',
                                  icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 18),
                                  onPressed: () async {
                                    final Uri uri = Uri(scheme: 'tel', path: clientPhone);
                                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                                  },
                                ),
                              IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('client_room_plans').doc(docId).delete();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (roomsList.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: roomsList.map((r) {
                              final roomMap = r is Map ? r : {};
                              final roomName = roomMap['room']?.toString() ?? 'Room';
                              final style = roomMap['style']?.toString() ?? 'Standard';
                              final note = roomMap['note']?.toString() ?? '';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.arrow_right_rounded, size: 16, color: AppColors.border),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(text: '$roomName: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.border)),
                                            TextSpan(text: style, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                                            if (note.isNotEmpty)
                                              TextSpan(text: ' • $note', style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      // Schema-Agnostic Dynamic Extra Fields
                      DynamicExtraFieldsWidget(data: data),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
