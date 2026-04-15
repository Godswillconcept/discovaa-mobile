import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/widgets/custom_buttons.dart';

class SocialAuthSection extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final String label;

  const SocialAuthSection({
    super.key,
    required this.onGooglePressed,
    this.label = "Register with Google",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Or",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ),
        AppOutlinedButton(
          onPressed: onGooglePressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/logos/google.svg',
                semanticsLabel: 'Google Logo',
                height: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
