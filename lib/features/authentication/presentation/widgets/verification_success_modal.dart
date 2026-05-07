import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VerificationSuccessModal extends StatelessWidget {
  const VerificationSuccessModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon with decorative dots (simplified version of Image 1)
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 100.h,
                  width: 100.w,
                  decoration: BoxDecoration(
                    color: Color(0xFF4C84FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 60.sp),
                ),
                // Decorative dots around the icon
                ...List.generate(
                  8,
                  (index) => Positioned(
                    child: Transform.rotate(
                      angle: index * 0.8,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 130.h),
                        child: CircleAvatar(
                          radius: 3.r,
                          backgroundColor: Color(0xFF4C84FF),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h),
            Text(
              "Account Verification Successful !",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text(
              "Proceed to complete your profile!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16.sp),
            ),
            SizedBox(height: 40.h),
            // Loading Indicator
            SizedBox(
              height: 60.h,
              width: 60.w,
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
