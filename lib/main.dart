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
    
    // Reduced timeout to prevent long loading times
    Future.delayed(
      Duration(milliseconds: 800), // Reduced from 2000ms to 800ms
      () {
        if (_appStateNotifier.showSplashImage) {
          if (kDebugMode) {
            print('⏱️ Splash screen timeout - forcing stop');
          }
          _appStateNotifier.stopShowingSplashImage();
        }
      },
    );

    // Additional safety timeout for extreme cases
    Future.delayed(
      Duration(milliseconds: 1500),
      () {
        if (_appStateNotifier.showSplashImage) {
          if (kDebugMode) {
            print('🚨 Emergency splash screen timeout - forcing stop');
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
            print('🔄 User state changed: ${user.loggedIn ? 'logged in' : 'logged out'}');
          }
          
          if (mounted) {
            _appStateNotifier.update(user);
            
            // Stop showing splash screen immediately when user state is determined
            if (_appStateNotifier.showSplashImage) {
              if (kDebugMode) {
                print('🛑 Stopping splash screen');
              }
              _appStateNotifier.stopShowingSplashImage();
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
          // Stop splash screen immediately on error to prevent infinite loading
          if (mounted && _appStateNotifier.showSplashImage) {
            if (kDebugMode) {
              print('🛑 Stopping splash screen due to error');
            }
            _appStateNotifier.stopShowingSplashImage();
          }
        },
      );
      
      // Simplified JWT token stream handling
      jwtTokenStreamSubscription = jwtTokenStream.listen((_) {}, onError: (error) {
        if (kDebugMode) {
          print('❌ Error in JWT token stream: $error');
        }
      });
      
      // Reduced delay for initial user check
      Future.delayed(Duration(milliseconds: 200), () { // Reduced from 500ms to 200ms
        if (_appStateNotifier.showSplashImage) {
          if (kDebugMode) {
            print('🔄 Forcing initial user check');
          }
          // This will trigger the user stream if it hasn't already
          foCoCoFirebaseUserStream().take(1).listen(
            (user) {
              if (kDebugMode) {
                print('🔄 Initial user check: ${user.loggedIn ? 'logged in' : 'logged out'}');
              }
              if (mounted) {
                _appStateNotifier.update(user);
                if (_appStateNotifier.showSplashImage) {
                  _appStateNotifier.stopShowingSplashImage();
                }
              }
            },
            onError: (error) {
              if (kDebugMode) {
                print('❌ Error in initial user check: $error');
              }
              if (mounted && _appStateNotifier.showSplashImage) {
                _appStateNotifier.stopShowingSplashImage();
              }
            },
          );
        }
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing user stream: $e');
      }
      // Ensure splash screen is stopped immediately even if user stream fails
      if (mounted && _appStateNotifier.showSplashImage) {  
        if (kDebugMode) {
          print('🛑 Stopping splash screen due to initialization error');
        }
        _appStateNotifier.stopShowingSplashImage();
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
