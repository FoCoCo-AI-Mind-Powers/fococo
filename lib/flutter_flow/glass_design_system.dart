/// FoCoCo Glassmorphism Design System
/// Modern 3D Glass Cards with Advanced Visual Effects
/// Based on reference design with enhanced AI integration

import 'package:flutter/material.dart';
import 'dart:ui';
import 'flutter_flow_theme.dart';

/// Enhanced Glassmorphism Design System for FoCoCo
class GlassDesignSystem {
  // Glass Material Properties
  static const double glassBlur = 20.0;
  static const double glassOpacity = 0.15;
  static const double glassBorderOpacity = 0.25;
  static const double glassElevation = 8.0;
  
  // 3D Transform Properties
  static const double cardTiltAngle = 0.02;
  static const double hoverScale = 1.02;
  static const double pressScale = 0.98;
  
  // Animation Durations
  static const Duration hoverDuration = Duration(milliseconds: 200);
  static const Duration pressDuration = Duration(milliseconds: 100);
  static const Duration cardFlipDuration = Duration(milliseconds: 600);
  
  /// Glass Material Background with Blur Effect
  static Widget glassBackground({
    required Widget child,
    double? opacity,
    double? blur,
    Color? tintColor,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur ?? glassBlur,
          sigmaY: blur ?? glassBlur,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: (tintColor ?? Colors.white).withValues(alpha: opacity ?? glassOpacity),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: glassBorderOpacity),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
  
  /// Advanced 3D Glass Card with Enhanced Effects
  static Widget glass3DCard({
    required Widget child,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? tintColor,
    double? elevation,
    bool enableHover = true,
    bool enable3D = true,
    Duration? animationDuration,
  }) {
    return _Glass3DCardWidget(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin ?? const EdgeInsets.all(8),
      onTap: onTap,
      onLongPress: onLongPress,
      tintColor: tintColor,
      elevation: elevation ?? glassElevation,
      enableHover: enableHover,
      enable3D: enable3D,
      animationDuration: animationDuration ?? hoverDuration,
      child: child,
    );
  }
  
  /// Glass Navigation Bar
  static Widget glassBottomNavBar({
    required List<GlassNavItem> items,
    required int currentIndex,
    required Function(int) onTap,
    FlutterFlowTheme? theme,
  }) {
    return _GlassBottomNavBarWidget(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
      theme: theme,
    );
  }
  
  /// Glass App Bar
  static PreferredSizeWidget glassAppBar({
    String? title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    double? elevation,
    FlutterFlowTheme? theme,
  }) {
    return _GlassAppBarWidget(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      elevation: elevation ?? glassElevation,
      theme: theme,
    );
  }
  
  /// Glass Button with Enhanced Effects
  static Widget glassButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    double? width,
    double? height,
    Color? color,
    Color? textColor,
    FlutterFlowTheme? theme,
    bool isLoading = false,
  }) {
    return _GlassButtonWidget(
      text: text,
      onPressed: onPressed,
      icon: icon,
      width: width,
      height: height,
      color: color,
      textColor: textColor,
      theme: theme,
      isLoading: isLoading,
    );
  }
  
  /// Glass Input Field
  static Widget glassTextField({
    String? hintText,
    String? labelText,
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    FlutterFlowTheme? theme,
  }) {
    return _GlassTextFieldWidget(
      hintText: hintText,
      labelText: labelText,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onSuffixTap: onSuffixTap,
      theme: theme,
    );
  }
  
  /// Glass Modal/Dialog
  static Future<T?> showGlassModal<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.3),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: glassBackground(
            borderRadius: BorderRadius.circular(24),
            child: builder(context),
          ),
        ),
      ),
    );
  }
}

/// Glass Navigation Item
class GlassNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color? color;
  
  const GlassNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.color,
  });
}

/// Internal 3D Glass Card Widget Implementation
class _Glass3DCardWidget extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? tintColor;
  final double elevation;
  final bool enableHover;
  final bool enable3D;
  final Duration animationDuration;
  
  const _Glass3DCardWidget({
    required this.child,
    this.width,
    this.height,
    required this.padding,
    required this.margin,
    this.onTap,
    this.onLongPress,
    this.tintColor,
    required this.elevation,
    this.enableHover = true,
    this.enable3D = true,
    required this.animationDuration,
  });
  
  @override
  State<_Glass3DCardWidget> createState() => _Glass3DCardWidgetState();
}

