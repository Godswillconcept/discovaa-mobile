import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ChatHeader extends ConsumerWidget {
  final Conversation conversation;

  const ChatHeader({super.key, required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 50.w, 20.w, 20.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50.r),
          bottomRight: Radius.circular(50.r),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      Text(
                        'Back',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.asset(
                    conversation.artisanAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        'LOGO',
                        style: TextStyle(color: Colors.white, fontSize: 10.sp),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () {
              final artisansAsync = ref.read(artisansProvider);
              final artisans = artisansAsync.value ?? [];
              if (artisans.isEmpty) return; // Or handle error

              final artisan = artisans.firstWhere(
                (a) => a.id == conversation.artisanId,
                orElse: () => artisans.first,
              );
              context.push('${RouteNames.artisanProfile}/${artisan.id}');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  conversation.artisanName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white, size: 20.sp),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          if (conversation.yearsInBusiness > 0 || conversation.hiresCount > 0)
            Text(
              '${conversation.yearsInBusiness} years in business • ${conversation.hiresCount} hires on Discovaa',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12.sp,
              ),
            ),
        ],
      ),
    );
  }
}
