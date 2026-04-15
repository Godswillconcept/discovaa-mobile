import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactInfoCard extends StatelessWidget {
  const ContactInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark card
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contact Information",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Say something to start a live chat!",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildInfoRow(Icons.phone_in_talk, "+1012 3456 789"),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.email, "discovaa@gmail.com"),
          const SizedBox(height: 48),
          const Text(
            "Join Our Newsletter",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildNewsletterSection(),
          const SizedBox(height: 12),
          const Text(
            "* Will send you weekly updates for your better tool management.",
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 48),
          _buildSocialIcons(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildNewsletterSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: const Center(
              child: TextField(
                style: TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Your email address",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: const Center(
            child: Text(
              "Subscribe",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FaIcon(FontAwesomeIcons.twitter, color: Colors.white, size: 20),
        const SizedBox(width: 24),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const FaIcon(
            FontAwesomeIcons.instagram,
            color: Colors.black,
            size: 20,
          ),
        ),
        const SizedBox(width: 24),
        const FaIcon(FontAwesomeIcons.discord, color: Colors.white, size: 20),
      ],
    );
  }
}
