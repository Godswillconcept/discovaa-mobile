import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessagingSearchBar extends ConsumerWidget {
  const MessagingSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          onChanged: (value) {
            ref.read(messagingProvider.notifier).setSearchQuery(value);
          },
          decoration: const InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 16),
            prefixIcon: Icon(Icons.search, color: Color(0xFF999999), size: 24),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
