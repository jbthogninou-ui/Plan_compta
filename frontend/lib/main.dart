import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: ComptaApp()));
}

class ComptaApp extends ConsumerStatefulWidget {
  const ComptaApp({super.key});

  @override
  ConsumerState<ComptaApp> createState() => _ComptaAppState();
}

class _ComptaAppState extends ConsumerState<ComptaApp> {
  @override
  void initState() {
    super.initState();
    // Relie l'expiration de session (refresh token invalide) à l'AuthNotifier,
    // qui fera basculer le router vers l'écran de connexion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiClientProvider).onSessionExpired = () {
        ref.read(authProvider.notifier).forceExpire();
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Compta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
