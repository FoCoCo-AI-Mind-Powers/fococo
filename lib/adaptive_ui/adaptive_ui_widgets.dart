/// FoCoCo-themed wrappers for adaptive_platform_ui widgets.
/// Applies FlutterFlowTheme colors and typography for consistent branding.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

/// FoCoCo-themed adaptive button. Wraps [AdaptiveButton] with brand colors.
class FoCoCoAdaptiveButton extends StatelessWidget {
  const FoCoCoAdaptiveButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.style = AdaptiveButtonStyle.filled,
    this.size = AdaptiveButtonSize.medium,
    this.color,
    this.textColor,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final AdaptiveButtonStyle style;
  final AdaptiveButtonSize size;
  final Color? color;
  final Color? textColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final child = AdaptiveButton(
      onPressed: enabled ? onPressed : null,
      label: label,
      style: style,
      size: size,
      color: color ?? (style == AdaptiveButtonStyle.filled ? theme.primary : null),
      textColor: textColor ?? (style == AdaptiveButtonStyle.filled ? theme.primaryText : theme.primary),
      enabled: enabled,
    );
    return _ConstrainAdaptiveChild(child: child);
  }
}

/// FoCoCo-themed adaptive button with icon. Wraps [AdaptiveButton.child].
class FoCoCoAdaptiveButtonIcon extends StatelessWidget {
  const FoCoCoAdaptiveButtonIcon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.style = AdaptiveButtonStyle.filled,
    this.size = AdaptiveButtonSize.medium,
    this.color,
    this.iconColor,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final AdaptiveButtonStyle style;
  final AdaptiveButtonSize size;
  final Color? color;
  final Color? iconColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final effectiveColor = iconColor ?? (style == AdaptiveButtonStyle.filled ? theme.primaryText : theme.primary);
    final child = AdaptiveButton.child(
      onPressed: enabled ? onPressed : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: effectiveColor),
          const SizedBox(width: 8),
          Text(label, style: theme.labelLarge.copyWith(color: effectiveColor)),
        ],
      ),
      style: style,
      size: size,
      color: color ?? (style == AdaptiveButtonStyle.filled ? theme.primary : null),
      enabled: enabled,
    );
    return _ConstrainAdaptiveChild(child: child);
  }
}

/// FoCoCo-themed adaptive icon-only button. Wraps [AdaptiveButton.icon].
class FoCoCoAdaptiveIconButton extends StatelessWidget {
  const FoCoCoAdaptiveIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.iconColor,
    this.style = AdaptiveButtonStyle.filled,
    this.size = AdaptiveButtonSize.medium,
    this.enabled = true,
    this.loadingChild,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final Color? color;
  final Color? iconColor;
  final AdaptiveButtonStyle style;
  final AdaptiveButtonSize size;
  final bool enabled;
  final Widget? loadingChild;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final effectiveEnabled = enabled && !isLoading;
    final Widget button;
    if (isLoading && loadingChild != null) {
      button = AdaptiveButton.child(
        onPressed: null,
        child: loadingChild!,
        style: style,
        size: size,
        color: color ?? theme.secondary,
        enabled: false,
      );
    } else {
      final effectiveIconColor = iconColor ?? (style == AdaptiveButtonStyle.filled ? theme.primaryText : theme.primary);
      button = AdaptiveButton.child(
        onPressed: effectiveEnabled ? onPressed : null,
        child: Icon(icon, size: 22, color: effectiveIconColor),
        style: style,
        size: size,
        color: color ?? (style == AdaptiveButtonStyle.filled ? theme.secondary : null),
        enabled: effectiveEnabled,
      );
    }
    return _ConstrainAdaptiveChild(child: button);
  }
}

/// FoCoCo-themed adaptive text field. Applies theme-based style and decoration.
class FoCoCoAdaptiveTextField extends StatelessWidget {
  const FoCoCoAdaptiveTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.keyboardType,
    this.textInputAction,
    this.style,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.decoration,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? decoration;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final effectiveDecoration = decoration ??
        InputDecoration(
          hintText: placeholder,
          hintStyle: theme.bodySmall.copyWith(color: theme.secondaryText),
          filled: true,
          fillColor: theme.secondaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusInput),
            borderSide: BorderSide(color: theme.alternate.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusInput),
            borderSide: BorderSide(color: theme.alternate.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FlutterFlowTheme.borderRadiusInput),
            borderSide: BorderSide(color: theme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        );
    return AdaptiveTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: style ?? theme.bodyMedium.copyWith(color: theme.primaryText),
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      inputFormatters: inputFormatters,
      decoration: effectiveDecoration,
      prefix: prefix,
      suffix: suffix,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }
}

/// FoCoCo-themed adaptive switch. Uses primary color when active.
class FoCoCoAdaptiveSwitch extends StatelessWidget {
  const FoCoCoAdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.thumbColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? thumbColor;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdaptiveSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? theme.primary,
      thumbColor: thumbColor,
    );
  }
}

/// FoCoCo-themed adaptive card. Uses theme background and border radius.
class FoCoCoAdaptiveCard extends StatelessWidget {
  const FoCoCoAdaptiveCard({
    super.key,
    required this.child,
    this.color,
    this.elevation,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final Color? color;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final card = AdaptiveCard(
      color: color ?? theme.secondaryBackground,
      elevation: elevation ?? FlutterFlowTheme.elevationXS,
      padding: padding ?? const EdgeInsets.all(FlutterFlowTheme.spacingM),
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
      child: child,
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(FlutterFlowTheme.borderRadiusCard),
          child: card,
        ),
      );
    }
    return card;
  }
}

/// Ensures [AdaptiveButton] (and native UiKitView) never receives infinite constraints.
class _ConstrainAdaptiveChild extends StatelessWidget {
  const _ConstrainAdaptiveChild({required this.child});

  static const double _kMaxFallbackWidth = 400;
  static const double _kMaxFallbackHeight = 56;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : _kMaxFallbackWidth;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : _kMaxFallbackHeight;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: w, maxHeight: h),
          child: child,
        );
      },
    );
  }
}
