import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/favorites_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/profile_connectivity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:discovaa/app/router/route_names.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Favorites page showing favorited artisans.
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(profileConnectivityProvider);

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
            // Connectivity indicator
            ProfileConnectivityIndicator(
              state: connectivityState,
              onRetry: () => ref
                  .read(profileConnectivityProvider.notifier)
                  .checkConnection(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and options
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Favourites',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'clear_all':
                                  _showClearAllDialog(context, ref);
                                  break;
                                case 'refresh':
                                  ref
                                      .read(
                                        profileConnectivityProvider.notifier,
                                      )
                                      .checkConnection();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'refresh',
                                child: Row(
                                  children: [
                                    Icon(Icons.refresh, size: 20),
                                    SizedBox(width: 12),
                                    Text('Refresh'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'clear_all',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Clear All',
                                      style: TextStyle(
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Search field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SearchField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        hintText: 'Search favorite artisans...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Content
                    Expanded(child: _ArtisansTab(searchQuery: _searchQuery)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text(
          'This will remove all favorite artisans. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(favoriteArtisansProvider.notifier).clearAll();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All favorite artisans removed')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search field widget
// ---------------------------------------------------------------------------
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Artisans Tab
// ---------------------------------------------------------------------------
class _ArtisansTab extends ConsumerWidget {
  final String searchQuery;

  const _ArtisansTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteArtisans = ref.watch(favoritesProvider);

    // Filter by search query
    final filteredArtisans = searchQuery.isEmpty
        ? favoriteArtisans
        : favoriteArtisans
              .where(
                (a) =>
                    a.name.toLowerCase().contains(searchQuery) ||
                    a.category.toLowerCase().contains(searchQuery),
              )
              .toList();

    if (filteredArtisans.isEmpty) {
      return _EmptyState(
        icon: Icons.people_outline,
        title: searchQuery.isEmpty ? 'No favorite artisans' : 'No results',
        subtitle: searchQuery.isEmpty
            ? 'Artisans you interact with will appear here.'
            : 'Try a different search term.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filteredArtisans.length,
      itemBuilder: (context, index) {
        return _FavoriteArtisanTile(artisan: filteredArtisans[index]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Favorite Artisan Tile
// ---------------------------------------------------------------------------
class _FavoriteArtisanTile extends ConsumerWidget {
  final Artisan artisan;

  const _FavoriteArtisanTile({required this.artisan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Select artisan and navigate to profile page
          ref.read(bookingProvider.notifier).selectArtisan(artisan);
          context.push(RouteNames.artisanProfile);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage(artisan.profileImage),
                  onBackgroundImageError: (_, _) => const Icon(Icons.person),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artisan.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artisan.category,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artisan.lastSeen != null
                            ? 'Last seen ${timeago.format(artisan.lastSeen!)}'
                            : 'Recently active',
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    // Rating badge
                    if (artisan.rating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9C4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              artisan.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Stop propagation to parent InkWell
                        final messagingState = ref.read(messagingProvider);
                        final conversation = messagingState.conversations
                            .firstWhere(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                        minimumSize: const Size(80, 32),
                      ),
                      child: const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State Widget
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
