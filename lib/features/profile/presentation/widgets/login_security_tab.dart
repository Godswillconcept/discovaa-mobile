import 'package:discovaa/features/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/app/router/route_names.dart';
import 'package:go_router/go_router.dart';

class LoginSecurityTab extends ConsumerWidget {
  final UserProfile profile;
  const LoginSecurityTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image (Centered like in design)
          Center(
            child: Stack(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/placeholders/user_avatar.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Email Section
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'Request email change',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 0.5),
          ),

          // Phone Section
          const Text(
            'Phone number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We will send you a text message to verify your phone number.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('🇪🇪', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text(
                      '+372',
                      style: TextStyle(fontSize: 16, color: Color(0xFFB0B0B0)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      profile.phone?.isNotEmpty == true
                          ? profile.phone!.replaceAll('+372', '').trim()
                          : '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 0.5),
          ),

          // Password Section
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Last changed 2 months ago',
                  style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 0.5),
          ),

          // Log out from all devices
          const Text(
            'Active devices',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Log out from all devices',
                  style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to sign in page (simple logout mock)
                    context.go(RouteNames.login);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 0.5),
          ),

          // Deactivate Account
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Deactivate your account',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
