import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Messages',
                          style: TextStyle(
                            fontSize: 28,
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.more_horiz,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const MessagingSearchBar(),
                  if (messagingState.isStale) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Showing cached messages. Service may be temporarily unavailable.',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else
                    const SizedBox(height: 16),
                  Expanded(
                    child: messagingState.isLoading
                        ? const _MessagesListSkeleton()
                        : messagingState.error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wifi_off_rounded,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  messagingState.error!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages found',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: filteredConversations.length,
                            separatorBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(left: 90),
                              child: Divider(
                                height: 1,
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
        padding: const EdgeInsets.only(left: 90),
        child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
      ),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
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
