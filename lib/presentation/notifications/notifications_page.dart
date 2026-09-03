import 'package:flutter/material.dart';
import '../../core/theme/senvo_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(SenvoSpacing.md),
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.all(SenvoSpacing.xl),
              child: Text(
                'No new notifications.',
                style: TextStyle(color: context.themeColors.muted),
              ),
            ),
          )
        ],
      ),
    );
  }
}
