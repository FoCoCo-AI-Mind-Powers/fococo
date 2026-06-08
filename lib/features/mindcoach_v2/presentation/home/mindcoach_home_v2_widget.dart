import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';

import '/ai_integration/widgets/navbar_widget.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_repository.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/presentation/shared/mindcoach_v2_visuals.dart';
import '/features/mindcoach_v2/services/mindcoach_favorite_launcher.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_catalog_service.dart';
import '/features/mindcoach_v2/services/mindcoach_session_prefetch.dart';

class MindCoachHomeV2Widget extends StatefulWidget {
  const MindCoachHomeV2Widget({
    super.key,
    required this.repository,
    required this.onGenerateRequested,
  });

  final MindCoachV2Repository repository;
  final Future<void> Function(MindCoachV2GenerateRequest request)
      onGenerateRequested;

  @override
  State<MindCoachHomeV2Widget> createState() => _MindCoachHomeV2WidgetState();
}

class _MindCoachHomeV2WidgetState extends State<MindCoachHomeV2Widget> {
  MindCoachV2Catalog? _catalog;
  MindCoachV2Pillar? _selectedPillar;
  MindCoachV2ContextMode? _selectedContext;
  bool _loading = true;
  bool _starting = false;
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
      final catalog = await MindCoachV2CatalogService.instance.load();

      if (!mounted) {
        return;
      }

      setState(() {
        _catalog = catalog;
        _loading = false;
      });
      _syncShellChrome();
      unawaited(_prefetchLikelySession());
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

  Future<void> _prefetchLikelySession() async {
    if (_starting) return;
    try {
      final response = await widget.repository.generateSession(
        MindCoachV2GenerateRequest(
          contextMode: MindCoachV2ContextMode.offDay,
          entrySource: 'home_prefetch',
          preferredDeliveryLength: 'standard',
        ),
      );
      MindCoachSessionPrefetch.store(response);
    } catch (_) {}
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
    return MindCoachFavoriteLauncher.openFavorite(context, favorite);
  }

