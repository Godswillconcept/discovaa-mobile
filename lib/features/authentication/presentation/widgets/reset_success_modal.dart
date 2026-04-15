import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';

class ResetSuccessModal extends StatefulWidget {
  const ResetSuccessModal({super.key});

  @override
  State<ResetSuccessModal> createState() => _ResetSuccessModalState();
}

class _ResetSuccessModalState extends State<ResetSuccessModal> {
  @override
  void initState() {
    super.initState();
    // Auto-redirect to login after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close modal
        context.go(RouteNames.login); // Navigate to login
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blue Icon Container (Image 4)
            Container(
              height: 100,
              width: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF4C84FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Reset Password Successful !",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Please wait...\nYou will be directed to the homepage soon.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
