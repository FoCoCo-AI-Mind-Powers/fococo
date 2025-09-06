import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/biometric_auth_service.dart';
import '/ai_integration/widgets/navbar_widget.dart';
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
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final BiometricAuthService _biometricService = BiometricAuthService();

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

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
    _loadBiometricSettings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: theme.primaryText,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            '$_biometricName & Security',
            style: theme.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          centerTitle: true,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isBiometricAvailable
                  ? _buildBiometricSettings(theme)
                  : _buildNotAvailableView(theme),
        ),
        bottomNavigationBar: FoCoCoNavBar(
          currentRoute: 'face_id_settings',
          enableVoiceButton: false,
          onTap: (route) => context.goNamed(route),
        ),
      ),
    );
  }

  /// Biometric settings view
  Widget _buildBiometricSettings(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _buildHeaderCard(theme),

          const SizedBox(height: 32),

          // Main biometric toggle
          _buildMainBiometricToggle(theme),

          const SizedBox(height: 24),

          // Security features
          if (_isBiometricEnabled) _buildSecurityFeatures(theme),

          const SizedBox(height: 32),

          // Security tips
          _buildSecurityTips(theme),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Header card with biometric icon
  Widget _buildHeaderCard(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary.withValues(alpha: 0.1),
            theme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
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
          Text(
            _biometricName,
            style: theme.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Secure your FoCoCo experience with biometric authentication',
            textAlign: TextAlign.center,
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Main biometric toggle
  Widget _buildMainBiometricToggle(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.secondaryText.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isBiometricEnabled
                  ? theme.performanceExcellent.withValues(alpha: 0.1)
                  : theme.secondaryText.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getBiometricIcon(),
              color: _isBiometricEnabled
                  ? theme.performanceExcellent
                  : theme.secondaryText,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable $_biometricName',
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use $_biometricName for secure authentication',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isBiometricEnabled,
            onChanged: _toggleBiometric,
            activeColor: theme.performanceExcellent,
          ),
        ],
      ),
    );
  }

  /// Security features section
  Widget _buildSecurityFeatures(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Features',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 16),

        // App lock
        _buildSecurityToggle(
          theme: theme,
          title: 'App Lock',
          subtitle: 'Require $_biometricName to open FoCoCo',
          icon: Icons.lock,
          value: _isAppLockEnabled,
          onChanged: _toggleAppLock,
        ),

        const SizedBox(height: 12),

        // Subscription protection
        _buildSecurityToggle(
          theme: theme,
          title: 'Subscription Protection',
          subtitle: 'Require $_biometricName to manage subscriptions',
          icon: Icons.workspace_premium,
          value: _isSubscriptionProtectionEnabled,
          onChanged: _toggleSubscriptionProtection,
        ),

        const SizedBox(height: 12),

        // Payment protection
        _buildSecurityToggle(
          theme: theme,
          title: 'Payment Protection',
          subtitle: 'Require $_biometricName for payments',
          icon: Icons.payment,
          value: _isPaymentProtectionEnabled,
          onChanged: _togglePaymentProtection,
        ),
      ],
    );
  }

  /// Security toggle widget
  Widget _buildSecurityToggle({
    required FlutterFlowTheme theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.secondaryText.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value
                  ? theme.performanceExcellent.withValues(alpha: 0.1)
                  : theme.secondaryText.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value ? theme.performanceExcellent : theme.secondaryText,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.performanceExcellent,
          ),
        ],
      ),
    );
  }

  /// Security tips section
  Widget _buildSecurityTips(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Tips',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.aiPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.aiPrimary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
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
          ),
        ),
      ],
    );
  }

  /// Security tip item
  Widget _buildTipItem({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.aiPrimary,
          size: 20,
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
    );
  }

  /// Not available view
  Widget _buildNotAvailableView(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          const SizedBox(height: 32),
          Text(
            'Biometric Authentication Unavailable',
            textAlign: TextAlign.center,
            style: theme.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your device doesn\'t support biometric authentication or it\'s not set up. Please set up Face ID, Touch ID, or fingerprint in your device settings.',
            textAlign: TextAlign.center,
            style: theme.bodyLarge.copyWith(
              color: theme.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          FFButtonWidget(
            onPressed: () => context.pop(),
            text: 'Go Back',
            options: FFButtonOptions(
              width: double.infinity,
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
