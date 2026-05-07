import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MessagingSearchBar extends ConsumerWidget {
  const MessagingSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TextField(
          onChanged: (value) {
            ref.read(messagingProvider.notifier).setSearchQuery(value);
          },
          decoration: InputDecoration(
            hintText: 'Search conversations',
            hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 16.sp),
            prefixIcon: Icon(
              Icons.search,
              color: Color(0xFF999999),
              size: 24.sp,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }
}
