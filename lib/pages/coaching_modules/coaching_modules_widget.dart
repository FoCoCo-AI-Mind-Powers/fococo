import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/fococo_ui_components.dart';
import '/ai_integration/widgets/enhanced_navigation_with_voice.dart';
import '/ai_integration/services/ai_coaching_service.dart';

import '/auth/firebase_auth/auth_util.dart';

import 'package:flutter/material.dart';

import 'coaching_modules_model.dart';
export 'coaching_modules_model.dart';

class CoachingModulesWidget extends StatefulWidget {
  const CoachingModulesWidget({super.key});

  static String routeName = 'coaching_modules';
  static String routePath = '/coaching_modules';

  @override
  State<CoachingModulesWidget> createState() => _CoachingModulesWidgetState();
}

class _CoachingModulesWidgetState extends State<CoachingModulesWidget> with TickerProviderStateMixin {
  late CoachingModulesModel _model;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  // AI Coaching Services
  final AICoachingService _aiCoachingService = AICoachingService.instance;
  bool _isLoadingAIRecommendations = false;
  String? _aiRecommendationError;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CoachingModulesModel());
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize animations
    _animationController = AnimationController(
      duration: FlutterFlowTheme.animationGentle,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _loadAIRecommendations();
  }

  /// Load AI-powered coaching recommendations
  Future<void> _loadAIRecommendations() async {
    if (currentUser == null) return;
    
    setState(() {
      _isLoadingAIRecommendations = true;
      _aiRecommendationError = null;
    });

    try {
              await _aiCoachingService.generateCoachingRecommendations(
        userId: currentUser?.uid ?? '',
        includeWeeklyPlan: true,
      );
      
      if (mounted) {
        setState(() {
          _isLoadingAIRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAIRecommendations = false;
          _aiRecommendationError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
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
        backgroundColor: theme.calmBackground,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Enhanced App Bar with Calm-inspired serene design
                _buildCalmInspiredAppBar(theme),
                
                // Tab Content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Mindfulness Library Tab (Calm-inspired)
                      _buildMindfulnessLibraryTab(theme),
                      
                      // Today's Sessions Tab (Calm-inspired)
                      _buildTodaySessionsTab(theme),
                      
                      // Progress & Journey Tab (Calm-inspired)
                      _buildProgressJourneyTab(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Enhanced Bottom Navigation with AI Coaching Integration
        bottomNavigationBar: FoCoCoNavBar(
          currentRoute: 'coaching_modules',
          enableVoiceButton: false, // Only show voice button on Today tab
          onTap: (route) => context.goNamed(route),
        ),
      ),
    );
  }

  /// Enhanced SliverAppBar with Calm-inspired serene design
  Widget _buildCalmInspiredAppBar(FlutterFlowTheme theme) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: theme.calmGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(FlutterFlowTheme.borderRadiusXXL),
              bottomRight: Radius.circular(FlutterFlowTheme.borderRadiusXXL),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(FlutterFlowTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with peaceful greeting
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find Your Center',
                              style: theme.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: FlutterFlowTheme.spacingXS),
                            Text(
                              'Strengthen your mental game with mindful practice',
                              style: theme.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Mindfulness streak indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlutterFlowTheme.spacingM,
                          vertical: FlutterFlowTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusXL),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.spa,
                              color: theme.mentalPeace,
                              size: FlutterFlowTheme.iconSizeS,
                            ),
                            const SizedBox(width: FlutterFlowTheme.spacingS),
                            Text(
                              '7 days',
                              style: theme.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: FlutterFlowTheme.spacingL),
                  
                  // Today's intention
                  Container(
                    padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusL),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.self_improvement,
                            color: Colors.white,
                            size: FlutterFlowTheme.iconSizeM,
                          ),
                        ),
                        const SizedBox(width: FlutterFlowTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Intention',
                                style: theme.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: FlutterFlowTheme.spacingXS),
                              Text(
                                'Cultivate inner stillness and focused awareness',
                                style: theme.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: FlutterFlowTheme.spacingL),
                  
                  // Tab Bar with Calm-inspired design
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusXL),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusXL),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: theme.calmPrimary,
                      unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                      labelStyle: theme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      tabs: const [
                        Tab(text: 'Library'),
                        Tab(text: 'Today'),
                        Tab(text: 'Journey'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mindfulness Library Tab - Calm-inspired content organization
  Widget _buildMindfulnessLibraryTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-Powered Coaching Recommendations
          _buildAICoachingRecommendations(theme),
          
          const SizedBox(height: FlutterFlowTheme.spacingXL),
          
          // Featured Session
          _buildFeaturedSession(theme),
          
          const SizedBox(height: FlutterFlowTheme.spacingXL),
          
          // Categories
          _buildMindfulnessCategories(theme),
          
          const SizedBox(height: FlutterFlowTheme.spacingXL),
          
          // Popular Sessions
          _buildPopularSessions(theme),
        ],
      ),
    );
  }

  /// AI-Powered Coaching Recommendations - Integrated AI Services
  Widget _buildAICoachingRecommendations(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: FlutterFlowTheme.iconSizeM,
              color: theme.aiPrimary,
            ),
            const SizedBox(width: FlutterFlowTheme.spacingS),
            Text(
              'AI Coaching Recommendations',
              style: theme.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
              ),
            ),
            const Spacer(),
            if (_isLoadingAIRecommendations)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        if (_aiRecommendationError != null)
          Container(
            padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
            decoration: BoxDecoration(
              color: theme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
              border: Border.all(color: theme.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: theme.error, size: 20),
                const SizedBox(width: FlutterFlowTheme.spacingS),
                Expanded(
                  child: Text(
                    'Unable to load AI recommendations. Please try again later.',
                    style: theme.bodySmall.copyWith(color: theme.error),
                  ),
                ),
                TextButton(
                  onPressed: _loadAIRecommendations,
                  child: Text('Retry', style: TextStyle(color: theme.error)),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(FlutterFlowTheme.spacingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.aiPrimary.withValues(alpha: 0.1),
                  theme.aiSecondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
              border: Border.all(
                color: theme.aiPrimary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.aiPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: FlutterFlowTheme.iconSizeM,
                      ),
                    ),
                    const SizedBox(width: FlutterFlowTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personalized Mental Training',
                            style: theme.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: FlutterFlowTheme.spacingXS),
                          Text(
                            'AI-powered recommendations based on your performance',
                            style: theme.bodySmall.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: FlutterFlowTheme.spacingM),
                
                // Sample AI recommendations (in a real app, these would come from the AI service)
                _buildAIRecommendationCard(
                  theme,
                  'Focus Enhancement',
                  'Based on your recent rounds, work on sustained attention during pressure situations',
                  'High Priority',
                  Icons.center_focus_strong,
                  theme.mentalFocus,
                ),
                
                const SizedBox(height: FlutterFlowTheme.spacingS),
                
                _buildAIRecommendationCard(
                  theme,
                  'Confidence Building',
                  'Develop pre-shot visualization routines to boost confidence on the tee',
                  'Medium Priority',
                  Icons.self_improvement,
                  theme.mentalStrength,
                ),
                
                const SizedBox(height: FlutterFlowTheme.spacingM),
                
                ElevatedButton.icon(
                  onPressed: () async {
                    // Generate personalized content
                    if (currentUser != null) {
                      try {
                        await _aiCoachingService.generatePersonalizedContent(
                          userId: currentUser?.uid ?? '',
                          contentType: 'lesson',
                          topic: 'mental_game_improvement',
                        );
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('AI coaching content generated!'),
                              backgroundColor: theme.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error generating content: ${e.toString()}'),
                              backgroundColor: theme.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.aiPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusButton),
                    ),
                  ),
                  icon: Icon(Icons.auto_awesome, size: 18),
                  label: Text('Generate Personalized Plan'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build individual AI recommendation card
  Widget _buildAIRecommendationCard(
    FlutterFlowTheme theme,
    String title,
    String description,
    String priority,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: FlutterFlowTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priority.contains('High') 
                            ? theme.error.withValues(alpha: 0.1)
                            : theme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        priority,
                        style: theme.bodySmall.copyWith(
                          color: priority.contains('High') ? theme.error : theme.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FlutterFlowTheme.spacingXS),
                Text(
                  description,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Featured Session - Calm-inspired hero content
  Widget _buildFeaturedSession(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Session',
          style: theme.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        FoCoCoMindfulnessCard(
          title: 'Pre-Round Preparation',
          description: 'A guided meditation to center your mind and prepare for peak performance on the course.',
          duration: '12 min',
          sessionType: 'meditation',
          progress: 0.0,
          backgroundImage: 'assets/images/meditation-bg.jpg',
          onTap: () {
            // TODO: Navigate to featured session
          },
        ),
      ],
    );
  }

  /// Mindfulness Categories - Calm-inspired organization
  Widget _buildMindfulnessCategories(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore by Category',
          style: theme.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          mainAxisSpacing: FlutterFlowTheme.spacingM,
          crossAxisSpacing: FlutterFlowTheme.spacingM,
          children: [
            _buildCategoryCard(
              theme,
              'Focus',
              Icons.center_focus_strong,
              theme.mentalFocus,
              'Enhance concentration and clarity',
            ),
            _buildCategoryCard(
              theme,
              'Calm',
              Icons.spa,
              theme.mentalCalm,
              'Find inner peace and stillness',
            ),
            _buildCategoryCard(
              theme,
              'Confidence',
              Icons.psychology,
              theme.mentalStrength,
              'Build unshakeable self-belief',
            ),
            _buildCategoryCard(
              theme,
              'Breathing',
              Icons.air,
              theme.breathingActive,
              'Master the power of breath',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    FlutterFlowTheme theme,
    String title,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.calmCardBackground,
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
        boxShadow: [theme.coachingModuleShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to category
          },
          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
          child: Padding(
            padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: FlutterFlowTheme.iconSizeL,
                    color: color,
                  ),
                ),
                const SizedBox(height: FlutterFlowTheme.spacingM),
                Text(
                  title,
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: FlutterFlowTheme.spacingS),
                Text(
                  description,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Popular Sessions - Calm-inspired content list
  Widget _buildPopularSessions(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Popular Sessions',
              style: theme.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all sessions
              },
              child: Text(
                'View All',
                style: theme.bodyMedium.copyWith(
                  color: theme.calmPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        FoCoCoMindfulnessCard(
          title: 'Mindful Putting',
          description: 'Develop present-moment awareness for consistent putting performance.',
          duration: '8 min',
          sessionType: 'focus',
          progress: 0.6,
          onTap: () {
            // TODO: Navigate to session
          },
        ),
        
        FoCoCoMindfulnessCard(
          title: 'Pressure Management',
          description: 'Stay calm and composed during high-pressure situations on the course.',
          duration: '15 min',
          sessionType: 'meditation',
          progress: 0.3,
          onTap: () {
            // TODO: Navigate to session
          },
        ),
        
        FoCoCoMindfulnessCard(
          title: 'Breathing for Golf',
          description: 'Learn rhythmic breathing techniques to enhance your swing tempo.',
          duration: '10 min',
          sessionType: 'breathing',
          progress: 0.0,
          onTap: () {
            // TODO: Navigate to session
          },
        ),
      ],
    );
  }

  /// Today's Sessions Tab - Calm-inspired daily practice
  Widget _buildTodaySessionsTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Mindfulness Practice
          _buildDailyPractice(theme),
          
          const SizedBox(height: FlutterFlowTheme.spacingXL),
          
          // Breathing Exercise
          _buildTodaysBreathing(theme),
          
          const SizedBox(height: FlutterFlowTheme.spacingXL),
          
          // Recommended for Today
          _buildTodaysRecommendations(theme),
        ],
      ),
    );
  }

  /// Daily Practice - Calm-inspired daily routine
  Widget _buildDailyPractice(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Practice',
          style: theme.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingS),
        
        Text(
          'Your personalized mindfulness routine',
          style: theme.bodyMedium.copyWith(
            color: theme.secondaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        Container(
          padding: const EdgeInsets.all(FlutterFlowTheme.spacingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.calmPrimary.withValues(alpha: 0.1),
                theme.calmSecondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
            border: Border.all(
              color: theme.calmPrimary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.calmPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.self_improvement,
                      color: Colors.white,
                      size: FlutterFlowTheme.iconSizeM,
                    ),
                  ),
                  const SizedBox(width: FlutterFlowTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Morning Centering',
                          style: theme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: FlutterFlowTheme.spacingXS),
                        Text(
                          '5 minutes • Not started',
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Start morning practice
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.calmPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusButton),
                      ),
                    ),
                    child: Text('Start'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Today's Breathing Exercise
  Widget _buildTodaysBreathing(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breathing Exercise',
          style: theme.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingS),
        
        Text(
          'Practice mindful breathing to center yourself',
          style: theme.bodyMedium.copyWith(
            color: theme.secondaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        FoCoCoBreathingWidget(
          duration: 180,
          inhaleTime: 4,
          holdTime: 4,
          exhaleTime: 4,
          onStart: () {
            // TODO: Track breathing session start
          },
          onStop: () {
            // TODO: Track breathing session stop
          },
          onComplete: () {
            // TODO: Track breathing session completion
          },
        ),
      ],
    );
  }

  /// Today's Recommendations
  Widget _buildTodaysRecommendations(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: theme.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingS),
        
        Text(
          'Based on your progress and goals',
          style: theme.bodyMedium.copyWith(
            color: theme.secondaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        FoCoCoMindfulnessCard(
          title: 'Confidence Building',
          description: 'Strengthen your mental resilience and self-belief through guided visualization.',
          duration: '12 min',
          sessionType: 'meditation',
          progress: 0.0,
          onTap: () {
            // TODO: Navigate to session
          },
        ),
      ],
    );
  }

  /// Progress & Journey Tab - Calm-inspired progress tracking
  Widget _buildProgressJourneyTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Journey Overview
          _buildJourneyOverview(theme),
          
          const SizedBox(height: FlutterFlowTheme.spacingXL),
          
          // Weekly Progress
          _buildWeeklyProgress(theme),
          
          const SizedBox(height: FlutterFlowTheme.spacingXL),
          
          // Achievements
          _buildMindfulnessAchievements(theme),
        ],
      ),
    );
  }

  /// Journey Overview - Calm-inspired progress summary
  Widget _buildJourneyOverview(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Mindfulness Journey',
          style: theme.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        Container(
          padding: const EdgeInsets.all(FlutterFlowTheme.spacingL),
          decoration: BoxDecoration(
            gradient: theme.mindfulnessGradient,
            borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.spa,
                      color: Colors.white,
                      size: FlutterFlowTheme.iconSizeL,
                    ),
                  ),
                  const SizedBox(width: FlutterFlowTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '127 minutes',
                          style: theme.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: FlutterFlowTheme.spacingXS),
                        Text(
                          'Total practice time',
                          style: theme.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: FlutterFlowTheme.spacingL),
              
              Row(
                children: [
                  Expanded(
                    child: _buildJourneyStatCard(theme, '15', 'Sessions\nCompleted'),
                  ),
                  const SizedBox(width: FlutterFlowTheme.spacingM),
                  Expanded(
                    child: _buildJourneyStatCard(theme, '7', 'Day\nStreak'),
                  ),
                  const SizedBox(width: FlutterFlowTheme.spacingM),
                  Expanded(
                    child: _buildJourneyStatCard(theme, '3', 'Skills\nUnlocked'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyStatCard(FlutterFlowTheme theme, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: FlutterFlowTheme.spacingXS),
          Text(
            label,
            style: theme.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Weekly Progress - Calm-inspired progress tracking
  Widget _buildWeeklyProgress(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: theme.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        Container(
          padding: const EdgeInsets.all(FlutterFlowTheme.spacingL),
          decoration: BoxDecoration(
            color: theme.calmCardBackground,
            borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
            boxShadow: [theme.coachingModuleShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Weekly Goal',
                    style: theme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '5 of 7 days',
                    style: theme.bodyMedium.copyWith(
                      color: theme.calmPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: FlutterFlowTheme.spacingM),
              
              LinearProgressIndicator(
                value: 5 / 7,
                backgroundColor: theme.calmPrimary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(theme.calmPrimary),
                minHeight: 8,
              ),
              
              const SizedBox(height: FlutterFlowTheme.spacingM),
              
              Text(
                'Practice mindfulness for 5 minutes each day',
                style: theme.bodyMedium.copyWith(
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mindfulness Achievements
  Widget _buildMindfulnessAchievements(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: theme.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        Row(
          children: [
            Expanded(
                             child: _buildAchievementCard(
                 theme,
                 'First Steps',
                 Icons.directions_walk,
                 'Completed your first session',
                 true,
               ),
            ),
            const SizedBox(width: FlutterFlowTheme.spacingM),
            Expanded(
              child: _buildAchievementCard(
                theme,
                'Consistent',
                Icons.timeline,
                '7 days in a row',
                true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: FlutterFlowTheme.spacingM),
        
        Row(
          children: [
            Expanded(
              child: _buildAchievementCard(
                theme,
                'Focused',
                Icons.center_focus_strong,
                'Master focus techniques',
                false,
              ),
            ),
            const SizedBox(width: FlutterFlowTheme.spacingM),
            Expanded(
              child: _buildAchievementCard(
                theme,
                'Calm Mind',
                Icons.spa,
                'Complete 30 sessions',
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementCard(
    FlutterFlowTheme theme,
    String title,
    IconData icon,
    String description,
    bool isEarned,
  ) {
    return Container(
      padding: const EdgeInsets.all(FlutterFlowTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.calmCardBackground,
        borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
        boxShadow: [theme.coachingModuleShadow],
        border: isEarned ? Border.all(
          color: theme.calmPrimary.withValues(alpha: 0.3),
          width: 2,
        ) : null,
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEarned ? theme.calmPrimary : theme.calmMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: FlutterFlowTheme.iconSizeM,
            ),
          ),
          const SizedBox(height: FlutterFlowTheme.spacingS),
          Text(
            title,
            style: theme.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isEarned ? theme.primaryText : theme.secondaryText,
            ),
          ),
          const SizedBox(height: FlutterFlowTheme.spacingXS),
          Text(
            description,
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Enhanced Bottom Navigation with Calm-inspired design
  Widget _buildCalmInspiredBottomNav(FlutterFlowTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.calmCardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FlutterFlowTheme.spacingL,
            vertical: FlutterFlowTheme.spacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(theme, 'Home', Icons.home, false, () {}),
              _buildNavItem(theme, 'Training', Icons.spa, true, () {}),
              _buildNavItem(theme, 'Progress', Icons.trending_up, false, () {}),
              _buildNavItem(theme, 'Profile', Icons.person, false, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    FlutterFlowTheme theme,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FlutterFlowTheme.spacingM,
          vertical: FlutterFlowTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isActive ? theme.calmPrimary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: FlutterFlowTheme.iconSizeM,
              color: isActive ? theme.calmPrimary : theme.secondaryText,
            ),
            const SizedBox(height: FlutterFlowTheme.spacingXS),
            Text(
              label,
              style: theme.bodySmall.copyWith(
                color: isActive ? theme.calmPrimary : theme.secondaryText,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 