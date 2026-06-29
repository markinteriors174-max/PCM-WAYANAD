import 'package:flutter/material.dart';

class PcmMaterialList extends StatelessWidget {
  final double calculatedArea;
  final int qtyCross;
  final int qtyMain;
  final int qtyPeri;
  final int dlCount;
  final double profileRft;

  const PcmMaterialList({
    super.key,
    required this.calculatedArea,
    required this.qtyCross,
    required this.qtyMain,
    required this.qtyPeri,
    required this.dlCount,
    required this.profileRft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xEE0C0E14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFFD4AF37), size: 14),
              const SizedBox(width: 6),
              const Text(
                'REAL-TIME MATERIALS ESTIMATE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF87).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AUTO-CALC',
                  style: TextStyle(color: Color(0xFF00FF87), fontSize: 7, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 8),
          _buildItemRow('Ceiling Gypsum Sheets', '${calculatedArea.toStringAsFixed(1)} SqFt'),
          _buildItemRow('Cross Channel (12 ft)', '$qtyCross Pcs'),
          _buildItemRow('Main Channel (12 ft)', '$qtyMain Pcs'),
          _buildItemRow('Wall Perimeter (12 ft)', '$qtyPeri Pcs'),
          if (dlCount > 0)
            _buildItemRow('LED Downlights (Spots)', '$dlCount Pcs'),
          if (profileRft > 0) ...[
            _buildItemRow('Aluminum Profile Channel', '${profileRft.toStringAsFixed(1)} Rft'),
            _buildItemRow('LED Strip & Diffuser', '${profileRft.toStringAsFixed(1)} Rft'),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 8),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
