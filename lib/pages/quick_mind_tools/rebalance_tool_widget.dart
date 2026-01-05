import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'rebalance_tool_painter.dart';
import 'rebalance_tool_model.dart';
export 'rebalance_tool_model.dart';

class RebalanceToolWidget extends StatefulWidget {
  const RebalanceToolWidget({Key? key}) : super(key: key);

  static const String routeName = 'rebalance_tool';
  static const String routePath = '/rebalance_tool';

  @override
  State<RebalanceToolWidget> createState() => _RebalanceToolWidgetState();
}

class _RebalanceToolWidgetState extends State<RebalanceToolWidget>
    with TickerProviderStateMixin {
  late RebalanceToolModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _balanceController;
  late AnimationController _fadeController;
  List<BalanceElement> _elements = [];
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RebalanceToolModel());

    _balanceController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _initializeElements();
    _startTime = DateTime.now();
    _startTimer();
  }

  void _initializeElements() {
    _elements = [
      BalanceElement(x: -0.8, y: -0.3, size: 12, opacity: 0.8),
      BalanceElement(x: 0.8, y: -0.3, size: 12, opacity: 0.8),
      BalanceElement(x: -0.6, y: 0.5, size: 10, opacity: 0.7),
      BalanceElement(x: 0.6, y: 0.5, size: 10, opacity: 0.7),
    ];
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _startTime != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
        _startTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _fadeController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.warning.withValues(alpha: 0.3),
              theme.warning.withValues(alpha: 0.1),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.safePop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rebalance',
                            style: theme.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Find your equilibrium',
                            style: theme.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _formatDuration(_elapsedTime),
                        style: theme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Balance visualization
              Expanded(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Stack(
                    children: [
                      // Balance animation
                      AnimatedBuilder(
                        animation: _balanceController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: RebalanceBalancePainter(
                              balanceProgress: _balanceController.value,
                              color: theme.warning,
                              elements: _elements,
                            ),
                            size: MediaQuery.of(context).size,
                          );
                        },
                      ),
                      
                      // Content overlay
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.balance,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Find Balance',
                                style: theme.displaySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Visualize yourself finding perfect balance between mind, body, and game',
                                style: theme.bodyLarge.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
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
    );
  }
}

