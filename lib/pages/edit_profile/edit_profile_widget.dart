import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/enhanced_navbar_widget.dart';
import 'edit_profile_model.dart';
export 'edit_profile_model.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileWidget extends StatefulWidget {
  const EditProfileWidget({Key? key}) : super(key: key);

  static const String routeName = 'edit_profile';
  static const String routePath = '/edit-profile';

  @override
  State<EditProfileWidget> createState() => _EditProfileWidgetState();
}

class _EditProfileWidgetState extends State<EditProfileWidget>
    with TickerProviderStateMixin {
  late EditProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _handicapController = TextEditingController();
  final _homeClubController = TextEditingController();
  final _timezoneController = TextEditingController();

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Loading state
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditProfileModel());

    // Initialize animations
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

    // Load user data
    _loadUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _handicapController.dispose();
    _homeClubController.dispose();
    _timezoneController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!loggedIn) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();

      if (userDoc.exists && mounted) {
        final userData = UserRecord.fromSnapshot(userDoc);

        _displayNameController.text = userData.displayName;
        _emailController.text = userData.email;
        _handicapController.text = userData.handicap.toString();
        _homeClubController.text = userData.homeClub;
        _timezoneController.text = userData.timezone;
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile data'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || !loggedIn) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updates = <String, dynamic>{
        'displayName': _displayNameController.text.trim(),
        'handicap': double.tryParse(_handicapController.text) ?? 0.0,
        'homeClub': _homeClubController.text.trim(),
        'timezone': _timezoneController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: FlutterFlowTheme.of(context).success,
          ),
        );

        // Navigate back to profile
        context.goNamed('profile');
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
                              ? _buildLoadingState(theme)
                              : _buildEditForm(theme),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Voice Button
            const FloatingVoiceButton(),
          ],
        ),
        bottomNavigationBar: EnhancedFoCoCoNavBar(
          currentRoute: 'profile',
          onTap: (route) {
            print(
                '🔄 Edit Profile page: Navigation requested to route: $route');
            context.goNamed(route);
          },
          currentUser: null,
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
          GestureDetector(
            onTap: () => context.goNamed('profile'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.glassBackground.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.glassBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: theme.primaryText,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'Edit Profile',
              style: theme.headlineSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Save button
          GestureDetector(
            onTap: _isSaving ? null : _saveProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save',
                      style: theme.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Profile Image Section
            _buildProfileImageSection(theme),

            const SizedBox(height: 32),

            // Personal Information
            GlassDashboardCard(
              title: 'Personal Information',
              subtitle: 'Update your basic details',
              children: [
                Column(
                  children: [
                    const SizedBox(height: 16),

                    // Display Name
                    _buildTextField(
                      controller: _displayNameController,
                      label: 'Display Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Display name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email (read-only)
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      readOnly: true,
                      validator: null,
                    ),

                    const SizedBox(height: 16),

                    // Handicap
                    _buildTextField(
                      controller: _handicapController,
                      label: 'Handicap',
                      icon: Icons.golf_course_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final handicap = double.tryParse(value);
                          if (handicap == null) {
                            return 'Please enter a valid handicap';
                          }
                          if (handicap < -10 || handicap > 54) {
                            return 'Handicap must be between -10 and 54';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Home Club
                    _buildTextField(
                      controller: _homeClubController,
                      label: 'Home Club',
                      icon: Icons.location_on_outlined,
                      validator: null,
                    ),

                    const SizedBox(height: 16),

                    // Timezone
                    _buildTextField(
                      controller: _timezoneController,
                      label: 'Timezone',
                      icon: Icons.access_time_outlined,
                      validator: null,
                    ),
                  ],
                )
              ],
            ),

            const SizedBox(height: 100), // Space for navbar
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Profile Photo',
      subtitle: 'Update your profile picture',
      children: [
        Column(
          children: [
            const SizedBox(height: 20),

            // Profile image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Change photo button
            GestureDetector(
              onTap: () {
                // TODO: Implement image picker
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Photo upload coming soon!'),
                    backgroundColor: theme.primary,
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: theme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Change Photo',
                      style: theme.labelMedium.copyWith(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      style: theme.bodyMedium.copyWith(
        color: theme.primaryText,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.bodyMedium.copyWith(
          color: theme.secondaryText,
        ),
        prefixIcon: Icon(
          icon,
          color: theme.primary,
          size: 22,
        ),
        filled: true,
        fillColor: readOnly
            ? theme.alternate.withValues(alpha: 0.1)
            : theme.glassBackground.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.error,
            width: 2,
          ),
        ),
      ),
    );
  }
}
