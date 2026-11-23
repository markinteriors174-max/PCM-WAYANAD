import 'package:flutter/material.dart';
import '../services/brand_service.dart';
import '../theme/app_theme.dart';

void showAddBrandDialog(
  BuildContext context, {
  required bool isChannel,
  required List<Map<String, dynamic>> items,
  required VoidCallback onBrandAdded,
}) {
  final nameCtrl = TextEditingController();
  final Map<String, TextEditingController> itemRateCtrls = {};
  for (var it in items) {
    final itemName = it['name'].toString();
    final defaultRate = (it['rate'] as num?)?.toDouble() ?? 0.0;
    itemRateCtrls[itemName] = TextEditingController(
        text: defaultRate > 0 ? defaultRate.toStringAsFixed(2) : '');
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(isChannel ? Icons.view_headline : Icons.dashboard,
              color: AppColors.primaryButton),
          const SizedBox(width: 8),
          Text(
            isChannel ? 'Add Channel Brand' : 'Add Board Brand',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                enabled: true,
                readOnly: false,
                decoration: InputDecoration(
                  labelText: isChannel
                      ? 'Channel Brand Name (e.g. JSW Steel)'
                      : 'Board Brand Name (e.g. Elephant Board)',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Text(
                'Item Rates for this Brand (Optional):',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              ...items.map((it) {
                final itemName = it['name'].toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          itemName,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        height: 36,
                        child: TextField(
                          controller: itemRateCtrls[itemName],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          enabled: true,
                          readOnly: false,
                          decoration: const InputDecoration(
                            prefixText: '₹',
                            labelText: 'Rate',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 6),
                          ),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryButton,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final brandName = nameCtrl.text.trim();
            if (brandName.isNotEmpty) {
              final rates = <String, double>{};
              itemRateCtrls.forEach((k, v) {
                final r = double.tryParse(v.text.trim()) ?? 0.0;
                if (r > 0) rates[k] = r;
              });
              await BrandService.instance.addBrand(
                brandName: brandName,
                isChannel: isChannel,
                rates: rates,
              );
              onBrandAdded();
              Navigator.pop(ctx);
            }
          },
          child: const Text('SAVE BRAND'),
        ),
      ],
    ),
  );
}

void showEditBrandDialog(
  BuildContext context, {
  required String currentBrandName,
  required bool isChannel,
  required List<Map<String, dynamic>> items,
  required VoidCallback onBrandUpdated,
}) {
  final nameCtrl = TextEditingController(text: currentBrandName);
  final isCustom = isChannel
      ? BrandService.instance.customChannelBrands.contains(currentBrandName)
      : BrandService.instance.customBoardBrands.contains(currentBrandName);

  final existingRates = BrandService.instance.brandRates[currentBrandName] ?? {};
  final Map<String, TextEditingController> itemRateCtrls = {};
  for (var it in items) {
    final itemName = it['name'].toString();
    final defaultRate =
        existingRates[itemName] ?? ((it['rate'] as num?)?.toDouble() ?? 0.0);
    itemRateCtrls[itemName] = TextEditingController(
        text: defaultRate > 0 ? defaultRate.toStringAsFixed(2) : '');
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isChannel ? Icons.view_headline : Icons.dashboard,
                  color: AppColors.primaryButton),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Edit $currentBrandName',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (isCustom)
            IconButton(
              icon:
                  const Icon(Icons.delete_forever, color: Colors.red, size: 20),
              tooltip: 'Delete Brand',
              onPressed: () async {
                await BrandService.instance
                    .deleteBrand(currentBrandName, isChannel);
                onBrandUpdated();
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                enabled: isCustom,
                readOnly: !isCustom,
                decoration: InputDecoration(
                  labelText: 'Brand Name',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  helperText: !isCustom
                      ? 'Default brand name cannot be renamed'
                      : null,
                ),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Text(
                'Item Rates for this Brand (Optional):',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              ...items.map((it) {
                final itemName = it['name'].toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          itemName,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        height: 36,
                        child: TextField(
                          controller: itemRateCtrls[itemName],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          enabled: true,
                          readOnly: false,
                          decoration: const InputDecoration(
                            prefixText: '₹',
                            labelText: 'Rate',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 6),
                          ),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryButton,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final newBrandName = nameCtrl.text.trim();
            if (newBrandName.isNotEmpty) {
              final rates = <String, double>{};
              itemRateCtrls.forEach((k, v) {
                final r = double.tryParse(v.text.trim()) ?? 0.0;
                if (r > 0) rates[k] = r;
              });

              if (isCustom && newBrandName != currentBrandName) {
                await BrandService.instance.editBrand(
                  oldName: currentBrandName,
                  newName: newBrandName,
                  isChannel: isChannel,
                );
              }
              BrandService.instance.brandRates[newBrandName] = rates;
              await BrandService.instance.saveBrands();

              onBrandUpdated();
              Navigator.pop(ctx);
            }
          },
          child: const Text('SAVE CHANGES'),
        ),
      ],
    ),
  );
}
