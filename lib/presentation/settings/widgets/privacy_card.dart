import 'package:flutter/material.dart';
import '../../../../core/theme/senvo_theme.dart';

class PrivacyCard extends StatelessWidget {
  final VoidCallback onClearData;

  const PrivacyCard({
    super.key,
    required this.onClearData,
  });

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: SenvoColors.surface,
          title: const Text('Clear All Health Data?', style: TextStyle(color: SenvoColors.riskEmergency)),
          content: const Text(
            'This action is irreversible. All locally stored health vitals, history, and baseline data will be permanently deleted.',
            style: TextStyle(color: SenvoColors.text),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: SenvoColors.muted)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SenvoColors.riskEmergency,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Data'),
              onPressed: () {
                Navigator.of(context).pop();
                onClearData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All local health data cleared.'),
                    backgroundColor: SenvoColors.riskEmergency,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg, vertical: SenvoSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(SenvoSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: SenvoColors.accent),
                const SizedBox(width: SenvoSpacing.md),
                Text(
                  'Privacy & Security',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: SenvoSpacing.md),
            const Text(
              'Your health data is encrypted and stored locally on this device. Senvo does not upload your vitals to any cloud servers without explicit permission.',
              style: TextStyle(color: SenvoColors.muted),
            ),
            const SizedBox(height: SenvoSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever, color: SenvoColors.riskEmergency),
                label: const Text(
                  'Clear All Local Data',
                  style: TextStyle(color: SenvoColors.riskEmergency),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: SenvoColors.riskEmergency),
                  padding: const EdgeInsets.symmetric(vertical: SenvoSpacing.md),
                ),
                onPressed: () => _showClearDataDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
