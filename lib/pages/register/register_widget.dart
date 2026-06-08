import '/ai_integration/widgets/navbar_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'age_verification_widget.dart';
import 'account_created_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'register_model.dart';
export 'register_model.dart';

// ─── Age-threshold helper ───────────────────────────────────────────────────

int _getAgeThreshold() => 16;

// ─── Locale-based pricing string ─────────────────────────────────────────────

String _getPricingString(String? countryCode) {
  switch (countryCode?.toUpperCase()) {
    case 'GB':
      return '14-day free trial. Then £8.75 a month, billed annually at £105.';
    case 'DE':
    case 'FR':
    case 'NL':
    case 'IE':
    case 'PT':
    case 'ES':
    case 'IT':
    case 'BE':
    case 'AT':
    case 'FI':
    case 'GR':
    case 'LU':
    case 'SK':
    case 'SI':
    case 'EE':
    case 'LV':
    case 'LT':
    case 'CY':
    case 'MT':
      return '14-day free trial. Then €10 a month, billed annually at €120.';
    default:
      return '14-day free trial. Then \$10 a month, billed annually at \$120.';
  }
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class RegisterWidget extends StatefulWidget {
  const RegisterWidget({super.key});

  static String routeName = 'register';
  static String routePath = '/register';

  @override
  State<RegisterWidget> createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  late RegisterModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // DOB state
  int _selectedMonthIndex = 0;
  int _selectedDayIndex = 0;
  int _selectedYearIndex = 0;
  bool _monthTouched = false;
  bool _dayTouched = false;
  bool _yearTouched = false;

  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _yearController;

  late final List<int> _years;

  // Terms
  bool _termsAccepted = false;

  // Email validation state (shown below field)
  String? _emailError;
  String? _passwordError;

  // Loading
  bool _isLoading = false;

  // Month names
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  bool get _isValidEmail {
    final email = _model.emailTextController?.text.trim() ?? '';
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  bool get _isValidPassword {
    final pw = _model.passwordTextController?.text ?? '';
    return pw.length >= 8;
  }

  bool get _canContinue =>
      _isValidEmail &&
      _isValidPassword &&
      _monthTouched &&
      _dayTouched &&
      _yearTouched &&
      _termsAccepted;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegisterModel());

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();
    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    // Add listeners to rebuild when text changes (for button enable state)
    _model.emailTextController?.addListener(() => setState(() {}));
    _model.passwordTextController?.addListener(() => setState(() {}));

    // Build year list: oldest (1920) → current year
    final currentYear = DateTime.now().year;
    _years = List.generate(currentYear - 1920 + 1, (i) => 1920 + i);

    // Start year wheel near 1990 for practical usability
    final startYearIndex = _years.indexOf(1990).clamp(0, _years.length - 1);

    _monthController = FixedExtentScrollController();
    _dayController = FixedExtentScrollController();
    _yearController = FixedExtentScrollController(initialItem: startYearIndex);
    _selectedYearIndex = startYearIndex;

    // ListWheelScrollView only calls onSelectedItemChanged after user scrolls.
    // Without this, the visible defaults (Jan 1 / year wheel position) never
    // set the *_touched flags and Continue stays permanently disabled.
    _monthTouched = true;
    _dayTouched = true;
    _yearTouched = true;
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    _model.dispose();
    super.dispose();
  }

  DateTime get _selectedDate {
    return DateTime(
      _years[_selectedYearIndex],
      _selectedMonthIndex + 1,
      _selectedDayIndex + 1,
    );
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _onContinue() async {
    // Validate fields and show inline errors
    setState(() {
      _emailError = _isValidEmail ? null : 'Enter a valid email address';
      _passwordError =
          _isValidPassword ? null : 'Password must be at least 8 characters';
    });

    if (!_canContinue) return;

    // Age check — BEFORE any Firebase call
    final age = _calculateAge(_selectedDate);
    final threshold = _getAgeThreshold();

    if (age < threshold) {
      // Navigate to age block — zero data stored
      context.goNamed(AgeVerificationWidget.routeName);
      return;
    }

    // Create account
    setState(() => _isLoading = true);
    try {
      GoRouter.of(context).prepareAuthEvent();

      final user = await authManager.createAccountWithEmail(
        context,
        _model.emailTextController!.text.trim(),
        _model.passwordTextController!.text,
      );

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Store user document in Firestore (DOB, terms, and initial fields)
      final uid = user.uid;
      await FirebaseFirestore.instance.collection('user').doc(uid).set({
        'email': user.email ?? '',
        'displayName': 'Golfer',
        'profileImageUrl': '',
        'createdTime': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'currentMembershipTier': 'junior',
        'mandatoryPaywallCompleted': false,
        'onboardingCompleted': false,
        'dateOfBirth': Timestamp.fromDate(_selectedDate),
        'termsAcceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      GoRouter.of(context).clearRedirectLocation();
      context.goNamed(AccountCreatedWidget.routeName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final countryCode = Localizations.localeOf(context).countryCode;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: buildFoCoCoAppBar(
          context,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon:
                const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Create Account',
            style: theme.headlineSmall.override(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    24, 24, 24, bottomPadding + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email field
                    _buildTextField(
                      controller: _model.emailTextController!,
                      focusNode: _model.emailFocusNode!,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      obscure: false,
                      suffixIcon: null,
                      theme: theme,
                    ),
                    if (_emailError != null) _buildFieldError(_emailError!),

                    _buildGlowDivider(),

                    const SizedBox(height: 16),

                    // Password field
                    _buildTextField(
                      controller: _model.passwordTextController!,
                      focusNode: _model.passwordFocusNode!,
                      hintText: 'Password',
                      keyboardType: TextInputType.visiblePassword,
                      obscure: !_model.passwordVisibility,
                      suffixIcon: InkWell(
                        onTap: () => setState(
                          () => _model.passwordVisibility =
                              !_model.passwordVisibility,
                        ),
                        child: Icon(
                          _model.passwordVisibility
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ),
                      theme: theme,
                    ),
                    if (_passwordError != null)
                      _buildFieldError(_passwordError!),

                    _buildGlowDivider(),

                    const SizedBox(height: 24),

                    // DOB picker section
                    Text(
                      'Date of birth:',
                      style: theme.bodyMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildDobPicker(theme),

                    const SizedBox(height: 24),

                    // Terms checkbox
                    _buildTermsRow(theme),

                    const SizedBox(height: 28),

                    // Continue button
                    _buildContinueButton(theme),

                    const SizedBox(height: 20),

                    // Pricing text
                    Text(
                      _getPricingString(countryCode),
                      textAlign: TextAlign.center,
                      style: theme.bodySmall.override(
                        fontFamily: 'Inter',
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'No credit card required',
                      textAlign: TextAlign.center,
                      style: theme.bodySmall.override(
                        fontFamily: 'Inter',
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DOB picker ─────────────────────────────────────────────────────────────

  Widget _buildDobPicker(FlutterFlowTheme theme) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Month column
          Expanded(
            flex: 3,
            child: _buildWheelColumn(
              items: _months,
              selectedIndex: _monthTouched ? _selectedMonthIndex : null,
              controller: _monthController,
              label: 'Month',
              onChanged: (i) => setState(() {
                _selectedMonthIndex = i;
                _monthTouched = true;
              }),
            ),
          ),
          _buildColumnDivider(),
          // Day column
          Expanded(
            flex: 2,
            child: _buildWheelColumn(
              items: List.generate(31, (i) => (i + 1).toString()),
              selectedIndex: _dayTouched ? _selectedDayIndex : null,
              controller: _dayController,
              label: 'Day',
              onChanged: (i) => setState(() {
                _selectedDayIndex = i;
                _dayTouched = true;
              }),
            ),
          ),
          _buildColumnDivider(),
          // Year column
          Expanded(
            flex: 2,
            child: _buildWheelColumn(
              items: _years.map((y) => y.toString()).toList(),
              selectedIndex: _yearTouched ? _selectedYearIndex : null,
              controller: _yearController,
              label: 'Year',
              onChanged: (i) => setState(() {
                _selectedYearIndex = i;
                _yearTouched = true;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildWheelColumn({
    required List<String> items,
    required int? selectedIndex,
    required FixedExtentScrollController controller,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        // Column header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.06),
        ),
        // Wheel
        Expanded(
          child: Stack(
            children: [
              // Center highlight band
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: selectedIndex != null
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.08)
                          : Colors.transparent,
                      border: selectedIndex != null
                          ? Border.symmetric(
                              horizontal: BorderSide(
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.25),
                                width: 1,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 36,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                diameterRatio: 2.5,
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: items.length,
                  builder: (context, index) {
                    final isSelected =
                        selectedIndex != null && selectedIndex == index;
                    return Center(
                      child: Text(
                        items[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          fontSize: isSelected ? 15 : 13,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Terms row ───────────────────────────────────────────────────────────────

  Widget _buildTermsRow(FlutterFlowTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _termsAccepted,
            onChanged: (val) => setState(() => _termsAccepted = val ?? false),
            activeColor: const Color(0xFF4CAF50),
            checkColor: Colors.white,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Wrap(
            children: [
              Text(
                'I agree to ',
                style: theme.bodyMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () => _openUrl('https://www.fococo.ai/terms'),
                child: Text(
                  'Terms of Service',
                  style: theme.bodyMedium.override(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
              Text(
                ' and ',
                style: theme.bodyMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () => _openUrl('https://www.fococo.ai/privacy-policy'),
                child: Text(
                  'Privacy Policy',
                  style: theme.bodyMedium.override(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Continue button ─────────────────────────────────────────────────────────

  Widget _buildContinueButton(FlutterFlowTheme theme) {
    final enabled = _canContinue && !_isLoading;

    return GestureDetector(
      onTap: enabled ? _onContinue : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? const Color(0xFF4CAF50)
                : Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
          color: enabled
              ? const Color(0xFF1A3320).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.03),
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Continue',
                  style: TextStyle(
                    color:
                        enabled ? Colors.white : Colors.white.withValues(alpha: 0.35),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Shared helpers ──────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required TextInputType keyboardType,
    required bool obscure,
    required Widget? suffixIcon,
    required FlutterFlowTheme theme,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 15,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: Color(0xFF4CAF50),
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
      ),
    );
  }

  Widget _buildFieldError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, bottom: 4),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFFF8A65),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildGlowDivider() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF4CAF50),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
