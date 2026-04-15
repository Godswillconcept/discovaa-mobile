import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (action != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                action!,
                style: const TextStyle(color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}
