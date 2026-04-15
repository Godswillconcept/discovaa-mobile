import 'package:flutter/material.dart';

class EmptyStateCard extends StatelessWidget {
  final String text;
  final double height;

  const EmptyStateCard({
    super.key,
    required this.text,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
      ),
    );
  }
}
