import 'package:flutter/material.dart';

class HealthAdvisoryCard extends StatelessWidget {
  const HealthAdvisoryCard({
    required this.advisoryText,
    super.key,
  });

  final String advisoryText;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lightbulb,
              color: Colors.blueAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                advisoryText,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
