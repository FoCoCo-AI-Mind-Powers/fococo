import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/services/profile_service.dart';
import 'edit_profile_model.dart';
export 'edit_profile_model.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';

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
  bool _isLoadingLocation = false;
  bool _isLoadingTimezones = false;

  // Profile service
  final _profileService = ProfileService();

  // Data
  String? _profileImageUrl;
  XFile? _selectedImage;
  List<GolfClub> _nearbyClubs = [];
  List<TimezoneInfo> _timezones = [];
  GolfClub? _selectedClub;
  TimezoneInfo? _selectedTimezone;
  Position? _userPosition;

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
    _loadLocationData();
    _loadTimezones();
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
        _profileImageUrl = userData.profileImageUrl;
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

  Future<void> _loadLocationData() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      _userPosition = await _profileService.getCurrentLocation();
      if (_userPosition != null) {
        final clubs =
            await _profileService.searchNearbyGolfClubs(_userPosition!);
        if (mounted) {
          setState(() {
            _nearbyClubs = clubs;
          });
        }
      }
    } catch (e) {
      print('Error loading location data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _loadTimezones() async {
    setState(() {
      _isLoadingTimezones = true;
    });

    try {
      final timezones =
          await _profileService.getTimezonesOrderedByLocation(_userPosition);
      if (mounted) {
        setState(() {
          _timezones = timezones;
        });
      }
    } catch (e) {
      print('Error loading timezones: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTimezones = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _profileService.pickImage();
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || !loggedIn) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? imageUrl = _profileImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        imageUrl = await _profileService.uploadProfileImage(
            currentUserUid, _selectedImage!);
      }

      final updates = <String, dynamic>{
        'displayName': _displayNameController.text.trim(),
        'handicap': double.tryParse(_handicapController.text) ?? 0.0,
        'homeClub': _selectedClub?.name ?? _homeClubController.text.trim(),
        'timezone': _selectedTimezone?.name ?? _timezoneController.text.trim(),
      };

      if (imageUrl != null) {
        updates['profileImageUrl'] = imageUrl;
      }

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
            _buildEnhancedGlassCard(
              theme: theme,
              title: 'Personal Information',
              subtitle: 'Update your basic details',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  const SizedBox(height: 20),

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

                  const SizedBox(height: 20),

                  // Email (read-only)
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    readOnly: true,
                    validator: null,
                  ),

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 20),

                  // Home Club Dropdown
                  _buildClubDropdown(theme),

                  const SizedBox(height: 20),

                  // Timezone Dropdown
                  _buildTimezoneDropdown(theme),
                ],
              ),
            ),

            const SizedBox(height: 100), // Space for navbar
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.glassBackground.withValues(alpha: 0.25),
                  theme.glassBackground.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primary.withValues(alpha: 0.2),
                            theme.secondary.withValues(alpha: 0.2)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.photo_camera_rounded,
                        color: theme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Photo',
                            style: theme.headlineSmall.copyWith(
                              color: theme.primaryText,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update your profile picture',
                            style: theme.bodySmall.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Profile image
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
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
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: _buildProfileImage(theme),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Change photo button
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primary.withValues(alpha: 0.2),
                          theme.secondary.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: theme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Change Photo',
                          style: theme.labelLarge.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(FlutterFlowTheme theme) {
    if (_selectedImage != null) {
      return FutureBuilder<Uint8List>(
        future: _selectedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            );
          } else {
            return _buildDefaultAvatar(theme);
          }
        },
      );
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return Image.network(
        _profileImageUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(theme);
        },
      );
    } else {
      return _buildDefaultAvatar(theme);
    }
  }

  Widget _buildDefaultAvatar(FlutterFlowTheme theme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary.withValues(alpha: 0.1),
            theme.secondary.withValues(alpha: 0.1)
          ],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  Widget _buildEnhancedGlassCard({
    required FlutterFlowTheme theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.glassBackground.withValues(alpha: 0.25),
                  theme.glassBackground.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primary.withValues(alpha: 0.2),
                            theme.secondary.withValues(alpha: 0.2)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: theme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.headlineSmall.copyWith(
                              color: theme.primaryText,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
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
                  ],
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClubDropdown(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: theme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Home Club',
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isLoadingLocation) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.glassBackground.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.glassBorder.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: DropdownButtonFormField<GolfClub>(
            value: _selectedClub,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              hintText: _nearbyClubs.isEmpty
                  ? 'Loading clubs...'
                  : 'Select a golf club',
              hintStyle: theme.bodyMedium.copyWith(
                color: theme.secondaryText.withValues(alpha: 0.7),
              ),
            ),
            style: theme.bodyMedium.copyWith(
              color: theme.primaryText,
            ),
            dropdownColor: theme.secondaryBackground,
            items: _nearbyClubs.map((club) {
              return DropdownMenuItem<GolfClub>(
                value: club,
                child: SizedBox(
                  height: club.address.isNotEmpty ? 50 : 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        club.name,
                        style: theme.bodyMedium.copyWith(
                          color: theme.primaryText,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (club.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${club.address} • ${club.distance.toStringAsFixed(1)} km',
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (GolfClub? club) {
              setState(() {
                _selectedClub = club;
                if (club != null) {
                  _homeClubController.text = club.name;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimezoneDropdown(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time_outlined,
              color: theme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Timezone',
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isLoadingTimezones) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.glassBackground.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.glassBorder.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: DropdownButtonFormField<TimezoneInfo>(
            value: _selectedTimezone,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              hintText: _timezones.isEmpty
                  ? 'Loading timezones...'
                  : 'Select timezone',
              hintStyle: theme.bodyMedium.copyWith(
                color: theme.secondaryText.withValues(alpha: 0.7),
              ),
            ),
            style: theme.bodyMedium.copyWith(
              color: theme.primaryText,
            ),
            dropdownColor: theme.secondaryBackground,
            items: _timezones.take(50).map((timezone) {
              // Limit to first 50 for performance
              return DropdownMenuItem<TimezoneInfo>(
                value: timezone,
                child: Text(
                  timezone.toString(),
                  style: theme.bodyMedium.copyWith(
                    color: theme.primaryText,
                  ),
                ),
              );
            }).toList(),
            onChanged: (TimezoneInfo? timezone) {
              setState(() {
                _selectedTimezone = timezone;
                if (timezone != null) {
                  _timezoneController.text = timezone.name;
                }
              });
            },
          ),
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: theme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          style: theme.bodyMedium.copyWith(
            color: theme.primaryText,
          ),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: readOnly
                ? theme.alternate.withValues(alpha: 0.1)
                : theme.glassBackground.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.glassBorder.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.glassBorder.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.primary.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.error,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
