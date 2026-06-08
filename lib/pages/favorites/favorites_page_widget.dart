import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '/ai_integration/services/voice_chat_database_service.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/presentation/shared/mindcoach_v2_visuals.dart';
import '/features/mindcoach_v2/services/mindcoach_favorite_launcher.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/widgets/maintenance_gate.dart';

class FavoritesPageWidget extends StatefulWidget {
  const FavoritesPageWidget({super.key});

  static const String routeName = 'favorites';
  static const String routePath = '/favorites';

  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: routeName),
        builder: (_) => const FavoritesPageWidget(),
      ),
    );
  }

  @override
  State<FavoritesPageWidget> createState() => _FavoritesPageWidgetState();
}

class _FavoritesPageWidgetState extends State<FavoritesPageWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final MindCoachV2Repository _mindRepository = MindCoachV2Repository.instance;
  final VoiceChatDatabaseService _chatDb = VoiceChatDatabaseService();

  bool _mindStarting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_chatDb.initialize());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startMindFavorite(MindCoachV2Favorite favorite) async {
    if (_mindStarting) {
      return;
    }
    setState(() => _mindStarting = true);
    try {
      await MindCoachFavoriteLauncher.openFavorite(context, favorite);
    } finally {
      if (mounted) {
        setState(() => _mindStarting = false);
      }
    }
  }

  void _openChatSession(VoiceChatSession session) {
    Navigator.of(context).pop();
    context.goNamed(
      'golf_chat',
      extra: <String, dynamic>{'sessionId': session.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Material(
      color: kFoCoCoShellTint,
      child: ColoredBox(
        color: kFoCoCoShellTint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FoCoCoInlineScreenHeader(
              title: 'Saved',
              titleColor: Colors.white,
              leading: IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              ),
              topInset: viewPadding.top,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: TabBar(
                controller: _tabController,
                indicatorColor: theme.primary,
                indicatorWeight: 2.5,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.52),
                labelStyle: theme.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                unselectedLabelStyle: theme.titleSmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'MindSessions'),
                  Tab(text: 'Chats'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MindSessionsTab(
                    repository: _mindRepository,
                    starting: _mindStarting,
                    onFavoriteTap: _startMindFavorite,
                  ),
                  _ChatsTab(
                    chatDb: _chatDb,
                    onSessionTap: _openChatSession,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MindSessionsTab extends StatelessWidget {
  const _MindSessionsTab({
    required this.repository,
    required this.starting,
    required this.onFavoriteTap,
  });

  final MindCoachV2Repository repository;
  final bool starting;
  final Future<void> Function(MindCoachV2Favorite favorite) onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    if (currentUserUid.isEmpty) {
      return const _EmptyState(
        message: 'Sign in to view saved MindSessions.',
      );
    }

    return StreamBuilder<List<MindCoachV2Favorite>>(
      stream: repository.streamFavorites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCCCCCC)),
              ),
            ),
          );
        }

        final favorites = snapshot.data ?? const <MindCoachV2Favorite>[];
        if (favorites.isEmpty) {
          return const _EmptyState(
            message:
                'No saved MindSessions yet.\nFinish a session and tap Add to Favorites.',
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            foCoCoTabShellBottomReserve(context, extra: 24),
          ),
          itemCount: favorites.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final favorite = favorites[index];
            final accent = MindCoachV2Visuals.accentForPillar(favorite.pillar);
            return _MindFavoriteCard(
              favorite: favorite,
              accent: accent,
              starting: starting,
              onStart: () => onFavoriteTap(favorite),
            );
          },
        );
      },
    );
  }
}

class _MindFavoriteCard extends StatelessWidget {
  const _MindFavoriteCard({
    required this.favorite,
    required this.accent,
    required this.onStart,
    this.starting = false,
  });

  final MindCoachV2Favorite favorite;
  final Color accent;
  final VoidCallback onStart;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    final duration = MindCoachV2Visuals.formatSessionDuration(
      favorite.durationSec,
    );

    return MindCoachGlowCard(
      color: accent,
      showTopGlow: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.sessionName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (favorite.sessionDescriptor.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        favorite.sessionDescriptor,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (duration.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    duration,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${favorite.pillar.label} · ${favorite.contextMode.displayLabel}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.56),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: starting ? null : onStart,
              style: FilledButton.styleFrom(
                backgroundColor: accent.withValues(alpha: 0.22),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: accent.withValues(alpha: 0.55)),
                ),
              ),
              child: starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    )
                  : const Text(
                      'Start session',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatsTab extends StatelessWidget {
  const _ChatsTab({
    required this.chatDb,
    required this.onSessionTap,
  });

  final VoiceChatDatabaseService chatDb;
  final void Function(VoiceChatSession session) onSessionTap;

  @override
  Widget build(BuildContext context) {
    if (currentUserUid.isEmpty) {
      return const _EmptyState(
        message: 'Sign in to view saved GolfChats.',
      );
    }

    return StreamBuilder<List<VoiceChatSession>>(
      stream: chatDb.streamGolfChatSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCCCCCC)),
              ),
            ),
          );
        }

        final sessions = snapshot.data ?? const <VoiceChatSession>[];
        if (sessions.isEmpty) {
          return const _EmptyState(
            message: 'No GolfChats yet.\nStart a conversation in GolfChat.',
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            foCoCoTabShellBottomReserve(context, extra: 24),
          ),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _ChatSessionCard(
              session: session,
              onTap: () => onSessionTap(session),
            );
          },
        );
      },
    );
  }
}

class _ChatSessionCard extends StatelessWidget {
  const _ChatSessionCard({
    required this.session,
    required this.onTap,
  });

  final VoiceChatSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final when = timeago.format(session.startTime, locale: 'en_short');
    final subtitle = session.messageCount > 0
        ? '${session.messageCount} message${session.messageCount == 1 ? '' : 's'}'
        : 'No messages yet';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E7FC4).withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: theme.primaryText.withValues(alpha: 0.9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title.trim().isEmpty
                          ? 'GolfChat'
                          : session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subtitle · $when',
                      style: theme.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.45,
              ),
        ),
      ),
    );
  }
}
