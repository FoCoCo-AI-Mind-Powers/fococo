import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import 'backend/push_notifications/push_notifications_handler.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import '/services/stripe_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();

  // Initialize timezone data for scheduled notifications
  tz.initializeTimeZones();

  // Set up background message handler for FCM with error handling
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error setting up background message handler: $e');
    }
  }

  await FlutterFlowTheme.initialize();

  // Initialize Stripe
  try {
    await StripeService().initialize();
    if (kDebugMode) {
      print('✅ Stripe initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Failed to initialize Stripe: $e');
    }
  }

  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

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

  late Stream<BaseAuthUser> userStream;
  StreamSubscription<BaseAuthUser>? userStreamSubscription;
  StreamSubscription<Future<String?>>? jwtTokenStreamSubscription;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    // Initialize the user stream and handle authentication state
    _initializeUserStream();

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

  void _initializeUserStream() {
    try {
      userStream = foCoCoFirebaseUserStream();

      // Listen to the user stream with a subscription
      userStreamSubscription = userStream.listen(
        (user) async {
          if (kDebugMode) {
            print(
                '🔄 User state changed: ${user.loggedIn ? 'logged in' : 'logged out'}');
          }

          if (mounted) {
            _appStateNotifier.update(user);

            // Let the enhanced splash screen handle navigation timing
            if (kDebugMode) {
              print(
                  '🔄 User state updated, enhanced splash will handle navigation');
            }
          }

          // Handle user authentication state (simplified)
          if (user.loggedIn) {
            if (kDebugMode) {
              print('✅ User logged in: ${user.uid}');
            }
            // Removed push notification initialization to prevent delays
          } else {
            if (kDebugMode) {
              print('✅ User logged out - showing home page');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Error in user stream: $error');
          }
          // Enhanced splash screen will handle error cases
          if (kDebugMode) {
            print('🛑 Error handled by enhanced splash screen');
          }
        },
      );

      // Simplified JWT token stream handling
      jwtTokenStreamSubscription =
          jwtTokenStream.listen((_) {}, onError: (error) {
        if (kDebugMode) {
          print('❌ Error in JWT token stream: $error');
        }
      });

      // Let enhanced splash screen handle initial user check timing
      if (kDebugMode) {
        print('🔄 Enhanced splash screen will handle initial user check');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing user stream: $e');
      }
      // Enhanced splash screen will handle initialization errors
      if (kDebugMode) {
        print('🛑 Enhanced splash screen will handle initialization error');
      }
    }
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  void dispose() {
    userStreamSubscription?.cancel();
    jwtTokenStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FoCoCo',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
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
      darkTheme: ThemeData(
        brightness: Brightness.dark,
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
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
