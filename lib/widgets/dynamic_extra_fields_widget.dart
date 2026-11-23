import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'brand_logo_overlay_widget.dart';

/// Schema-Agnostic Dynamic Extra Fields Renderer
/// Automatically extracts and renders unmapped/new incoming payload keys
/// as labeled rows/chips or safe image previews inside a clean, overflow-free
/// collapsible block.
class DynamicExtraFieldsWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Set<String> customKnownKeys;

  const DynamicExtraFieldsWidget({
    super.key,
    required this.data,
    this.customKnownKeys = const {},
  });

  /// Default standard keys that are already displayed in dedicated UI fields.
  static const Set<String> defaultStandardKeys = {
    'id',
    'docId',
    'doc_id',
    'clientName',
    'client_name',
    'name',
    'client',
    'clientPhone',
    'client_phone',
    'phone',
    'phoneNumber',
    'phone_number',
    'projectId',
    'project_id',
    'siteId',
    'site_id',
    'unitNumber',
    'unit_number',
    'createdAt',
    'created_at',
    'timestamp',
    'time',
    'date',
    'updatedAt',
    'updated_at',
    'updatedAtIso',
    'photoUrl',
    'photo_url',
    'url',
    'clientSelfie',
    'client_selfie',
    'profile_photo',
    'status',
    'type',
    'action',
    'title',
    'note',
    'requirements',
    'budgetAmount',
    'rooms',
    'latitude',
    'longitude',
    'googleMapsUrl',
    'fileName',
  };

  @override
  State<DynamicExtraFieldsWidget> createState() => _DynamicExtraFieldsWidgetState();
}

class _DynamicExtraFieldsWidgetState extends State<DynamicExtraFieldsWidget> {
  bool _isExpanded = false;

  /// Returns true if the string looks like an image URL or Base64 string (ignoring blob:)
  bool _isPhotoValue(String val) {
    final clean = val.trim();
    if (clean.isEmpty || clean.startsWith('blob:')) return false;
    if (clean.startsWith('http://') || clean.startsWith('https://')) return true;
    if (clean.startsWith('data:image/')) return true;
    // Check if it's a valid raw Base64 string of meaningful length
    if (clean.length > 100 && !clean.contains(' ')) {
      try {
        final sample = clean.contains(',') ? clean.split(',').last : clean;
        base64Decode(sample.substring(0, 32));
        return true;
      } catch (_) {}
    }
    return false;
  }

  Widget _buildPhotoPreview(BuildContext context, String photoStr, String label) {
    final clean = photoStr.trim();
    Widget imgWidget;

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      imgWidget = Image.network(
        clean,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24),
      );
    } else {
      try {
        final base64Str = clean.contains(',') ? clean.split(',').last.trim() : clean;
        final bytes = base64Decode(base64Str);
        imgWidget = Image.memory(
          bytes,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24),
        );
      } catch (_) {
        imgWidget = const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24);
      }
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.black87,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                    brandText: 'PCM',
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      width: double.infinity,
                      child: clean.startsWith('http')
                          ? Image.network(clean, fit: BoxFit.contain)
                          : Image.memory(base64Decode(clean.contains(',') ? clean.split(',').last : clean), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 50,
          height: 50,
          child: BrandLogoOverlayWidget(
            brandText: 'PCM',
            logoSize: 8,
            child: imgWidget,
          ),
        ),
      ),
    );
  }

  String _formatKeyLabel(String key) {
    // Converts camelCase or snake_case to Human Title Case
    final result = key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .replaceAll('_', ' ')
        .trim();
    return result[0].toUpperCase() + result.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final knownKeys = {
      ...DynamicExtraFieldsWidget.defaultStandardKeys,
      ...widget.customKnownKeys,
    };

    // Filter out standard keys
    final Map<String, dynamic> extraFields = {};
    widget.data.forEach((k, v) {
      if (!knownKeys.contains(k) && v != null && v.toString().trim().isNotEmpty) {
        extraFields[k] = v;
      }
    });

    if (extraFields.isEmpty) {
      return const SizedBox.shrink();
    }

    final fieldEntries = extraFields.entries.toList();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible Header Row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Colors.amber.shade900,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'EXTRA FIELDS (${fieldEntries.length}): ${fieldEntries.map((e) => _formatKeyLabel(e.key)).join(", ")}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: Colors.amber.shade900,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Dynamic Fields List
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fieldEntries.map((entry) {
                  final rawKey = entry.key;
                  final label = _formatKeyLabel(rawKey);
                  final val = entry.value;

                  // 1. If value is an image string
                  if (val is String && _isPhotoValue(val)) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '$label: ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.border),
                          ),
                          const SizedBox(width: 6),
                          _buildPhotoPreview(context, val, label),
                        ],
                      ),
                    );
                  }

                  // 2. If value is a Map or List
                  String displayVal;
                  if (val is Map || val is List) {
                    displayVal = jsonEncode(val);
                  } else {
                    displayVal = val.toString();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: RichText(
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$label: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppColors.border,
                              ),
                            ),
                            TextSpan(
                              text: displayVal,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
