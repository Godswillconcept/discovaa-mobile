import 'package:flutter/material.dart';
import '../../../../core/utils/clippers.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? step;
  final VoidCallback? onBack;
  final double height;

  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.step,
    this.onBack,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return HeaderClipper(
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onBack != null)
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: const Text(
                      "Back",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (step != null)
                  Text(
                    "Step $step",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
