import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/biometric/presentation/providers/biometric_providers.dart';
import 'routing/app_router.dart';

class _LockScreenObserver extends NavigatorObserver {
  int _lockScreenCount = 0;
  bool get isLockScreenVisible => _lockScreenCount > 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == AppRouter.biometricLock) {
      _lockScreenCount++;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == AppRouter.biometricLock) {
      _lockScreenCount = (_lockScreenCount - 1).clamp(0, 999);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == AppRouter.biometricLock) {
      _lockScreenCount = (_lockScreenCount - 1).clamp(0, 999);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute?.settings.name == AppRouter.biometricLock) {
      _lockScreenCount = (_lockScreenCount - 1).clamp(0, 999);
    }
    if (newRoute?.settings.name == AppRouter.biometricLock) {
      _lockScreenCount++;
    }
  }
}

class BaniRasijanApp extends ConsumerStatefulWidget {
  const BaniRasijanApp({super.key});

  @override
  ConsumerState<BaniRasijanApp> createState() => _BaniRasijanAppState();
}

class _BaniRasijanAppState extends ConsumerState<BaniRasijanApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _LockScreenObserver _lockScreenObserver = _LockScreenObserver();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final bioController = ref.read(biometricControllerProvider.notifier);
    if (bioController.isAuthenticating) {
      return;
    }

    if (state == AppLifecycleState.paused) {
      bioController.recordBackground();
    } else if (state == AppLifecycleState.resumed) {
      _checkAutoLock();
    }
  }

  Future<void> _checkAutoLock() async {
    final bioController = ref.read(biometricControllerProvider.notifier);
    if (bioController.isAuthenticating ||
        _lockScreenObserver.isLockScreenVisible) {
      return;
    }

    final shouldLock = await bioController.shouldLockOnResume();
    if (!shouldLock) return;

    final session = ref.read(authRepositoryProvider).currentSession;
    if (session != null && _navigatorKey.currentState != null) {
      await _navigatorKey.currentState?.pushNamed(AppRouter.biometricLock);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: _navigatorKey,
        navigatorObservers: [_lockScreenObserver],
        title: 'BANI RASIJAN',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.splash,
      );
}
