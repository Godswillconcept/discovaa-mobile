import 'package:flutter/material.dart';

class PrivacyTab extends StatelessWidget {
  const PrivacyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Information collection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'We collect info that you provide to us, info from your use of our Services, and info from other sources. Here are some examples of what this means:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          _buildPrivacyItem(
            'Personal info you give us',
            'Like your name, email, phone number, and password, to set up your account.',
          ),
          _buildPrivacyItem(
            'Profile info',
            'Things you might add like your profile photo, gender, or pronouns.',
          ),
          _buildPrivacyItem(
            'In-app messages and reviews',
            'When you message other users or write a review, we process this to deliver the service.',
          ),
          _buildPrivacyItem(
            'Device and usage info',
            'We collect info about how you use Discovaa and the devices you use to access it.',
          ),

          const SizedBox(height: 32),

          const Text(
            'How we use your info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'We use your info to provide, improve, and protect our Services. This includes things like:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          _buildPrivacyItem(
            'Providing the service',
            'To connect you with artisans or clients, process payments, and provide customer support.',
          ),
          _buildPrivacyItem(
            'Safety and security',
            'To verify accounts, detect spam or fraud, and keep the platform safe for everyone.',
          ),
          _buildPrivacyItem(
            'Improving Discovaa',
            'To understand how people use our app so we can make it better.',
          ),

          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Read full Privacy Policy',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
