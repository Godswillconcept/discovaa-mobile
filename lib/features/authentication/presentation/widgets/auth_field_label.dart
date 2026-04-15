import 'package:flutter/material.dart';

class AuthFieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const AuthFieldLabel({
    super.key,
    required this.label,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: "*",
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
