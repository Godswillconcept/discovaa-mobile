import 'package:flutter/material.dart';

class PaginationButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;

  const PaginationButton({super.key, this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: onTap != null ? Colors.grey.shade300 : Colors.grey.shade100,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? Colors.black : Colors.grey.shade300,
        ),
      ),
    );
  }
}
