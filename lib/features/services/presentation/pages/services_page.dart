import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/saved_services_provider.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/services/presentation/providers/services_provider.dart';
import 'package:discovaa/features/services/presentation/widgets/add_service_sheet.dart';
import 'package:discovaa/features/services/presentation/widgets/service_card.dart';
import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  void _openAddSheet(BuildContext context) {
    final profile = ref.read(userProfileProvider).profile;
    final canCreate = profile?.isProvider == true;
    if (!canCreate) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Not allowed'),
          content: const Text(
            'You need a provider account to create services.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: AddServiceSheet(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Trigger API fetch on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(servicesProvider.notifier).loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final isProvider = profileState.profile?.isProvider ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFF),
        body: Column(
          children: [
            const MainHeader(),
            Expanded(
              child: profileState.isLoading
                  ? const _ServicesPageSkeleton()
                  : isProvider
                  ? _ProviderServicesView(
                      onAddTap: () => _openAddSheet(context),
                    )
                  : const _UserServicesView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesPageSkeleton extends StatelessWidget {
  const _ServicesPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonBar(width: 140, height: 28),
          SizedBox(height: 8),
          _SkeletonBar(width: 220, height: 14),
          SizedBox(height: 16),
          _SkeletonBox(height: 48),
          SizedBox(height: 16),
          Expanded(child: _ServicesGridSkeleton()),
        ],
      ),
    );
  }
}

class _ServicesGridSkeleton extends StatelessWidget {
  const _ServicesGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, index) {
        return const _SkeletonBox(height: double.infinity, radius: 16);
      },
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double radius;

  const _SkeletonBox({required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider view
// ---------------------------------------------------------------------------

class _ProviderServicesView extends ConsumerWidget {
  final VoidCallback onAddTap;
  const _ProviderServicesView({required this.onAddTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesState = ref.watch(servicesProvider);
    final filtered = ref.watch(filteredServicesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Services',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create, price, and showcase your services.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Top Add service button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAddTap,
                  icon: const Icon(Icons.add, size: 20, color: Colors.white),
                  label: const Text(
                    'Add service',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Body: empty state or list
        Expanded(
          child: servicesState.status == ServicesStatus.loading
              ? const _ServicesGridSkeleton()
              : filtered.isEmpty
              ? _ProviderEmptyState(onAddTap: onAddTap)
              : _ProviderServiceList(
                  services: filtered,
                  searchQuery: servicesState.searchQuery,
                ),
        ),
      ],
    );
  }
}

class _ProviderEmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  const _ProviderEmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No services yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first service so customers can book you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                'Add service',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderServiceList extends ConsumerWidget {
  final List<ServiceModel> services;
  final String searchQuery;

  const _ProviderServiceList({
    required this.services,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ServiceSearchField(
            hint: 'Search your services...',
            onChanged: ref.read(servicesProvider.notifier).updateSearch,
            initialValue: searchQuery,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.74,
            ),
            itemBuilder: (context, index) {
              final svc = services[index];
              return ServiceCard(
                service: svc,
                isProvider: true,
                onEdit: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => FractionallySizedBox(
                    heightFactor: 0.92,
                    child: AddServiceSheet(existing: svc),
                  ),
                ),
                onToggleStatus: () => ref
                    .read(servicesProvider.notifier)
                    .toggleServiceStatus(svc.id),
                onDelete: () => _confirmDelete(context, ref, svc),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ServiceModel svc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete service'),
        content: Text('Remove "${svc.title}" from your catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(servicesProvider.notifier).deleteService(svc.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User (customer) view
// ---------------------------------------------------------------------------

class _UserServicesView extends ConsumerStatefulWidget {
  const _UserServicesView();

  @override
  ConsumerState<_UserServicesView> createState() => _UserServicesViewState();
}

class _UserServicesViewState extends ConsumerState<_UserServicesView> {
  int _selectedTab = 0;
  static const _filterLabels = ['All', 'Saved', 'Recent'];

  /// Derives the visible list based on the selected tab.
  List<ServiceModel> _tabServices(
    List<ServiceModel> all,
    List<ServiceModel> saved,
  ) {
    switch (_selectedTab) {
      case 1: // Saved — from savedServicesProvider
        return saved;
      case 2: // Recent — last 5 services by createdAt
        final sorted = [...all]
          ..sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );
        return sorted.take(5).toList();
      default: // All
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesState = ref.watch(servicesProvider);
    final allServices = ref.watch(filteredServicesProvider);
    final savedServices = ref.watch(savedServicesProvider).savedServices;

    final visibleServices = _tabServices(allServices, savedServices);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Services Directory',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse and book from available services.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _ServiceSearchField(
                hint: 'Search services...',
                onChanged: ref.read(servicesProvider.notifier).updateSearch,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterLabels.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    // Show count badge on Saved pill when > 0
                    final label = i == 1 && savedServices.isNotEmpty
                        ? 'Saved (${savedServices.length})'
                        : _filterLabels[i];
                    return _CategoryPill(
                      label: label,
                      isSelected: _selectedTab == i,
                      onTap: () => setState(() => _selectedTab = i),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Body
        Expanded(
          child: servicesState.status == ServicesStatus.loading
              ? const _ServicesGridSkeleton()
              : servicesState.status == ServicesStatus.failure
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                          servicesState.errorMessage ?? 'Something went wrong.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(servicesProvider.notifier)
                              .loadServices(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : visibleServices.isEmpty
              ? _UserEmptyState(tab: _filterLabels[_selectedTab])
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: visibleServices.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.74,
                  ),
                  itemBuilder: (context, index) => ServiceCard(
                    service: visibleServices[index],
                    isProvider: false,
                  ),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _UserEmptyState extends StatelessWidget {
  final String tab;
  const _UserEmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    final (icon, message) = switch (tab) {
      'Saved' => (
        Icons.favorite_border_rounded,
        'Tap the heart on any service to save it here.',
      ),
      'Recent' => (
        Icons.history_rounded,
        'Services you have recently viewed will appear here.',
      ),
      _ => (
        Icons.home_repair_service_outlined,
        'No services found. Try a different search.',
      ),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No $tab services',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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
// Shared local widgets
// ---------------------------------------------------------------------------

class _ServiceSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final String? initialValue;

  const _ServiceSearchField({
    required this.hint,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<_ServiceSearchField> createState() => _ServiceSearchFieldState();
}

class _ServiceSearchFieldState extends State<_ServiceSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant _ServiceSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        (widget.initialValue ?? '') != _controller.text) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  void _handleTextChanged() {
    widget.onChanged(_controller.text);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    _controller.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
