import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';

import '/auth/base_auth_user_provider.dart';

import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';

import '/pages/vark_onboarding/vark_onboarding_widget.dart';
import '/pages/subscription/subscription_onboarding_widget.dart';
import '/pages/subscription/subscription_management_widget.dart';
import '/pages/foco_map/foco_map_conditional_widget.dart';
import '/pages/splash/enhanced_splash_widget.dart';
import '/pages/golf_rounds/caddyplay_widget.dart';
import '/pages/security/face_id_settings_widget.dart';
import '/pages/edit_profile/edit_profile_widget.dart';
import '/pages/settings/settings_widget.dart';
import '/pages/support/support_widget.dart';
import '/pages/quick_mind_tools/breathing_tool_widget.dart';
import '/pages/quick_mind_tools/visualize_tool_widget.dart';
import '/pages/quick_mind_tools/reset_tool_widget.dart';
import '/pages/quick_mind_tools/rebalance_tool_widget.dart';
import '/pages/quick_mind_tools/virtual_training_experience_widget.dart';
import '/pages/just_talk/just_talk_widget.dart';
import '/features/mindcoach_v2/app/mindcoach_v2_entry_widget.dart';
import '/config/app_feature_flags.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => appStateNotifier.loggedIn
          ? const MindCoachV2EntryWidget()
          : LoginWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => const EnhancedSplashWidget(),
        ),
        FFRoute(
          name: LoginWidget.routeName,
          path: LoginWidget.routePath,
          builder: (context, params) => LoginWidget(),
        ),
        FFRoute(
          name: ProfileWidget.routeName,
          path: ProfileWidget.routePath,
          requireAuth: true,
          builder: (context, params) => ProfileWidget(),
        ),
        FFRoute(
          name: 'face_id_settings',
          path: '/face-id-settings',
          requireAuth: true,
          builder: (context, params) => FaceIdSettingsWidget(),
        ),
        FFRoute(
          name: 'ai_insights',
          path: '/ai_insights',
          requireAuth: true,
          builder: (context, params) => const AiInsightsWidget(),
        ),
        FFRoute(
          name: CaddyPlayWidget.routeName,
          path: CaddyPlayWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const CaddyPlayWidget(),
        ),
        FFRoute(
          name: MindCoachWidget.routeName,
          path: MindCoachWidget.routePath,
          requireAuth: true,
          builder: (context, params) => MindCoachV2EntryWidget(
            initialTabIndex: params.state.extraMap['initialTab'] ?? 0,
          ),
        ),
        FFRoute(
          name: 'mind_coach_legacy',
          path: '/mind_coach_legacy',
          requireAuth: true,
          builder: (context, params) => kDebugMode
              ? MindCoachWidget(
                  initialTabIndex: params.state.extraMap['initialTab'] ?? 0,
                )
              : MindCoachV2EntryWidget(
                  initialTabIndex: params.state.extraMap['initialTab'] ?? 0,
                ),
        ),
        FFRoute(
          name: ProgressWidget.routeName,
          path: ProgressWidget.routePath,
          requireAuth: true,
          builder: (context, params) => ProgressWidget(),
        ),
        FFRoute(
          name: AchievementsWidget.routeName,
          path: AchievementsWidget.routePath,
          requireAuth: true,
          builder: (context, params) => AchievementsWidget(),
        ),
        FFRoute(
          name: RegisterWidget.routeName,
          path: RegisterWidget.routePath,
          builder: (context, params) => RegisterWidget(),
        ),
        if (AppFeatureFlags.varkEnabled)
          FFRoute(
            name: VarkOnboardingWidget.routeName,
            path: VarkOnboardingWidget.routePath,
            builder: (context, params) => const VarkOnboardingWidget(),
          ),
        if (AppFeatureFlags.varkEnabled)
          FFRoute(
            name: ComprehensiveOnboardingWidget.routeName,
            path: ComprehensiveOnboardingWidget.routePath,
            builder: (context, params) => const ComprehensiveOnboardingWidget(),
          ),
        FFRoute(
          name: 'subscription_onboarding',
          path: '/subscription_onboarding',
          requireAuth: true,
          builder: (context, params) => SubscriptionOnboardingWidget(
            isMandatory: params.state.extraMap['mandatory'] == true,
          ),
        ),
        FFRoute(
          name: 'subscription_management',
          path: '/subscription_management',
          requireAuth: true,
          builder: (context, params) => const SubscriptionManagementWidget(),
        ),
        FFRoute(
          name: 'foco_map',
          path: '/foco_map',
          requireAuth: true,
          builder: (context, params) => const FoCoMapConditionalWidget(),
        ),
        FFRoute(
          name: 'edit_profile',
          path: '/edit-profile',
          requireAuth: true,
          builder: (context, params) => const EditProfileWidget(),
        ),
        FFRoute(
          name: 'settings',
          path: '/settings',
          requireAuth: true,
          builder: (context, params) => const SettingsWidget(),
        ),
        FFRoute(
          name: 'support',
          path: '/support',
          requireAuth: true,
          builder: (context, params) => const SupportWidget(),
        ),
        FFRoute(
          name: AiAssessmentWidget.routeName,
          path: AiAssessmentWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const AiAssessmentWidget(),
        ),
        FFRoute(
          name: BreathingToolWidget.routeName,
          path: BreathingToolWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const BreathingToolWidget(),
        ),
        FFRoute(
          name: VisualizeToolWidget.routeName,
          path: VisualizeToolWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const VisualizeToolWidget(),
        ),
        FFRoute(
          name: ResetToolWidget.routeName,
          path: ResetToolWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const ResetToolWidget(),
        ),
        FFRoute(
          name: RebalanceToolWidget.routeName,
          path: RebalanceToolWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const RebalanceToolWidget(),
        ),
        FFRoute(
          name: VirtualTrainingExperienceWidget.routeName,
          path: VirtualTrainingExperienceWidget.routePath,
          requireAuth: true,
          builder: (context, params) => VirtualTrainingExperienceWidget(
            moduleTitle: params.state.extraMap['moduleTitle'] as String?,
            moduleId: params.state.extraMap['moduleId'] as String?,
            description: params.state.extraMap['description'] as String?,
            estimatedDuration:
                params.state.extraMap['estimatedDuration'] as int?,
          ),
        ),
        FFRoute(
          name: JustTalkWidget.routeName,
          path: JustTalkWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const JustTalkWidget(),
        ),
        FFRoute(
          name: GolfChatWidget.routeName,
          path: GolfChatWidget.routePath,
          requireAuth: true,
          builder: (context, params) => const GolfChatWidget(),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList()
        ..addAll([
          _buildAliasRoute(
            appStateNotifier: appStateNotifier,
            name: DashboardWidget.routeName,
            path: DashboardWidget.routePath,
            targetPath: MindCoachWidget.routePath,
          ),
          _buildAliasRoute(
            appStateNotifier: appStateNotifier,
            name: GolfSyncWidget.routeName,
            path: GolfSyncWidget.routePath,
            targetPath: CaddyPlayWidget.routePath,
          ),
          if (!AppFeatureFlags.varkEnabled)
            _buildAliasRoute(
              appStateNotifier: appStateNotifier,
              name: VarkOnboardingWidget.routeName,
              path: VarkOnboardingWidget.routePath,
              targetPath: MindCoachWidget.routePath,
            ),
          if (!AppFeatureFlags.varkEnabled)
            _buildAliasRoute(
              appStateNotifier: appStateNotifier,
              name: ComprehensiveOnboardingWidget.routeName,
              path: ComprehensiveOnboardingWidget.routePath,
              targetPath: MindCoachWidget.routePath,
            ),
        ]),
    );

GoRoute _buildAliasRoute({
  required AppStateNotifier appStateNotifier,
  required String name,
  required String path,
  required String targetPath,
}) {
  return GoRoute(
    name: name,
    path: path,
    redirect: (context, state) {
      if (appStateNotifier.shouldRedirect) {
        final redirectLocation = appStateNotifier.getRedirectLocation();
        appStateNotifier.clearRedirectLocation();
        return redirectLocation;
      }

      return targetPath;
    },
  );
}

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/login';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);

          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child =
              appStateNotifier.loading ? const EnhancedSplashWidget() : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
