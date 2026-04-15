import 'package:flutter/material.dart';

class VerificationSuccessModal extends StatelessWidget {
  const VerificationSuccessModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon with decorative dots (simplified version of Image 1)
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4C84FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 60),
                ),
                // Decorative dots around the icon
                ...List.generate(
                  8,
                  (index) => Positioned(
                    child: Transform.rotate(
                      angle: index * 0.8,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 130),
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFF4C84FF),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Account Verification Successful !",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Proceed to complete your profile!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            // Loading Indicator
            const SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF444444)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
