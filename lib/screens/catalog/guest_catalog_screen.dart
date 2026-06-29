import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../auth/login_screen.dart';
import '../auth/portal_login_screen.dart';

class GuestCatalogScreen extends StatefulWidget {
  const GuestCatalogScreen({super.key});

  @override
  State<GuestCatalogScreen> createState() => _GuestCatalogScreenState();
}

class _GuestCatalogScreenState extends State<GuestCatalogScreen> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _catalogData = {};
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    if (kIsWeb) {
      // Mock data for Web to avoid SQFlite crashes until Web DB is implemented
      if (mounted) {
        setState(() {
          _catalogData = {
            'Gypsum Board': [
              {'name': 'Saint-Gobain Gyproc', 'unit': 'Nos', 'sku': 'SG-001'},
              {'name': 'USG Boral', 'unit': 'Nos', 'sku': 'USG-002'},
            ],
            'PVC Panels': [
              {'name': 'Premium High Gloss', 'unit': 'Nos', 'sku': 'PVC-HG'},
              {'name': 'Wooden Texture', 'unit': 'Nos', 'sku': 'PVC-WD'},
            ],
          };
          _categories = _catalogData.keys.toList();
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final data = await DatabaseService.instance.getMaterialDictionary();
      if (mounted) {
        setState(() {
          _catalogData = data;
          _categories = data.keys.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading catalog: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('PCM PRODUCT CATALOG', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => kIsWeb ? const PortalLoginScreen() : const LoginScreen()),
              );
            },
            icon: const Icon(Icons.login, color: Colors.white, size: 18),
            label: const Text('ADMIN LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.premiumGold))
          : _categories.isEmpty
              ? _buildEmptyState(isDark)
              : _buildCatalogList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: isDark ? Colors.white12 : AppColors.border.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Text('Catalog is currently being updated.', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCatalogList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final items = _catalogData[category] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                children: [
                  Container(width: 5, height: 25, color: AppColors.premiumGold),
                  const SizedBox(width: 10),
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1, color: isDark ? Colors.white : AppColors.border),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: items.length,
              itemBuilder: (context, itemIdx) {
                final item = items[itemIdx];
                return _buildProductCard(item, isDark);
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, bool isDark) {
    return Container(
      decoration: AppStyles.neumorphicDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        hasThickBorder: isDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Icon(Icons.architecture, size: 50, color: isDark ? Colors.white10 : Colors.black12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Material',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 5),
                Text(
                  'UNIT: ${item['unit']}',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey, fontWeight: FontWeight.bold),
                ),
                if (item['sku'] != null && (item['sku'] as String).isNotEmpty)
                  Text(
                    'SKU: ${item['sku']}',
                    style: const TextStyle(fontSize: 9, color: AppColors.premiumGold, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
