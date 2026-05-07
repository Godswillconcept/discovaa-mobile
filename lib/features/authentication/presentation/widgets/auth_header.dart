import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/clippers.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? step;
  final VoidCallback? onBack;
  final double height;

  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.step,
    this.onBack,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return HeaderClipper(
      child: Container(
        height: height.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onBack != null)
                  TextButton.icon(
                    onPressed: onBack,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    label: Text("Back", style: TextStyle(color: Colors.white)),
                  )
                else
                  const SizedBox.shrink(),
                if (step != null)
                  Text(
                    "Step $step",
                    style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                    ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
