import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Grint-Style Golf Round Entry Modal
class GolfRoundModalGrintStyle extends StatefulWidget {
  final FlutterFlowTheme theme;

  const GolfRoundModalGrintStyle({required this.theme, super.key});

  @override
  State<GolfRoundModalGrintStyle> createState() => _GolfRoundModalGrintStyleState();
}

class _GolfRoundModalGrintStyleState extends State<GolfRoundModalGrintStyle> {
  // Score and Putts
  int _score = 5;
  int _putts = 2;
  
  // Tee Shot
  String _teeShotDirection = 'center';
  String _teeShotClub = 'Driver';
  bool _teeShotMisHit = false;
  
  // Putt Distance
  int? _firstPuttDistance;
  
  // Bunkers
  bool _fairwayBunker = false;
  bool _greenSideBunker = false;
  
  // Penalties
  bool _hazardWater = false;
  bool _dropShot = false;
  bool _outOfBounds = false;
  
  // Drinks
  bool _drinksOnHole = false;
  
  // Mode
  bool _isAdvancedMode = true;
  
  bool _isSubmitting = false;
  
  String _selectedTeeBox = 'White';
  
  // Get current user initials for avatar
  String get _userInitials {
    // You can get user name from UserRecord if needed
    return 'G';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: widget.theme.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.theme.secondaryText.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header with Player Info
          _buildPlayerHeader(),
          
          // Scrollable Content Area (everything between Enter button and Basic/Advanced)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score and Putts Section
                  _buildScorePuttsSection(),
                  
                  // Tee Shot Section
                  _buildTeeShotSection(),
                  
                  // 1st Putt Distance and Tee Shot Club
                  _buildPuttAndClubSection(),
                  
                  // Bunkers, Penalties, Drinks Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBunkersSection(),
                        const SizedBox(height: 20),
                        _buildPenaltiesSection(),
                        const SizedBox(height: 20),
                        _buildDrinksSection(),
                        const SizedBox(height: 20), // Extra padding at bottom
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Mode Toggle and Enter Button
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Player Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: widget.theme.primaryBrandGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _userInitials,
                style: widget.theme.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Player', // Replace with actual user name
                  style: widget.theme.titleMedium.copyWith(
                    color: widget.theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '[5]', // Handicap or current score
                  style: widget.theme.bodySmall.copyWith(
                    color: widget.theme.secondaryText,
                  ),
                ),
                Text(
                  'E 4', // Score relative to par
                  style: widget.theme.bodySmall.copyWith(
                    color: widget.theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          // Enhanced Enter Button
          _buildEnhancedEnterButton(),
        ],
      ),
    );
  }

  Widget _buildEnhancedEnterButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return GestureDetector(
          onTap: _isSubmitting ? null : _submitRound,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // Golden-orange gradient with glow effect
                  Color.lerp(
                    const Color(0xFFFF8C42), // Golden orange
                    const Color(0xFFFF6B35), // Deeper orange
                    value,
                  )!,
                  Color.lerp(
                    const Color(0xFFFF6B35), // Deeper orange
                    const Color(0xFFFF8C42), // Golden orange
                    value,
                  )!,
                ],
              ),
              boxShadow: [
                // Outer glow
                BoxShadow(
                  color: const Color(0xFFFF8C42).withValues(alpha: 0.4 * value),
                  blurRadius: 20 * value,
                  spreadRadius: 2 * value,
                  offset: const Offset(0, 4),
                ),
                // Inner glow
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3 * value),
                  blurRadius: 10 * value,
                  spreadRadius: -2 * value,
                ),
                // Depth shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Enter',
                                style: widget.theme.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScorePuttsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildNumberControl(
              label: 'Score',
              value: _score,
              onDecrement: () => setState(() => _score = (_score > 1) ? _score - 1 : 1),
              onIncrement: () => setState(() => _score = _score + 1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildNumberControl(
              label: 'Putts',
              value: _putts,
              onDecrement: () => setState(() => _putts = (_putts > 1) ? _putts - 1 : 1),
              onIncrement: () => setState(() => _putts = _putts + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberControl({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.glassTint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.glassBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: widget.theme.bodySmall.copyWith(
              color: widget.theme.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: widget.theme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                value.toString(),
                style: widget.theme.headlineMedium.copyWith(
                  color: widget.theme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onIncrement,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add,
                    color: widget.theme.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeeShotSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tee Shot',
                style: widget.theme.titleSmall.copyWith(
                  color: widget.theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_teeShotMisHit)
                GestureDetector(
                  onTap: () => setState(() => _teeShotMisHit = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.theme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.theme.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'X Mis-Hit',
                      style: widget.theme.bodySmall.copyWith(
                        color: widget.theme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Circular Directional Control
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.theme.glassTint.withValues(alpha: 0.1),
                border: Border.all(
                  color: widget.theme.glassBorder.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Center HIT button
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _teeShotDirection = 'center'),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _teeShotDirection == 'center'
                              ? widget.theme.primaryBrandGradient
                              : LinearGradient(
                                  colors: [
                                    widget.theme.glassTint.withValues(alpha: 0.2),
                                    widget.theme.glassTint.withValues(alpha: 0.1),
                                  ],
                                ),
                          border: Border.all(
                            color: widget.theme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'HIT',
                            style: widget.theme.titleMedium.copyWith(
                              color: _teeShotDirection == 'center'
                                  ? Colors.white
                                  : widget.theme.primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Directional arrows (simplified - you can add more precise positioning)
                  _buildDirectionButton('up', Icons.arrow_upward, Alignment.topCenter),
                  _buildDirectionButton('down', Icons.arrow_downward, Alignment.bottomCenter),
                  _buildDirectionButton('left', Icons.arrow_back, Alignment.centerLeft),
                  _buildDirectionButton('right', Icons.arrow_forward, Alignment.centerRight),
                  _buildDirectionButton('topLeft', Icons.arrow_upward, Alignment.topLeft),
                  _buildDirectionButton('topRight', Icons.arrow_upward, Alignment.topRight),
                  _buildDirectionButton('bottomLeft', Icons.arrow_downward, Alignment.bottomLeft),
                  _buildDirectionButton('bottomRight', Icons.arrow_downward, Alignment.bottomRight),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!_teeShotMisHit)
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _teeShotMisHit = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.theme.glassTint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.theme.glassBorder.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'X Mis-Hit',
                    style: widget.theme.bodySmall.copyWith(
                      color: widget.theme.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(String direction, IconData icon, Alignment alignment) {
    final isSelected = _teeShotDirection == direction;
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: GestureDetector(
          onTap: () => setState(() => _teeShotDirection = direction),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? widget.theme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? widget.theme.primary
                    : widget.theme.glassBorder.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected
                  ? widget.theme.primary
                  : widget.theme.secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPuttAndClubSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectorControl(
              label: '1st Putt Distance',
              value: _firstPuttDistance?.toString() ?? '--',
              onTap: () => _showPuttDistancePicker(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSelectorControl(
              label: 'Tee Shot Club',
              value: _teeShotClub,
              onTap: () => _showClubPicker(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorControl({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.theme.glassTint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: widget.theme.bodySmall.copyWith(
                color: widget.theme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: widget.theme.bodyLarge.copyWith(
                    color: widget.theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: widget.theme.secondaryText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBunkersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bunkers',
          style: widget.theme.titleSmall.copyWith(
            color: widget.theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildIconButton(
                label: 'Fairway Bunker',
                icon: FontAwesomeIcons.hillRockslide,
                isSelected: _fairwayBunker,
                onTap: () => setState(() => _fairwayBunker = !_fairwayBunker),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIconButton(
                label: 'Green Side',
                icon: FontAwesomeIcons.golfBallTee,
                isSelected: _greenSideBunker,
                onTap: () => setState(() => _greenSideBunker = !_greenSideBunker),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPenaltiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Penalties',
          style: widget.theme.titleSmall.copyWith(
            color: widget.theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildIconButton(
                label: 'Hazard / Water',
                icon: FontAwesomeIcons.water,
                isSelected: _hazardWater,
                onTap: () => setState(() => _hazardWater = !_hazardWater),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIconButton(
                label: 'Drop Shot',
                icon: FontAwesomeIcons.arrowRotateLeft,
                isSelected: _dropShot,
                onTap: () => setState(() => _dropShot = !_dropShot),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIconButton(
                label: 'Out of Bounds',
                icon: FontAwesomeIcons.ban,
                isSelected: _outOfBounds,
                onTap: () => setState(() => _outOfBounds = !_outOfBounds),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drinks',
          style: widget.theme.titleSmall.copyWith(
            color: widget.theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildIconButton(
          label: 'On This Hole',
          icon: FontAwesomeIcons.mugSaucer,
          isSelected: _drinksOnHole,
          onTap: () => setState(() => _drinksOnHole = !_drinksOnHole),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.theme.primary.withValues(alpha: 0.1)
              : widget.theme.glassTint.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? widget.theme.primary.withValues(alpha: 0.3)
                : widget.theme.glassBorder.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? widget.theme.primary
                  : widget.theme.secondaryText,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: widget.theme.bodySmall.copyWith(
                color: isSelected
                    ? widget.theme.primary
                    : widget.theme.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: widget.theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAdvancedMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isAdvancedMode
                      ? widget.theme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !_isAdvancedMode
                        ? widget.theme.primary
                        : widget.theme.glassBorder.withValues(alpha: 0.2),
                    width: !_isAdvancedMode ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Basic',
                    style: widget.theme.bodyMedium.copyWith(
                      color: !_isAdvancedMode
                          ? widget.theme.primary
                          : widget.theme.secondaryText,
                      fontWeight: !_isAdvancedMode ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAdvancedMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isAdvancedMode
                      ? widget.theme.success.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isAdvancedMode
                        ? widget.theme.success
                        : widget.theme.glassBorder.withValues(alpha: 0.2),
                    width: _isAdvancedMode ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Advanced',
                    style: widget.theme.bodyMedium.copyWith(
                      color: _isAdvancedMode
                          ? widget.theme.success
                          : widget.theme.secondaryText,
                      fontWeight: _isAdvancedMode ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPuttDistancePicker() async {
    // Simple implementation - you can enhance this
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Putt Distance'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 50,
            itemBuilder: (context, index) {
              final distance = index + 1;
              return ListTile(
                title: Text('$distance ft'),
                onTap: () => Navigator.pop(context, distance),
              );
            },
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() => _firstPuttDistance = result);
    }
  }

  Future<void> _showClubPicker() async {
    final clubs = ['Driver', '3 Wood', '5 Wood', 'Hybrid', '3 Iron', '4 Iron', '5 Iron', '6 Iron', '7 Iron', '8 Iron', '9 Iron', 'PW', 'SW', 'LW', 'Putter'];
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Club'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.4,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              final club = clubs[index];
              return ListTile(
                title: Text(club),
                onTap: () => Navigator.pop(context, club),
              );
            },
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() => _teeShotClub = result);
    }
  }

  Future<void> _submitRound() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);

    try {
      final roundData = {
        'userId': currentUserUid,
        'date': DateTime.now(),
        'courseName': 'Golf Course', // Default course name
        'teeBox': _selectedTeeBox,
        'score': _score,
        'parTotal': 72, // Default par
        'scoreToPar': _score - 72,
        'totalPutts': _putts,
        'teeShotDirection': _teeShotDirection,
        'teeShotClub': _teeShotClub,
        'teeShotMisHit': _teeShotMisHit,
        'firstPuttDistance': _firstPuttDistance,
        'fairwayBunker': _fairwayBunker,
        'greenSideBunker': _greenSideBunker,
        'hazardWater': _hazardWater,
        'dropShot': _dropShot,
        'outOfBounds': _outOfBounds,
        'drinksOnHole': _drinksOnHole,
        'createdTime': DateTime.now(),
        'updatedTime': DateTime.now(),
        'isValid': true,
      };

      await GolfRoundsRecord.collection.add(roundData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Round saved successfully!'),
            backgroundColor: widget.theme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving round: $e'),
            backgroundColor: widget.theme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

