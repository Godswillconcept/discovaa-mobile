import 'package:flutter/material.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_field_label.dart';
import '../../../../core/widgets/custom_buttons.dart';

class ContactForm extends StatefulWidget {
  const ContactForm({super.key});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubject;
  final List<String> _subjects = [
    "General Inquiry",
    "Support",
    "Feedback",
    "Partnership",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AuthFieldLabel(label: "First Name"),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: "First Name",
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AuthFieldLabel(label: "Last Name"),
                      TextFormField(
                        decoration: const InputDecoration(
                          hintText: "Doe",
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const AuthFieldLabel(label: "Email"),
            TextFormField(
              decoration: const InputDecoration(
                hintText: "example@gmail.com",
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const AuthFieldLabel(label: "Phone Number"),
            TextFormField(
              decoration: const InputDecoration(
                hintText: "+1 012 3456 789",
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Select Subject?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ..._subjects.map((subject) => _buildSubjectOption(subject)),
            const SizedBox(height: 24),
            const AuthFieldLabel(label: "Message"),
            TextFormField(
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: "Write your message...",
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 180,
                child: AppPrimaryButton(
                  onPressed: () {},
                  child: const Text("Send"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectOption(String subject) {
    final bool isSelected = _selectedSubject == subject;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubject = subject;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: isSelected ? Colors.black : Colors.grey.shade300,
            ),
            const SizedBox(width: 8),
            Text(
              subject,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
