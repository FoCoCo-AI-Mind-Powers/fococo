import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/glass_components.dart';
import '/services/biometric_auth_service.dart';
import 'dart:ui';
import 'face_id_settings_model.dart';
export 'face_id_settings_model.dart';

class FaceIdSettingsWidget extends StatefulWidget {
  const FaceIdSettingsWidget({super.key});

  static String routeName = 'face_id_settings';
  static String routePath = '/face-id-settings';

  @override
  State<FaceIdSettingsWidget> createState() => _FaceIdSettingsWidgetState();
}

class _FaceIdSettingsWidgetState extends State<FaceIdSettingsWidget>
    with TickerProviderStateMixin {
  late FaceIdSettingsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final BiometricAuthService _biometricService = BiometricAuthService();

  // Animation controllers - matching settings pattern
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isBiometricAvailable = false;
  String _biometricName = 'Biometric Authentication';
  bool _isBiometricEnabled = false;
  bool _isAppLockEnabled = false;
  bool _isSubscriptionProtectionEnabled = false;
  bool _isPaymentProtectionEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FaceIdSettingsModel());

    // Initialize animations - matching settings pattern
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _loadBiometricSettings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricSettings() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final biometricName = await _biometricService.getPrimaryBiometricName();
      final isBiometricEnabled = await _biometricService.isBiometricEnabled();
      final isAppLockEnabled = await _biometricService.isAppLockEnabled();
      final isSubscriptionProtectionEnabled =
          await _biometricService.isSubscriptionProtectionEnabled();
      final isPaymentProtectionEnabled =
          await _biometricService.isPaymentProtectionEnabled();

      setState(() {
        _isBiometricAvailable = isAvailable;
        _biometricName = biometricName;
        _isBiometricEnabled = isBiometricEnabled;
        _isAppLockEnabled = isAppLockEnabled;
        _isSubscriptionProtectionEnabled = isSubscriptionProtectionEnabled;
        _isPaymentProtectionEnabled = isPaymentProtectionEnabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load biometric settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: Stack(
          children: [
            // Main content
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryBackground,
                    theme.secondaryBackground.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Custom App Bar
                        _buildCustomAppBar(theme),

                        // Main Content
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _isBiometricAvailable
                                  ? _buildBiometricSettings(theme)
                                  : _buildNotAvailableView(theme),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          _buildGlassButton(
            theme: theme,
            icon: Icons.arrow_back_ios,
            onTap: () {
              // Try to pop first, if that fails navigate to settings
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.goNamed('settings');
              }
            },
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              '$_biometricName & Security',
              style: theme.headlineSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Settings button
          _buildGlassButton(
            theme: theme,
            icon: Icons.settings_outlined,
            onTap: () => context.goNamed('settings'),
          ),
        ],
      ),
    );
  }

  /// Build glass design button
  Widget _buildGlassButton({
    required FlutterFlowTheme theme,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.glassBackground.withValues(alpha: 0.3),
                  theme.glassTint.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.glassBorder.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.glassShadow.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: theme.primaryText,
              size: icon == Icons.arrow_back_ios ? 20 : 24,
            ),
          ),
        ),
      ),
    );
  }

  /// Biometric settings view
  Widget _buildBiometricSettings(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header section with biometric info
          _buildBiometricHeaderSection(theme),

          const SizedBox(height: 24),

          // Main biometric control
          _buildBiometricControlSection(theme),

          const SizedBox(height: 24),

          // Security features
          if (_isBiometricEnabled) _buildSecurityFeaturesSection(theme),

          const SizedBox(height: 24),

          // Security tips
          _buildSecurityTipsSection(theme),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBiometricHeaderSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: _biometricName,
      subtitle: 'Secure your FoCoCo experience with biometric authentication',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getBiometricIcon(),
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isBiometricEnabled
                    ? theme.performanceExcellent.withValues(alpha: 0.1)
                    : theme.secondaryText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isBiometricEnabled ? 'Active' : 'Inactive',
                style: theme.bodySmall.copyWith(
                  color: _isBiometricEnabled
                      ? theme.performanceExcellent
                      : theme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBiometricControlSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Biometric Authentication',
      subtitle: 'Control your biometric security settings',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            _buildSwitchItem(
              theme,
              _getBiometricIcon(),
              'Enable $_biometricName',
              'Use $_biometricName for secure authentication',
              _isBiometricEnabled,
              _toggleBiometric,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSecurityFeaturesSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Security Features',
      subtitle: 'Configure additional security protections',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),

            // App lock
            _buildSwitchItem(
              theme,
              Icons.lock,
              'App Lock',
              'Require $_biometricName to open FoCoCo',
              _isAppLockEnabled,
              _toggleAppLock,
            ),

            // Subscription protection
            _buildSwitchItem(
              theme,
              Icons.workspace_premium,
              'Subscription Protection',
              'Require $_biometricName to manage subscriptions',
              _isSubscriptionProtectionEnabled,
              _toggleSubscriptionProtection,
            ),

            // Payment protection
            _buildSwitchItem(
              theme,
              Icons.payment,
              'Payment Protection',
              'Require $_biometricName for payments',
              _isPaymentProtectionEnabled,
              _togglePaymentProtection,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSwitchItem(
    FlutterFlowTheme theme,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.labelSmall.copyWith(
            color: theme.secondaryText,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSecurityTipsSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Security Tips',
      subtitle: 'Important information about biometric security',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            _buildTipItem(
              theme: theme,
              icon: Icons.security,
              text:
                  'Biometric data is stored securely on your device and never shared',
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              theme: theme,
              icon: Icons.fingerprint,
              text: 'You can always use your device passcode as a backup',
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              theme: theme,
              icon: Icons.settings,
              text: 'Manage biometric settings in your device Settings app',
            ),
          ],
        )
      ],
    );
  }

  /// Security tip item
  Widget _buildTipItem({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.bodySmall.copyWith(
                color: theme.primaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Not available view
  Widget _buildNotAvailableView(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassDashboardCard(
            title: 'Biometric Authentication Unavailable',
            subtitle:
                'Your device doesn\'t support biometric authentication or it\'s not set up',
            children: [
              Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: theme.secondaryText.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security,
                      color: theme.secondaryText,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Please set up Face ID, Touch ID, or fingerprint in your device settings to enable biometric authentication in FoCoCo.',
                    textAlign: TextAlign.center,
                    style: theme.bodyLarge.copyWith(
                      color: theme.secondaryText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FFButtonWidget(
                      onPressed: () => context.pop(),
                      text: 'Go Back to Settings',
                      options: FFButtonOptions(
                        height: 56,
                        padding: EdgeInsets.zero,
                        iconPadding: EdgeInsets.zero,
                        color: theme.primary,
                        textStyle: theme.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 0,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods

  IconData _getBiometricIcon() {
    if (_biometricName.contains('Face')) {
      return FontAwesomeIcons.faceSmile;
    } else if (_biometricName.contains('Touch') ||
        _biometricName.contains('Fingerprint')) {
      return Icons.fingerprint;
    }
    return Icons.security;
  }

  // Toggle handlers

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Test authentication before enabling
      final result = await _biometricService.authenticate(
        reason: 'Verify your identity to enable $_biometricName',
      );

      if (result.success) {
        await _biometricService.setBiometricEnabled(true);
        setState(() => _isBiometricEnabled = true);
        _showSuccessSnackBar('$_biometricName enabled successfully');
      } else {
        _showErrorSnackBar(result.error ?? 'Failed to enable $_biometricName');
      }
    } else {
      await _biometricService.setBiometricEnabled(false);
      // Disable all dependent features
      await _biometricService.setAppLockEnabled(false);
      await _biometricService.setSubscriptionProtectionEnabled(false);

      setState(() {
        _isBiometricEnabled = false;
        _isAppLockEnabled = false;
        _isSubscriptionProtectionEnabled = false;
      });

      _showSuccessSnackBar('$_biometricName disabled');
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    await _biometricService.setAppLockEnabled(value);
    setState(() => _isAppLockEnabled = value);
    _showSuccessSnackBar(value ? 'App lock enabled' : 'App lock disabled');
  }

  Future<void> _toggleSubscriptionProtection(bool value) async {
    await _biometricService.setSubscriptionProtectionEnabled(value);
    setState(() => _isSubscriptionProtectionEnabled = value);
    _showSuccessSnackBar(value
        ? 'Subscription protection enabled'
        : 'Subscription protection disabled');
  }

  Future<void> _togglePaymentProtection(bool value) async {
    await _biometricService.setPaymentProtectionEnabled(value);
    setState(() => _isPaymentProtectionEnabled = value);
    _showSuccessSnackBar(
        value ? 'Payment protection enabled' : 'Payment protection disabled');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