class _Glass3DCardWidgetState extends State<_Glass3DCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<Matrix4> _transformAnimation;
  
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _pressController = AnimationController(
      duration: GlassDesignSystem.pressDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: GlassDesignSystem.hoverScale,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 1.5,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    _transformAnimation = Tween<Matrix4>(
      begin: Matrix4.identity(),
      end: widget.enable3D
          ? (Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(GlassDesignSystem.cardTiltAngle)
            ..rotateY(GlassDesignSystem.cardTiltAngle))
          : Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    super.dispose();
  }
  
  void _onHover(bool isHovered) {
    if (!widget.enableHover) return;
    
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }
  
  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _pressController.forward();
  }
  
  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
    widget.onTap?.call();
  }
  
  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onLongPress: widget.onLongPress,
          child: AnimatedBuilder(
            animation: Listenable.merge([_hoverController, _pressController]),
            builder: (context, child) {
              double scale = _scaleAnimation.value;
              if (_isPressed) {
                scale *= GlassDesignSystem.pressScale;
              }
              
              return Transform.scale(
                scale: scale,
                child: Transform(
                  alignment: Alignment.center,
                  transform: _transformAnimation.value,
                  child: Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: _elevationAnimation.value,
                          offset: Offset(0, _elevationAnimation.value / 2),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: _elevationAnimation.value / 2,
                          offset: Offset(-1, -1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: GlassDesignSystem.glassBlur,
                          sigmaY: GlassDesignSystem.glassBlur,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (widget.tintColor ?? Colors.white)
                                    .withValues(alpha: GlassDesignSystem.glassOpacity + 0.05),
                                (widget.tintColor ?? Colors.white)
                                    .withValues(alpha: GlassDesignSystem.glassOpacity),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: GlassDesignSystem.glassBorderOpacity),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: widget.padding,
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Glass Bottom Navigation Bar Implementation
class _GlassBottomNavBarWidget extends StatelessWidget {
  final List<GlassNavItem> items;
  final int currentIndex;
  final Function(int) onTap;
  final FlutterFlowTheme? theme;
  
  const _GlassBottomNavBarWidget({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? FlutterFlowTheme.of(context);
    
    return Container(
      height: 80,
      margin: const EdgeInsets.all(16),
      child: GlassDesignSystem.glassBackground(
        borderRadius: BorderRadius.circular(25),
        tintColor: effectiveTheme.primaryBackground,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == currentIndex;
            
            return GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: GlassDesignSystem.hoverDuration,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? effectiveTheme.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected && item.activeIcon != null
                          ? item.activeIcon!
                          : item.icon,
                      color: isSelected
                          ? effectiveTheme.primary
                          : effectiveTheme.secondaryText,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: effectiveTheme.labelSmall.override(
                        color: isSelected
                            ? effectiveTheme.primary
                            : effectiveTheme.secondaryText,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Glass App Bar Implementation
class _GlassAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final FlutterFlowTheme? theme;
  
  const _GlassAppBarWidget({
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    required this.elevation,
    this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? FlutterFlowTheme.of(context);
    
    return GlassDesignSystem.glassBackground(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      tintColor: effectiveTheme.primaryBackground,
      child: AppBar(
        title: title != null
            ? Text(
                title!,
                style: effectiveTheme.headlineSmall.override(
                  color: effectiveTheme.primaryText,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              )
            : null,
        centerTitle: centerTitle,
        leading: leading,
        actions: actions,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: effectiveTheme.primaryText),
      ),
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Glass Button Implementation
class _GlassButtonWidget extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final double? width;
  final double? height;
  final Color? color;
  final Color? textColor;
  final FlutterFlowTheme? theme;
  final bool isLoading;
  
  const _GlassButtonWidget({
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.height,
    this.color,
    this.textColor,
    this.theme,
    this.isLoading = false,
  });
  
  @override
  State<_GlassButtonWidget> createState() => _GlassButtonWidgetState();
}

class _GlassButtonWidgetState extends State<_GlassButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: GlassDesignSystem.pressDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: GlassDesignSystem.pressScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? FlutterFlowTheme.of(context);
    final buttonColor = widget.color ?? effectiveTheme.primary;
    final textColor = widget.textColor ?? Colors.white;
    
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        if (!widget.isLoading) {
          widget.onPressed();
        }
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    buttonColor.withValues(alpha: 0.9),
                    buttonColor.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(textColor),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    color: textColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  widget.text,
                                  style: effectiveTheme.titleSmall.override(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
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
      ),
    );
  }
}

/// Glass Text Field Implementation
class _GlassTextFieldWidget extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final FlutterFlowTheme? theme;
  
  const _GlassTextFieldWidget({
    this.hintText,
    this.labelText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? FlutterFlowTheme.of(context);
    
    return GlassDesignSystem.glassBackground(
      borderRadius: BorderRadius.circular(12),
      tintColor: effectiveTheme.primaryBackground,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: effectiveTheme.bodyMedium.override(
          color: effectiveTheme.primaryText,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          hintStyle: effectiveTheme.bodyMedium.override(
            color: effectiveTheme.secondaryText,
            height: 1.4,
          ),
          labelStyle: effectiveTheme.bodyMedium.override(
            color: effectiveTheme.secondaryText,
            height: 1.4,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: effectiveTheme.secondaryText,
                  size: 20,
                )
              : null,
          suffixIcon: suffixIcon != null
              ? GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(
                    suffixIcon,
                    color: effectiveTheme.secondaryText,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}