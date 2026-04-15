import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/favorites_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/saved_services_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/profile_connectivity_provider.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/services/presentation/pages/service_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:discovaa/app/router/route_names.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Favorites page with tabs for Favorite Artisans and Saved Services
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                        hintText: _tabController.index == 0
                            ? 'Search favorite artisans...'
                            : 'Search saved services...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tab bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorPadding: const EdgeInsets.all(4),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey.shade600,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          dividerColor: Colors.transparent,
                          tabs: [
                            _buildTab('Artisans', Icons.people_outline),
                            _buildTab(
                              'Services',
                              Icons.home_repair_service_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _ArtisansTab(searchQuery: _searchQuery),
                          _SavedServicesTab(searchQuery: _searchQuery),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, IconData icon) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text(
          'This will remove all saved artisans and services. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(savedServicesProvider.notifier).clear();
              // Note: Favorite artisans are derived from artisansProvider,
              // so we can't directly clear them. They are based on lastSeen.
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All saved services cleared')),
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
    final favoriteArtisansAsync = ref.watch(favoritesProvider);

    return favoriteArtisansAsync.when(
      data: (artisans) {
        // Filter by search query
        final filteredArtisans = searchQuery.isEmpty
            ? artisans
            : artisans
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
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Error loading favorites',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(favoritesProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved Services Tab
// ---------------------------------------------------------------------------
class _SavedServicesTab extends ConsumerWidget {
  final String searchQuery;

  const _SavedServicesTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedServicesState = ref.watch(savedServicesProvider);
    final savedServices = savedServicesState.savedServices;

    // Filter by search query
    final filteredServices = searchQuery.isEmpty
        ? savedServices
        : savedServices
              .where(
                (s) =>
                    s.title.toLowerCase().contains(searchQuery) ||
                    (s.category?.toLowerCase().contains(searchQuery) ?? false),
              )
              .toList();

    if (filteredServices.isEmpty) {
      return _EmptyState(
        icon: Icons.home_repair_service_outlined,
        title: searchQuery.isEmpty ? 'No saved services' : 'No results',
        subtitle: searchQuery.isEmpty
            ? 'Tap the heart icon on any service to save it here.'
            : 'Try a different search term.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filteredServices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _SavedServiceTile(service: filteredServices[index]);
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
    );
  }
}

// ---------------------------------------------------------------------------
// Saved Service Tile
// ---------------------------------------------------------------------------
class _SavedServiceTile extends ConsumerWidget {
  final ServiceModel service;

  const _SavedServiceTile({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ServiceDetailPage(service: service)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Service cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: service.imagePath != null
                    ? _buildServiceImage(service.imagePath!)
                    : _ThumbFallback(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (service.category != null &&
                        service.category!.isNotEmpty)
                      Text(
                        service.category!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.formattedPrice,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              // Un-save button
              GestureDetector(
                onTap: () {
                  ref.read(savedServicesProvider.notifier).toggle(service);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${service.title} removed from saved services',
                      ),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          ref.read(savedServicesProvider.notifier).add(service);
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds service image widget, handling both network URLs and local assets
  Widget _buildServiceImage(String imagePath) {
    final isNetworkUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    if (isNetworkUrl) {
      return Image.network(
        imagePath,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _ThumbFallback(),
      );
    }
    return Image.asset(
      imagePath,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => _ThumbFallback(),
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

// ---------------------------------------------------------------------------
// Thumb Fallback Widget
// ---------------------------------------------------------------------------
class _ThumbFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFF0F0F0),
      child: const Icon(
        Icons.home_repair_service_rounded,
        size: 24,
        color: Colors.black26,
      ),
    );
  }
}
