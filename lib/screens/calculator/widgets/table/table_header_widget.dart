import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class TableHeaderWidget extends StatelessWidget {
  const TableHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.border,
      ),
      child: const Row(
        children: [
          SizedBox(width: 25, child: Text('SL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))),
          Expanded(flex: 24, child: Text('Item Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 8, child: Text('L', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 8, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 6, child: Text('Q', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 15, child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 18, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 44),
        ],
      ),
    );
  }
}
