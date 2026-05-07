import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
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
                SizedBox(width: 16.w),
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
            SizedBox(height: 20.h),
            const AuthFieldLabel(label: "Email"),
            TextFormField(
              decoration: const InputDecoration(
                hintText: "example@gmail.com",
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.h),
            const AuthFieldLabel(label: "Phone Number"),
            TextFormField(
              decoration: const InputDecoration(
                hintText: "+1 012 3456 789",
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              "Select Subject?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            ..._subjects.map((subject) => _buildSubjectOption(subject)),
            SizedBox(height: 24.h),
            const AuthFieldLabel(label: "Message"),
            TextFormField(
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: "Write your message...",
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 40.h),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 180.w,
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
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20.sp,
              color: isSelected ? Colors.black : Colors.grey.shade300,
            ),
            SizedBox(width: 8.w),
            Text(subject, style: TextStyle(fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }
}
