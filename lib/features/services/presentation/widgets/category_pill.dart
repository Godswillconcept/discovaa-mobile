import 'package:discovaa/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class CategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  
  const CategoryPill({
    super.key,
    required this.label, 
    this.isSelected = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}
