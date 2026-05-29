import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// =========================================================
// Widget kapsul filter kategori atau genre film
// =========================================================
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isOutline;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: isOutline ? Border.all(color: isSelected ? AppColors.primary : AppColors.border) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isOutline && !isSelected ? '# $label' : label, 
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}