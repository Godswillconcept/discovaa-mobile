import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/authentication/presentation/providers/identity_verification_reminder_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Widget that displays a reminder banner for pending identity verification
/// Shows when user has skipped or not completed identity verification
class IdentityVerificationReminderWidget extends ConsumerWidget {
  const IdentityVerificationReminderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showReminder = ref.watch(showIdentityVerificationReminderProvider);

    // Don't show if already verified or permanently skipped
    if (!showReminder) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Colors.orange.shade700,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Complete Your Identity Verification',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
              // Dismiss button
              IconButton(
                onPressed: () {
                  ref
                      .read(identityVerificationReminderProvider.notifier)
                      .dismissReminder();
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.orange.shade700,
                  size: 20.sp,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Verify your identity to unlock all features and build trust with customers. This helps ensure a safe and secure marketplace.',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.orange.shade800,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Permanently dismiss - user doesn't want to see this again
                    ref
                        .read(identityVerificationReminderProvider.notifier)
                        .permanentlyDismiss();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    side: BorderSide(color: Colors.orange.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'I\'ll do this later',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to identification page
                    context.push(RouteNames.identification);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Verify Now',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
