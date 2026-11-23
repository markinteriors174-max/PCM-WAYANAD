import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/labor_service.dart';
import '../../../../models/labor_models.dart';

class ProjectHubWorkerRating extends StatelessWidget {
  final String assignedWorkers;
  final VoidCallback onRatingSubmitted;

  const ProjectHubWorkerRating({
    super.key,
    required this.assignedWorkers,
    required this.onRatingSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final workers = assignedWorkers.split(',').map((w) => w.trim()).where((w) => w.isNotEmpty).toList();
    if (workers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RATE YOUR SERVICE TEAM', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 10),
          ...workers.map((workerName) => FutureBuilder<List<Worker>>(
            future: LaborService.instance.getWorkers().first,
            builder: (context, snapshot) {
              final worker = snapshot.data?.firstWhere((w) => w.name.toLowerCase() == workerName.toLowerCase(), orElse: () => Worker(id: '', name: workerName, place: '', phoneNumber: ''));
              if (worker == null || worker.id == '') return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(workerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isSelected = worker.rating >= starValue;
                        return GestureDetector(
                          onTap: () async {
                            final newRating = starValue.toDouble();
                            await LaborService.instance.updateWorkerRating(worker.id, newRating);
                            onRatingSubmitted();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Thank you! ₹${starValue * 10} bonus added to $workerName\'s account.'),
                                backgroundColor: AppColors.resultGreen,
                              ));
                            }
                          },
                          child: Icon(
                            isSelected ? Icons.star : Icons.star_border,
                            color: isSelected ? Colors.orange : Colors.grey,
                            size: 24,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          )),
        ],
      ),
    );
  }
}
