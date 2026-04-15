import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              child: conversation.unreadCount > 0
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF007AFF),
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 28,
              backgroundImage: AssetImage(conversation.artisanAvatar),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation.artisanName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormat(
                              'h:mm a',
                            ).format(conversation.lastMessageTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Color(0xFFD1D1D6),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    style: const TextStyle(
                      fontSize: 14,
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
