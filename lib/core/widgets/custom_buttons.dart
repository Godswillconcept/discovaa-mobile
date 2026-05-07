import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: Size(double.maxFinite, 55.h),
        backgroundColor: isLoading ? Colors.grey : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: 20.h,
              width: 20.w,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child,
    );
  }
}

class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        fixedSize: Size(double.maxFinite, 55.h),
        side: BorderSide(color: isLoading ? Colors.grey : Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: 20.h,
              width: 20.w,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child,
    );
  }
}

class AppOutlinedButtonWithIcon extends StatelessWidget {
  const AppOutlinedButtonWithIcon({
    super.key,
    required this.onPressed,
    required this.child,
    required this.icon,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 30.sp),
      label: isLoading ? SizedBox.shrink() : child,
      style: OutlinedButton.styleFrom(
        fixedSize: Size(double.maxFinite, 55.h),
        side: BorderSide(color: isLoading ? Colors.grey : Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
    );
  }
}
