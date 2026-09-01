import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/fcm_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/data/invite_link_service.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import 'router.dart';

/// Kök uygulama widget'ı.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  String? _lastSyncedUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inviteLinkServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      final prevUid = prev?.valueOrNull?.uid;
      final uid = next.valueOrNull?.uid;
      if (uid != null && uid != _lastSyncedUid) {
        _lastSyncedUid = uid;
        FcmService.syncTokenForUser(uid);
      }
      if (uid == null) {
        if (prevUid != null) {
          FcmService.clearTokenForUser(prevUid);
        }
        _lastSyncedUid = null;
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Eduly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('tr', 'TR'),
    );
  }
}
