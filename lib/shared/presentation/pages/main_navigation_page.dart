import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/shared/presentation/widgets/bottom_nav_bar.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  final Widget child;
  const MainNavigationPage({super.key, required this.child});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  List<String> get _paths => [
    RouteNames.home,
    RouteNames.dashboard,
    RouteNames.bookings,
    RouteNames.messages,
    RouteNames.services,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will update the selected index based on route, though we might need
    // to do this in build if Provider changes dynamically.
  }

  @override
  Widget build(BuildContext context) {
    final paths = _paths;

    final location = GoRouterState.of(context).matchedLocation;
    final newIndex = paths.indexWhere((path) => location.startsWith(path));
    if (newIndex != -1 && newIndex != _selectedIndex) {
      // Defer state update to avoid build cycle warning
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = newIndex);
      });
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          context.go(paths[index]);
        },
      ),
    );
  }
}
