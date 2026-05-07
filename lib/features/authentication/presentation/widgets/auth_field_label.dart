import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      padding: EdgeInsets.only(bottom: 8.h),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
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
