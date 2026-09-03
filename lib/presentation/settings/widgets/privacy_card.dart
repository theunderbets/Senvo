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
          backgroundColor: context.themeColors.surface,
          title: Text('Clear All Health Data?', style: TextStyle(color: context.themeColors.riskEmergency)),
          content: Text(
            'This action is irreversible. All locally stored health vitals, history, and baseline data will be permanently deleted.',
            style: TextStyle(color: context.themeColors.text),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: context.themeColors.muted)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.themeColors.riskEmergency,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Data'),
              onPressed: () {
                Navigator.of(context).pop();
                onClearData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All local health data cleared.'),
                    backgroundColor: context.themeColors.riskEmergency,
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
                Icon(Icons.security, color: context.themeColors.accent),
                const SizedBox(width: SenvoSpacing.md),
                Text(
                  'Privacy & Security',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: SenvoSpacing.md),
            Text(
              'Your health data is encrypted and stored locally on this device. Senvo does not upload your vitals to any cloud servers without explicit permission.',
              style: TextStyle(color: context.themeColors.muted),
            ),
            const SizedBox(height: SenvoSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.delete_forever, color: context.themeColors.riskEmergency),
                label: Text(
                  'Clear All Local Data',
                  style: TextStyle(color: context.themeColors.riskEmergency),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.themeColors.riskEmergency),
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
