import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/notifications/presentation/widgets/notification_bottom_sheet.dart';
import 'package:discovaa/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:discovaa/features/profile/presentation/providers/saved_services_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_names.dart';

class MainHeader extends ConsumerWidget {
  const MainHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        20,
        30,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A), // Lighter black
            Color(0xFF0F0F0F), // Darker black
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/images/logos/logo.png',
                height: 35,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'DISCOVAA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          // Right-side actions
          Row(
            children: [
              // Favorites icon with badge
              Consumer(
                builder: (context, ref, child) {
                  final savedCount = ref.watch(savedServicesCountProvider);
                  final hasSavedItems = savedCount > 0;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_outline,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () {
                          final currentLocation = GoRouterState.of(
                            context,
                          ).matchedLocation;
                          // Prevent navigation if already on favorites page
                          if (currentLocation != RouteNames.favorites) {
                            context.push(RouteNames.favorites);
                          }
                        },
                      ),
                      if (hasSavedItems)
                        Positioned(
                          top: -2,
                          right: 2,
                          child: Container(
                            height: 18,
                            width: savedCount > 99 ? 28 : 18,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE91E63,
                              ), // Pink/red for favorites
                              shape: savedCount > 99
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: savedCount > 99
                                  ? BorderRadius.circular(9)
                                  : null,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                savedCount > 99 ? '99+' : savedCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: savedCount > 99 ? 9 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              NotificationBadge(
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    NotificationBottomSheet.show(context);
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final currentLocation = GoRouterState.of(
                    context,
                  ).matchedLocation;
                  // Prevent navigation if already on user profile
                  if (currentLocation != RouteNames.userProfile) {
                    context.push(RouteNames.userProfile);
                  }
                },
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  backgroundImage: AssetImage(
                    'assets/images/placeholders/user_avatar.png',
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
