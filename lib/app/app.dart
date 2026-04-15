import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/app/router/app_router.dart';
import 'package:discovaa/app/theme/app_theme.dart';
import 'package:discovaa/shared/providers/theme_provider.dart';
import 'package:discovaa/shared/providers/locale_provider.dart';

class DiscovaaApp extends ConsumerWidget {
  const DiscovaaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Discovaa',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: AppThemes.lightTheme,
      themeMode: themeMode,
      locale: locale,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(
              context,
            ).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
          ),
          child: child!,
        );
      },
    );
  }
}
