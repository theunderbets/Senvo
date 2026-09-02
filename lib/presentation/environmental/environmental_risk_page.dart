import 'package:flutter/material.dart';

class EnvironmentalRiskPage extends StatelessWidget {
  const EnvironmentalRiskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment'),
      ),
      body: const Center(
        child: Text('Environmental Risk Content Here'),
      ),
    );
  }
}
