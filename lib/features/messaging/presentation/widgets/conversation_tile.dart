import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ConversationTile extends ConsumerWidget {
  final Conversation conversation;

  const ConversationTile({super.key, required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.read(messagingProvider.notifier).markAsRead(conversation.id);
        context.push('${RouteNames.messages}/chat', extra: conversation);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.w, 20.w, 16.w),
        child: Row(
          children: [
            SizedBox(
              width: 12.w,
              child: conversation.unreadCount > 0
                  ? Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF007AFF),
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 28.r,
              backgroundImage: AssetImage(conversation.artisanAvatar),
              backgroundColor: Colors.grey.shade200,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.artisanName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Row(
                        children: [
                          Text(
                            DateFormat(
                              'h:mm a',
                            ).format(conversation.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Color(0xFF999999),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14.sp,
                            color: Color(0xFFD1D1D6),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    conversation.lastMessage,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Color(0xFF8E8E93),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
