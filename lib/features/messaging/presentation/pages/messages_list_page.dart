import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:discovaa/features/messaging/presentation/widgets/conversation_tile.dart';
import 'package:discovaa/features/messaging/presentation/widgets/messaging_search_bar.dart';

class MessagesListPage extends ConsumerWidget {
  const MessagesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagingState = ref.watch(messagingProvider);
    final filteredConversations = messagingState.filteredConversations;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const MainHeader(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 24.w, 20.w, 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Messages',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'mark_all_read') {
                              ref
                                  .read(messagingProvider.notifier)
                                  .markAllAsRead();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'mark_all_read',
                              child: Text('Mark all as read'),
                            ),
                          ],
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.more_horiz,
                              color: Colors.grey,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const MessagingSearchBar(),
                  if (messagingState.isStale) ...[
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18.sp,
                              color: Colors.orange.shade700,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Showing cached messages. Service may be temporarily unavailable.',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ] else
                    SizedBox(height: 16.h),
                  Expanded(
                    child: messagingState.isLoading
                        ? const _MessagesListSkeleton()
                        : messagingState.error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  size: 48.sp,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  messagingState.error!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton(
                                  onPressed: () => ref
                                      .read(messagingProvider.notifier)
                                      .refresh(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : filteredConversations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64.sp,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No messages found',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(messagingProvider.notifier).refresh(),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: filteredConversations.length,
                              separatorBuilder: (context, index) => Padding(
                                padding: EdgeInsets.only(left: 90.w),
                                child: Divider(
                                  height: 1.h,
                                  thickness: 0.5,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              itemBuilder: (context, index) {
                                return ConversationTile(
                                  conversation: filteredConversations[index],
                                );
                              },
                            ),
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

class _MessagesListSkeleton extends StatelessWidget {
  const _MessagesListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: 6,
      separatorBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(left: 90.w),
        child: Divider(
          height: 1.h,
          thickness: 0.5,
          color: Colors.grey.shade200,
        ),
      ),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
