import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

class QuickAddHeader extends StatelessWidget {
  final CalculatorController ctrl;
  final String currentRoomName;
  final String currentDesignName;
  final VoidCallback onEditDetails;

  const QuickAddHeader({
    super.key,
    required this.ctrl,
    required this.currentRoomName,
    required this.currentDesignName,
    required this.onEditDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  ctrl.activeProjectId != null ? 'EDIT ENTRY' : 'QUICK ADD: $currentDesignName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.border,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: AppColors.border),
                onPressed: onEditDetails,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
