import 'dart:async';

import 'package:flutter/material.dart';

import '/ai_integration/widgets/navbar_widget.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/presentation/shared/mindcoach_v2_visuals.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_catalog_service.dart';

class MindCoachHomeV2Widget extends StatefulWidget {
  const MindCoachHomeV2Widget({
    super.key,
    required this.repository,
    required this.onGenerateRequested,
    required this.onResumeRequested,
  });

  final MindCoachV2Repository repository;
  final Future<void> Function(MindCoachV2GenerateRequest request)
      onGenerateRequested;
  final Future<void> Function(MindCoachV2ResumePayload payload)
      onResumeRequested;

  @override
  State<MindCoachHomeV2Widget> createState() => _MindCoachHomeV2WidgetState();
}

class _MindCoachHomeV2WidgetState extends State<MindCoachHomeV2Widget> {
  MindCoachV2Catalog? _catalog;
  MindCoachV2ResumePayload? _resumePayload;
  MindCoachV2Pillar? _selectedPillar;
  MindCoachV2ContextMode? _selectedContext;
  bool _loading = true;
  bool _starting = false;
  bool _resumeDismissed = false;
  bool _favoritesExpanded = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitialState());
  }

  @override
  void dispose() {
    setFoCoCoNavBarBackgroundOverride(null);
    setFoCoCoNavSelectedColorOverride('mind_coach', null);
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        MindCoachV2CatalogService.instance.load(),
        widget.repository.getResumePayload(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _catalog = results[0] as MindCoachV2Catalog;
        _resumePayload = results[1] as MindCoachV2ResumePayload?;
        _loading = false;
      });
      _syncShellChrome();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError =
            'MindCoach could not finish loading. Pull to retry or reopen the app.';
      });
    }
  }

  void _syncShellChrome() {
    final selectedPillar = _selectedPillar;
    setFoCoCoNavBarBackgroundOverride(
      MindCoachV2Visuals.shellBackgroundForPillar(selectedPillar),
    );
    setFoCoCoNavSelectedColorOverride(
      'mind_coach',
      selectedPillar == null
          ? MindCoachV2Visuals.homeNavAccent
          : MindCoachV2Visuals.accentForPillar(selectedPillar),
    );
  }

  Future<void> _handleRefresh() async {
    await _loadInitialState();
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError ?? 'MindCoach could not finish loading.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _handleRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPillar(MindCoachV2Pillar pillar) {
    setState(() {
      _selectedPillar = pillar;
      _selectedContext = null;
      _favoritesExpanded = false;
    });
    _syncShellChrome();
  }

  void _openContext(MindCoachV2ContextMode contextMode) {
    if (_selectedPillar == null) {
      return;
    }
    setState(() {
      _selectedContext = contextMode;
      _favoritesExpanded = false;
    });
  }

  void _goBackOneLevel() {
    if (_selectedContext != null) {
      setState(() {
        _selectedContext = null;
      });
      return;
    }
    if (_selectedPillar != null) {
      setState(() {
        _selectedPillar = null;
        _favoritesExpanded = false;
      });
      _syncShellChrome();
    }
  }

  Future<void> _handleResume() async {
    final payload = _resumePayload;
    if (payload == null || _starting) {
      return;
    }

    setState(() => _starting = true);
    try {
      await widget.onResumeRequested(payload);
      if (mounted) {
        await _loadInitialState();
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  String _deliveryLengthForSession(MindCoachV2CatalogSession session) {
    if (session.contextMode == MindCoachV2ContextMode.duringRound ||
        session.durationSec <= 20) {
      return 'micro';
    }
    if (session.durationSec >= 75 ||
        session.contextMode == MindCoachV2ContextMode.afterRound) {
      return 'deep';
    }
    return 'standard';
  }

  Future<void> _startCatalogSession(
    MindCoachV2CatalogSession session, {
    required String entrySource,
  }) async {
    if (_starting) {
      return;
    }

    setState(() => _starting = true);
    try {
      await widget.onGenerateRequested(
        MindCoachV2GenerateRequest(
          contextMode: session.contextMode,
          entrySource: entrySource,
          pillar: session.pillar,
          sessionKey: session.key,
          sessionName: session.name,
          sessionDescriptor: session.descriptor,
          targetDurationSec: session.durationSec,
          preferredDeliveryLength: _deliveryLengthForSession(session),
        ),
      );
      if (mounted) {
        await _loadInitialState();
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  Future<void> _startFavorite(MindCoachV2Favorite favorite) {
    return _startCatalogSession(
      MindCoachV2CatalogSession(
        key: favorite.sessionKey,
        name: favorite.sessionName,
        descriptor: favorite.sessionDescriptor,
        durationSec: favorite.durationSec,
        templateId: favorite.templateId,
        pillar: favorite.pillar,
        contextMode: favorite.contextMode,
      ),
      entrySource: 'favorite_replay',
    );
  }

  Widget _buildHomeScreen(MindCoachV2Catalog catalog) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        22,
        16,
        22,
        MediaQuery.viewPaddingOf(context).bottom +
            kFoCoCoBottomNavStripAndTabsHeight +
            24,
      ),
      children: [
        const SizedBox(height: 4),
        Text(
          'MindCoach',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
        ),
        const SizedBox(height: 28),
        Text(
          catalog.homeSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: MindCoachV2Visuals.dimTextColor,
                fontWeight: FontWeight.w400,
              ),
        ),
        if (_resumePayload != null && !_resumeDismissed) ...[
          const SizedBox(height: 28),
          _ResumePill(
            onResume: _starting ? null : _handleResume,
            onDismiss: () {
              setState(() => _resumeDismissed = true);
            },
          ),
        ],
        const SizedBox(height: 34),
        for (final pillar in catalog.pillars) ...[
          MindCoachGlowCard(
            color: MindCoachV2Visuals.accentForPillar(pillar.key),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            onTap: () => _selectPillar(pillar.key),
            child: Column(
              children: [
                Text(
                  pillar.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: MindCoachV2Visuals.accentForPillar(pillar.key),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  pillar.descriptor,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildPillarScreen(MindCoachV2CatalogPillar pillar) {
    final accent = MindCoachV2Visuals.accentForPillar(pillar.key);
    return StreamBuilder<List<MindCoachV2Favorite>>(
      stream: widget.repository.streamFavorites(pillar: pillar.key),
      builder: (context, snapshot) {
        final favorites = snapshot.data ?? const <MindCoachV2Favorite>[];
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            MediaQuery.viewPaddingOf(context).bottom +
                kFoCoCoBottomNavStripAndTabsHeight +
                24,
          ),
          children: [
            _PillarHeader(
              title: pillar.label,
              subtitle: pillar.descriptor,
              color: accent,
              onBack: _goBackOneLevel,
            ),
            const SizedBox(height: 26),
            _ContextCard(
              title: 'During Round',
              subtitle:
                  pillar.rowDescriptors[MindCoachV2ContextMode.duringRound] ??
                      '',
              color: accent,
              onTap: () => _openContext(MindCoachV2ContextMode.duringRound),
            ),
            const SizedBox(height: 16),
            _ContextCard(
              title: 'Before Round',
              subtitle:
                  pillar.rowDescriptors[MindCoachV2ContextMode.beforeRound] ??
                      '',
              durationHint: pillar
                  .context(MindCoachV2ContextMode.beforeRound)
                  .durationHint,
              color: accent,
              onTap: () => _openContext(MindCoachV2ContextMode.beforeRound),
            ),
            const SizedBox(height: 16),
            _ContextCard(
              title: 'After Round',
              subtitle:
                  pillar.rowDescriptors[MindCoachV2ContextMode.afterRound] ??
                      '',
              durationHint: pillar
                  .context(MindCoachV2ContextMode.afterRound)
                  .durationHint,
              color: accent,
              onTap: () => _openContext(MindCoachV2ContextMode.afterRound),
            ),
            const SizedBox(height: 16),
            _FavoritesAccordion(
              color: accent,
              expanded: _favoritesExpanded,
              favorites: favorites,
              onTap: () {
                setState(() => _favoritesExpanded = !_favoritesExpanded);
              },
              onFavoriteTap: _startFavorite,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionListScreen(
    MindCoachV2CatalogPillar pillar,
    MindCoachV2CatalogContext contextModel,
  ) {
    final accent = MindCoachV2Visuals.accentForPillar(pillar.key);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        MediaQuery.viewPaddingOf(context).bottom +
            kFoCoCoBottomNavStripAndTabsHeight +
            24,
      ),
      children: [
        _PillarHeader(
          title: pillar.label,
          subtitle: pillar.descriptor,
          color: accent,
          onBack: _goBackOneLevel,
        ),
        const SizedBox(height: 18),
        Text(
          contextModel.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        MindCoachGlowLine(color: accent, width: 188),
        const SizedBox(height: 18),
        for (final session in contextModel.sessions) ...[
          _SessionListRow(
            color: accent,
            session: session,
            onTap: _starting
                ? null
                : () => _startCatalogSession(
                      session,
                      entrySource: contextModel.mode ==
                              MindCoachV2ContextMode.duringRound
                          ? 'during_round_overlay'
                          : 'session_list',
                    ),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    final pillar = _selectedPillar == null || catalog == null
        ? null
        : catalog.pillar(_selectedPillar!);
    final backgroundPillar = _selectedPillar;

    return PopScope(
      canPop: _selectedPillar == null && _selectedContext == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && (_selectedPillar != null || _selectedContext != null)) {
          _goBackOneLevel();
        }
      },
      child: MindCoachV2Backdrop(
        pillar: backgroundPillar,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white70,
                ),
              )
            : catalog == null
                ? _buildLoadError()
                : RefreshIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                    onRefresh: _handleRefresh,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _selectedPillar == null
                          ? _buildHomeScreen(catalog)
                          : _selectedContext == null
                              ? _buildPillarScreen(pillar!)
                              : _buildSessionListScreen(
                                  pillar!,
                                  pillar.context(_selectedContext!),
                                ),
                    ),
                  ),
      ),
    );
  }
}

class _ResumePill extends StatelessWidget {
  const _ResumePill({
    required this.onResume,
    required this.onDismiss,
  });

  final VoidCallback? onResume;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.035),
        border: Border.all(
          color: const Color(0xFF398EFF).withValues(alpha: 0.44),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Resume session?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          TextButton(
            onPressed: onResume,
            child: const Text('Resume'),
          ),
          Text(
            '·',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 18,
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            child: Text(
              'Dismiss',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.74),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarHeader extends StatelessWidget {
  const _PillarHeader({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
              ),
        ),
        const SizedBox(height: 10),
        MindCoachGlowLine(color: color, width: 168),
      ],
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.durationHint,
  });

  final String title;
  final String subtitle;
  final String? durationHint;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MindCoachGlowCard(
      color: color,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                ),
              ],
            ),
          ),
          if (durationHint != null) ...[
            const SizedBox(width: 12),
            Text(
              durationHint!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(width: 10),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

class _FavoritesAccordion extends StatelessWidget {
  const _FavoritesAccordion({
    required this.color,
    required this.expanded,
    required this.favorites,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final Color color;
  final bool expanded;
  final List<MindCoachV2Favorite> favorites;
  final VoidCallback onTap;
  final Future<void> Function(MindCoachV2Favorite favorite) onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return MindCoachGlowCard(
      color: color,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Favorites',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Saved for instant access.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.74),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            const SizedBox(height: 14),
            if (favorites.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  children: [
                    Text(
                      'No favorites yet. Complete a session and save it\nfor quick access.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.52),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 18),
                    MindCoachGlowLine(color: color, width: double.infinity),
                  ],
                ),
              )
            else ...[
              for (final favorite in favorites) ...[
                _FavoriteRow(
                  favorite: favorite,
                  color: color,
                  onTap: () => onFavoriteTap(favorite),
                ),
                const SizedBox(height: 14),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${favorites.length} of 5 slots used',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({
    required this.favorite,
    required this.color,
    required this.onTap,
  });

  final MindCoachV2Favorite favorite;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    favorite.sessionName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  '${favorite.contextMode.displayLabel} · ${favorite.durationSec} sec',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.56),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            MindCoachGlowLine(color: color, width: double.infinity),
          ],
        ),
      ),
    );
  }
}

class _SessionListRow extends StatelessWidget {
  const _SessionListRow({
    required this.color,
    required this.session,
    required this.onTap,
  });

  final Color color;
  final MindCoachV2CatalogSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.descriptor,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w400,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${session.durationSec} sec',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            MindCoachGlowLine(color: color, width: double.infinity),
          ],
        ),
      ),
    );
  }
}
