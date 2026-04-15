import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable profile field row widget for displaying and editing profile information
class ProfileFieldRow extends StatelessWidget {
  final String label;
  final String value;
  final String? placeholder;
  final VoidCallback? onEdit;
  final bool isEditable;
  final bool showDivider;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;
  final Widget? leading;
  final int? maxLines;
  final int? maxLength;
  final String? helperText;

  const ProfileFieldRow({
    super.key,
    required this.label,
    required this.value,
    this.placeholder,
    this.onEdit,
    this.isEditable = true,
    this.showDivider = true,
    this.keyboardType,
    this.inputFormatters,
    this.trailing,
    this.leading,
    this.maxLines = 1,
    this.maxLength,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty ? (placeholder ?? 'Not set') : value;
    final isPlaceholder = value.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isPlaceholder
                            ? FontWeight.w400
                            : FontWeight.w500,
                        color: isPlaceholder
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF111827),
                      ),
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (helperText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        helperText!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ] else if (isEditable && onEdit != null) ...[
                const SizedBox(width: 12),
                _EditButton(onPressed: onEdit!),
              ],
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
      ],
    );
  }
}

/// Edit button styled for profile fields
class _EditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 36),
        foregroundColor: const Color(0xFF111827),
      ),
      child: const Text(
        'Edit',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Section card widget for grouping profile fields
class ProfileSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? action;
  final EdgeInsets padding;

  const ProfileSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.action,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                action != null ? action! : const SizedBox.shrink(),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
