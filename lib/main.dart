import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'auth/firebase_auth/firebase_user_provider.dart';

import 'backend/firebase/firebase_config.dart';
import 'backend/push_notifications/push_notifications_handler.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import '/services/stripe_service.dart';
import '/services/store_subscription_service.dart';
import '/services/revenuecat_service.dart';
import '/services/background_audio_service.dart';
import '/services/boot_phase_logger.dart';
import '/services/startup_auth_service.dart';
import '/services/subscription_state_provider.dart';
import '/services/widget_data_service.dart';
import '/widgets/maintenance_gate.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/ai_integration/services/cartesia_api_service.dart';
import '/ai_integration/services/cartesia_voice_runtime.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:provider/provider.dart';

void main() async {
  // Run the entire app inside a guarded zone so any uncaught async error —
  // including errors delivered by native plugins on the Dart VM event handler
  // thread — is caught and logged instead of aborting the process. The native
  // stack trace `dart::bin::EventHandlerImplementation::EventHandlerEntry`
  // indicates exactly that kind of unhandled async error escaping into the
  // VM's event loop (typically from a stream callback, timer, or HTTP Future
  // completing after its owner was disposed).
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    GoRouter.optionURLReflectsImperativeAPIs = true;
    usePathUrlStrategy();

    // Firebase init can rethrow for non-duplicate-app errors; catch here so
    // the app still launches (degraded) instead of a silent process abort.
    try {
      await initFirebase();
      await BootPhaseLogger.configureCrashlyticsCollection();
      await BootPhaseLogger.record('firebase_initialized');
      // Firebase Performance: disable in debug to avoid noisy local traces,
      // enabled for profile + release so TestFlight / Play Store builds
      // report `_app_start`, network request traces, and custom AI traces.
      try {
        await FirebasePerformance.instance
            .setPerformanceCollectionEnabled(kReleaseMode || kProfileMode);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to configure Firebase Performance: $e');
        }
      }
      // Stamp build flavor + isolate so TestFlight crashes can be distinguished
      // from local debug noise in the Crashlytics console without having to
      // cross-reference the build number every time.
      await BootPhaseLogger.setCustomKey(
        'launch_mode',
        kReleaseMode
            ? 'release'
            : kProfileMode
                ? 'profile'
                : 'debug',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase init failed – app will launch degraded: $e');
      }
    }

    tz.initializeTimeZones();

    // Background voice: lets Cartesia TTS playback continue when the app is
    // backgrounded / the screen is locked, and surfaces lock-screen controls.
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.fococo.voice.playback',
        androidNotificationChannelName: 'FoCoCo Voice',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      );
    } catch (e) {
      if (kDebugMode) print('⚠️ JustAudioBackground.init failed: $e');
    }

    // Coordinates voice audio across lifecycle + OS interruptions.
    try {
      BackgroundAudioService.instance.init();
    } catch (e) {
      if (kDebugMode) print('⚠️ BackgroundAudioService.init failed: $e');
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting up background message handler: $e');
      }
    }

    await FlutterFlowTheme.initialize();
    try {
      await WidgetDataService.initialize();
    } catch (e) {
      if (kDebugMode) print('⚠️ WidgetDataService.initialize failed: $e');
    }

    if (!kIsWeb &&
        Firebase.apps.isNotEmpty &&
        BootPhaseLogger.crashlyticsEnabled) {
      // Flutter framework errors → Crashlytics (fatal).
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // PlatformDispatcher errors (async errors that bubble up from the
      // engine). Return true so the runtime knows we handled it — critically,
      // we do NOT rethrow. Otherwise the error continues up to the event
      // handler thread.
      PlatformDispatcher.instance.onError = (error, stack) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
        } catch (_) {}
        if (kDebugMode) {
          print('⚠️ PlatformDispatcher caught: $error');
        }
        return true;
      };
    }

    // Beacon: Dart reached runApp without aborting. If a TestFlight crash log
    // has 'reached_run_app' but no 'first_frame_painted', the crash is in
    // widget-tree construction (initState / build). If it lacks
    // 'reached_run_app', the crash is in plugin init or Firebase startup.
    unawaited(BootPhaseLogger.record('reached_run_app'));

    // Stamp once the framework has painted the first frame. This is the cheapest
    // possible "the app is alive" signal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(BootPhaseLogger.record('first_frame_painted'));
    });

    runApp(MyApp());
  }, (error, stack) {
    // Last line of defense. Any async error that wasn't caught by a local
    // try/catch, by the FlutterError handler, or by PlatformDispatcher.onError
    // lands here. Log it and keep the app running.
    if (kDebugMode) {
      print('🛡️ runZonedGuarded caught uncaught async error: $error');
      print(stack);
    }
    try {
      if (!kIsWeb &&
          Firebase.apps.isNotEmpty &&
          BootPhaseLogger.crashlyticsEnabled) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      }
    } catch (_) {}
  });
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .whereType<RouteMatch>()
          .map((e) => getRoute(e))
          .toList();

  @override
  void initState() {
    super.initState();

    _themeMode = ThemeMode.dark;
    FlutterFlowTheme.saveThemeMode(ThemeMode.dark);

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    StartupAuthService.instance.configure(
      onUserChanged: _handleUserStateChanged,
      onError: _handleUserStateError,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(BootPhaseLogger.record('post_frame_auth_bootstrap'));
      unawaited(_bootstrapAuthState());
    });

    // Keep payment/subscription SDK warmup out of the launch window entirely.
    // The app can function without them during first paint, and delaying them
    // reduces the odds of iOS launch-time crashes inside native SDK threads.
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) {
        return;
      }
      unawaited(_warmStartupServices());
    });

    // Enhanced splash screen will handle its own timing and navigation
    // Reduced timeout as backup safety measure
    Future.delayed(
      Duration(
          milliseconds: 4000), // Longer timeout to let enhanced splash complete
      () {
        if (_appStateNotifier.showSplashImage) {
          if (kDebugMode) {
            print('⏱️ Backup splash screen timeout - forcing stop');
          }
          _appStateNotifier.stopShowingSplashImage();
        }
      },
    );
  }

  Future<void> _warmStartupServices() async {
    await BootPhaseLogger.record('deferred_services_start');
    await _initializeDeferredService(
      name: 'Stripe',
      initialize: () => StripeService().initialize(),
    );
    await _initializeDeferredService(
      name: 'RevenueCat',
      initialize: () => RevenueCatService().initialize(),
    );
    await _initializeDeferredService(
      name: 'Store Subscription Service',
      initialize: () => StoreSubscriptionService().initialize(),
    );
    await _initializeDeferredService(
      name: 'Subscription State Provider',
      initialize: () => SubscriptionStateProvider().initialize(),
    );
    if (currentUserUid.isNotEmpty) {
      unawaited(_warmCartesiaVoice());
    }
  }

  Future<void> _warmCartesiaVoice() async {
    try {
      await CartesiaVoiceRuntime.load();
      final tts = CartesiaAPIService.instance;
      if (!tts.isInitialized) {
        await tts.initialize();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Cartesia voice warm skipped: $e');
      }
    }
  }

  Future<void> _initializeDeferredService({
    required String name,
    required Future<void> Function() initialize,
  }) async {
    try {
      await initialize();
      if (kDebugMode) {
        print('✅ $name initialized successfully');
      }
    } catch (error, stackTrace) {
      // Only log to Crashlytics if Firebase is actually initialised.
      // If Firebase init failed, accessing FirebaseCrashlytics.instance throws.
      if (!kIsWeb &&
          Firebase.apps.isNotEmpty &&
          BootPhaseLogger.crashlyticsEnabled) {
        try {
          await FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            reason: '$name startup initialization failed',
          );
        } catch (_) {}
      }
      if (kDebugMode) {
        print('❌ Failed to initialize $name: $error');
      }
    }
  }

  Future<void> _bootstrapAuthState() async {
    try {
      await StartupAuthService.instance.bootstrap();
      if (kDebugMode) {
        print('🔄 Auth bootstrap completed');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Auth bootstrap failed: $error');
      }
    }
  }

  Future<void> _handleUserStateChanged(BaseAuthUser user) async {
    unawaited(BootPhaseLogger.setCustomKey(
      'auth_user_state',
      user.loggedIn ? 'logged_in' : 'logged_out',
    ));
    unawaited(BootPhaseLogger.record('auth_user_resolved'));

    if (kDebugMode) {
      print(
          '🔄 User state changed: ${user.loggedIn ? 'logged in' : 'logged out'}');
    }

    if (!mounted) {
      return;
    }

    _appStateNotifier.update(user);

    if (kDebugMode) {
      print('🔄 User state updated, enhanced splash will handle navigation');
    }

    if (user.loggedIn) {
      if (kDebugMode) {
        print('✅ User logged in: ${user.uid}');
      }
      unawaited(_warmCartesiaVoice());
      return;
    }

    if (kDebugMode) {
      print('✅ User logged out - showing home page');
    }
  }

  void _handleUserStateError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('❌ Error in user stream: $error');
      print('🛑 Error handled by enhanced splash screen');
    }
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = ThemeMode.dark;
        FlutterFlowTheme.saveThemeMode(ThemeMode.dark);
      });

  @override
  void dispose() {
    unawaited(StartupAuthService.instance.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SubscriptionStateProvider>.value(
      value: SubscriptionStateProvider(),
      child: MaintenanceGate(
        child: AdaptiveApp.router(
        routerConfig: _router,
        title: 'FoCoCo',
        themeMode: _themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        material: (_, __) =>
            const MaterialAppData(debugShowCheckedModeBanner: false),
        materialLightTheme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor:
              const Color(0xFFFFFFFF), // White background for light mode
          colorScheme: const ColorScheme.light(
            brightness: Brightness.light,
            primary: Color(0xFFFEA400), // FoCoCo orange
            onPrimary: Colors.white,
            secondary: Color(0xFF0A3669), // Navy blue
            onSecondary: Colors.white,
            surface: Color(0xFFFFFFFF), // White surface
            onSurface: Color(0xFF0F172A), // Dark text on light surface
            onSurfaceVariant: Color(0xFF475569), // Grey text for secondary
            background: Color(0xFFFFFFFF), // White background
            onBackground: Color(0xFF0F172A), // Dark text on background
            error: Color(0xFFDC2626),
            onError: Colors.white,
          ),
          scrollbarTheme: ScrollbarThemeData(
            thumbVisibility: WidgetStateProperty.all(true),
            interactive: true,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.dragged)) {
                return Color(4282089311);
              }
              if (states.contains(WidgetState.hovered)) {
                return Color(1275734606);
              }
              return Color(4278856270);
            }),
          ),
        ),
        materialDarkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF111827), // Dark background
          colorScheme: const ColorScheme.dark(
            brightness: Brightness.dark,
            primary: Color(0xFFFEA400), // FoCoCo orange
            onPrimary: Colors.white,
            secondary: Color(0xFF1E40AF), // Navy blue
            onSecondary: Colors.white,
            surface: Color(0xFF1F2937), // Dark surface
            onSurface: Colors.white, // White text on dark surface
            onSurfaceVariant: Color(0xFF94A3B8), // Grey text for secondary
            background: Color(0xFF111827), // Dark background
            onBackground: Colors.white, // White text on background
            error: Color(0xFFEF4444),
            onError: Colors.white,
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: Colors.white),
            displayMedium: TextStyle(color: Colors.white),
            displaySmall: TextStyle(color: Colors.white),
            headlineLarge: TextStyle(color: Colors.white),
            headlineMedium: TextStyle(color: Colors.white),
            headlineSmall: TextStyle(color: Colors.white),
            titleLarge: TextStyle(color: Colors.white),
            titleMedium: TextStyle(color: Colors.white),
            titleSmall: TextStyle(color: Colors.white),
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
            bodySmall:
                TextStyle(color: Color(0xFF94A3B8)), // Grey for secondary text
            labelLarge: TextStyle(color: Colors.white),
            labelMedium: TextStyle(color: Colors.white),
            labelSmall: TextStyle(color: Color(0xFF94A3B8)),
          ),
          scrollbarTheme: ScrollbarThemeData(
            thumbVisibility: WidgetStateProperty.all(true),
            interactive: true,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.dragged)) {
                return Color(4282089311);
              }
              if (states.contains(WidgetState.hovered)) {
                return Color(1275734606);
              }
              return Color(4278856270);
            }),
          ),
        ),
        cupertinoLightTheme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: Color(0xFFFEA400),
        ),
        cupertinoDarkTheme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: Color(0xFFFEA400),
        ),
        ),
      ),
    );
  }
}
