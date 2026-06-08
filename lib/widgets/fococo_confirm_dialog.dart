import 'dart:ui';

import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

enum FoCoCoDialogAccent { primary, destructive }

const Color _kDialogSurface = Color(0xFF1A1030);
const Color _kDialogGreen = Color(0xFF4CAF50);

/// Glass-backed confirmation dialog matching FoCoCo dark UI.
Future<bool> showFoCoCoConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
  IconData? icon,
  FoCoCoDialogAccent accent = FoCoCoDialogAccent.primary,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _FoCoCoDialogShell(
      child: _FoCoCoDialogBody(
        title: title,
        message: message,
        icon: icon,
        accent: accent,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        onCancel: () => Navigator.of(ctx).pop(false),
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    ),
  );
  return result == true;
}

/// Account deletion with typed DELETE confirmation.
Future<bool> showFoCoCoDeleteAccountDialog(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _FoCoCoDialogShell(
      child: StatefulBuilder(
        builder: (ctx, setDialogState) {
          final canDelete =
              controller.text.trim().toUpperCase() == 'DELETE';
          return _FoCoCoDialogBody(
            title: 'Delete your FoCoCo account?',
            message:
                'This permanently deletes your account and FoCoCo data. '
                'This cannot be undone.\n\nType DELETE to confirm.',
            icon: Icons.delete_outline_rounded,
            accent: FoCoCoDialogAccent.destructive,
            cancelLabel: 'Cancel',
            confirmLabel: 'Delete Account',
            confirmEnabled: canDelete,
            onCancel: () => Navigator.of(ctx).pop(false),
            onConfirm: canDelete ? () => Navigator.of(ctx).pop(true) : null,
            extraContent: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: controller,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _dialogInputDecoration(hintText: 'DELETE'),
                onChanged: (_) => setDialogState(() {}),
              ),
            ),
          );
        },
      ),
    ),
  );
  controller.dispose();
  return result == true;
}

/// Single-action informational dialog (e.g. change password hint).
Future<void> showFoCoCoAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  String okLabel = 'OK',
  IconData? icon,
  bool barrierDismissible = true,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _FoCoCoDialogShell(
      child: _FoCoCoDialogBody(
        title: title,
        message: message,
        icon: icon ?? Icons.info_outline_rounded,
        accent: FoCoCoDialogAccent.primary,
        cancelLabel: okLabel,
        confirmLabel: '',
        showCancelOnly: true,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

InputDecoration _dialogInputDecoration({required String hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kDialogGreen, width: 1.5),
    ),
  );
}

class _FoCoCoDialogShell extends StatelessWidget {
  const _FoCoCoDialogShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kDialogSurface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FoCoCoDialogBody extends StatelessWidget {
  const _FoCoCoDialogBody({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.icon,
    this.accent = FoCoCoDialogAccent.primary,
    this.confirmEnabled = true,
    this.extraContent,
    this.showCancelOnly = false,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final IconData? icon;
  final FoCoCoDialogAccent accent;
  final bool confirmEnabled;
  final Widget? extraContent;
  final bool showCancelOnly;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accentColor = accent == FoCoCoDialogAccent.destructive
        ? theme.error
        : _kDialogGreen;
    final iconBg = accentColor.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: theme.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              title,
              style: theme.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          if (icon == null) const SizedBox(height: 4),
          const SizedBox(height: 14),
          Text(
            message,
            style: theme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.55,
              fontSize: 15,
            ),
          ),
          if (extraContent != null) extraContent!,
          const SizedBox(height: 22),
          if (showCancelOnly)
            Align(
              alignment: Alignment.centerRight,
              child: _FoCoCoDialogButton(
                label: cancelLabel,
                filled: true,
                color: _kDialogGreen,
                onPressed: onCancel,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _FoCoCoDialogButton(
                    label: cancelLabel,
                    filled: false,
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FoCoCoDialogButton(
                    label: confirmLabel,
                    filled: true,
                    color: accentColor,
                    onPressed: confirmEnabled ? onConfirm : null,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FoCoCoDialogButton extends StatelessWidget {
  const _FoCoCoDialogButton({
    required this.label,
    required this.filled,
    required this.onPressed,
    this.color,
  });

  final String label;
  final bool filled;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    if (filled) {
      final bg = enabled
          ? (color ?? _kDialogGreen)
          : Colors.white.withValues(alpha: 0.08);
      final fg = enabled ? Colors.white : Colors.white.withValues(alpha: 0.35);
      return Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: enabled
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.35),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
