import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blue Icon Container (Image 4)
            Container(
              height: 100.h,
              width: 100.w,
              decoration: BoxDecoration(
                color: Color(0xFF4C84FF),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline, color: Colors.white, size: 50.sp),
            ),
            SizedBox(height: 24.h),
            Text(
              "Reset Password Successful !",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text(
              "Please wait...\nYou will be directed to the homepage soon.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            SizedBox(height: 30.h),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
