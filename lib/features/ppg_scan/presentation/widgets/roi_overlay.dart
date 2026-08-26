import 'package:flutter/material.dart';

class RoiOverlay extends StatelessWidget {
  const RoiOverlay({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: Container(
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xff63d7b0), width: 2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            '64 x 64 ROI',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );
}
