import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:discovaa/features/profile/domain/repositories/artisan_detail_repository.dart'
    show ArtisanService;
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/features/profile/presentation/widgets/booking_flow_widgets.dart';
import 'package:discovaa/app/router/route_names.dart';

class ArtisanProfileHeader extends ConsumerWidget {
  final Artisan artisan;
  final List<ArtisanService> services;

  const ArtisanProfileHeader({
    super.key,
    required this.artisan,
    this.services = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    artisan.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (artisan.isVerified)
                    const Icon(
                      Icons.verified_user,
                      color: Colors.amber,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  RatingBarIndicator(
                    rating: artisan.rating,
                    itemBuilder: (context, index) =>
                        const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 18.0,
                    unratedColor: Colors.amber.withValues(alpha: 0.2),
                    direction: Axis.horizontal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${artisan.rating} (${artisan.reviewsCount} Reviews)',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${artisan.location} • ${artisan.registrationNumber ?? artisan.id}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              if (artisan.address != null && artisan.address!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    artisan.address!,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        Column(
          children: [
            ElevatedButton(
              onPressed: () => _showBookingModal(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text('Book Now'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                final messagingState = ref.read(messagingProvider);
                final conversation = messagingState.conversations.firstWhere(
                  (c) => c.artisanId == artisan.id,
                  orElse: () => Conversation(
                    id: 'temp_${artisan.id}',
                    artisanId: artisan.id,
                    artisanName: artisan.name,
                    artisanAvatar: artisan.profileImage,
                    lastMessage: '',
                    lastMessageTime: DateTime.now(),
                    yearsInBusiness: artisan.yearsInBusiness,
                    hiresCount: artisan.hiresCount,
                  ),
                );
                context.push(
                  '${RouteNames.messages}/chat',
                  extra: conversation,
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text(
                'Message',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBookingModal(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bookingProvider.notifier);
    notifier.reset();
    notifier.selectArtisan(artisan);

    // Convert ArtisanService to BookingService and set in state
    final bookingServices = services
        .map(
          (s) => BookingService(
            id: s.id,
            title: s.title,
            hourlyRate: s.hourlyRate,
            priceRange: s.priceRange,
          ),
        )
        .toList();
    notifier.setAvailableServices(bookingServices);

    showDialog(
      context: context,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        child: BookingFlowModal(),
      ),
    );
  }
}