  Widget _buildHomeScreen(MindCoachV2Catalog catalog) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        22,
        16 + viewPadding.top,
        22,
        foCoCoTabShellBottomReserve(context, extra: 32),
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
        const SizedBox(height: 34),
        for (var i = 0; i < MindCoachV2Visuals.homePillarOrder.length; i++) ...[
          _MindCoachPillarTabCard(
            pillar: catalog.pillar(MindCoachV2Visuals.homePillarOrder[i]),
            onTap: () =>
                _selectPillar(MindCoachV2Visuals.homePillarOrder[i]),
          ),
          if (i < MindCoachV2Visuals.homePillarOrder.length - 1)
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
        final viewPadding = MediaQuery.viewPaddingOf(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PillarHeader(
              title: pillar.label,
              subtitle: pillar.descriptor,
              color: accent,
              onBack: _goBackOneLevel,
              topInset: viewPadding.top,
            ),
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  foCoCoTabShellBottomReserve(context, extra: 32),
                ),
                children: [
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
              color: accent,
              onTap: () => _openContext(MindCoachV2ContextMode.beforeRound),
            ),
            const SizedBox(height: 16),
            _ContextCard(
              title: 'After Round',
              subtitle:
                  pillar.rowDescriptors[MindCoachV2ContextMode.afterRound] ??
                      '',
              color: accent,
              onTap: () => _openContext(MindCoachV2ContextMode.afterRound),
            ),
            const SizedBox(height: 16),
            _FavoritesAccordion(
              color: accent,
              expanded: _favoritesExpanded,
              favorites: favorites,
              starting: _starting,
              onTap: () {
                setState(() => _favoritesExpanded = !_favoritesExpanded);
              },
              onFavoriteTap: _startFavorite,
            ),
            const SizedBox(height: 20),
            const _MindCoachDisclosures(),
                ],
              ),
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
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final contextSubtitle =
        pillar.rowDescriptors[contextModel.mode] ?? pillar.descriptor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PillarHeader(
          title: contextModel.label,
          subtitle: contextSubtitle,
          color: accent,
          onBack: _goBackOneLevel,
          topInset: viewPadding.top,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
          child: Text(
            '${pillar.label} · ${contextModel.sessions.length} sessions',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ),
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              22,
              16,
              22,
              foCoCoTabShellBottomReserve(context, extra: 48),
            ),
            children: [
              for (final session in contextModel.sessions) ...[
                _SessionStartCard(
                  color: accent,
                  session: session,
                  starting: _starting,
                  onStart: () => _startCatalogSession(
                    session,
                    entrySource: contextModel.mode ==
                            MindCoachV2ContextMode.duringRound
                        ? 'during_round_overlay'
                        : 'session_list',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              const _MindCoachDisclosures(),
            ],
          ),
        ),
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

class _MindCoachPillarTabCard extends StatefulWidget {
  const _MindCoachPillarTabCard({
    required this.pillar,
    required this.onTap,
  });

  final MindCoachV2CatalogPillar pillar;
  final VoidCallback onTap;

  @override
  State<_MindCoachPillarTabCard> createState() => _MindCoachPillarTabCardState();
}

class _MindCoachPillarTabCardState extends State<_MindCoachPillarTabCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  bool _pressed = false;
  bool _hovering = false;

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _setHighlight(bool active) {
    if (active) {
      _hoverController.forward();
    } else if (!_pressed) {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = MindCoachV2Visuals.accentForPillar(widget.pillar.key);

    return MouseRegion(
      onEnter: (_) {
        _hovering = true;
        _setHighlight(true);
      },
      onExit: (_) {
        _hovering = false;
        _setHighlight(false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() => _pressed = true);
          _hoverController.forward();
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          if (!_hovering) {
            _hoverController.reverse();
          }
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _pressed = false);
          _hoverController.reverse();
        },
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(_hoverController.value);
            final scale = 1.0 + (t * 0.022);
            final borderAlpha = 0.38 + (t * 0.42);
            final fillAlpha = 0.035 + (t * 0.03);
            final glowStrength = 0.55 + (t * 0.45);

            return Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: fillAlpha),
                  border: Border.all(
                    color: accent.withValues(alpha: borderAlpha),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.1 + (t * 0.22)),
                      blurRadius: 24 + (t * 28),
                      spreadRadius: -8 + (t * 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 12 + (t * 4),
                            sigmaY: 12 + (t * 4),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.pillar.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Color.lerp(
                                            accent,
                                            Colors.white,
                                            t * 0.12,
                                          ),
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.4,
                                        ),
                                  ),
                                ),
                                Iconify(
                                  MindCoachV2Visuals.iconAssetForPillar(
                                    widget.pillar.key,
                                  ),
                                  color: accent.withValues(
                                    alpha: 0.88 + (t * 0.12),
                                  ),
                                  size: 34 + (t * 4),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.pillar.descriptor,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white
                                        .withValues(alpha: 0.88 + (t * 0.08)),
                                    fontWeight: FontWeight.w500,
                                    height: 1.25,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        top: -1,
                        child: Opacity(
                          opacity: glowStrength,
                          child: MindCoachGlowLine(
                            color: accent,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: -1,
                        child: Opacity(
                          opacity: glowStrength,
                          child: MindCoachGlowLine(
                            color: accent,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
    this.topInset = 0,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onBack;

  /// Status bar / notch inset so the header clears the safe area.
  final double topInset;

  static const double _leadingWidth = 48;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    return Padding(
      padding: EdgeInsets.only(
        top: topInset + 4,
        left: viewPadding.left,
        right: viewPadding.right,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _leadingWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: _leadingWidth,
                      minHeight: 44,
                    ),
                    onPressed: onBack,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 24,
                    ),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              const SizedBox(width: _leadingWidth),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w400,
                ),
          ),
          const SizedBox(height: 10),
          MindCoachGlowLine(color: color, width: 168),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MindCoachGlowCard(
      color: color,
      showTopGlow: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                ),
              ],
            ),
          ),
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
    this.starting = false,
  });

  final Color color;
  final bool expanded;
  final List<MindCoachV2Favorite> favorites;
  final VoidCallback onTap;
  final Future<void> Function(MindCoachV2Favorite favorite) onFavoriteTap;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    return MindCoachGlowCard(
      color: color,
      showTopGlow: true,
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
                  onTap: starting ? null : () => onFavoriteTap(favorite),
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
  final VoidCallback? onTap;

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
                  favorite.contextMode.displayLabel,
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

class _SessionStartCard extends StatelessWidget {
  const _SessionStartCard({
    required this.color,
    required this.session,
    required this.onStart,
    this.starting = false,
  });

  final Color color;
  final MindCoachV2CatalogSession session;
  final VoidCallback onStart;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    return MindCoachGlowCard(
      color: color,
      showTopGlow: true,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            session.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            session.descriptor,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: starting ? null : () => onStart(),
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.22),
                disabledBackgroundColor: color.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: color.withValues(alpha: 0.55)),
                ),
              ),
              child: starting
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: color,
                      ),
                    )
                  : const Text(
                      'Start session',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MindCoachDisclosures extends StatelessWidget {
  const _MindCoachDisclosures();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.42),
          height: 1.45,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        'MindCoach sessions are AI-generated coaching cues grounded in your '
        'round and training data. Review Settings → Legal for privacy and '
        'technical details.',
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}
