import 'package:flutter/material.dart';

import '/ai_integration/widgets/navbar_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/glass_components.dart';
import '/pages/fococo_tab/fococo_tab_widget.dart';
import '/services/support_submission_service.dart';
import 'support_submission_model.dart';

export 'support_submission_model.dart';

class SupportSubmissionWidget extends StatefulWidget {
  const SupportSubmissionWidget({
    super.key,
    required this.type,
  });

  final SupportSubmissionType type;

  static const String reportBugRouteName = 'report_bug';
  static const String reportBugRoutePath = '/report-bug';
  static const String sendFeedbackRouteName = 'send_feedback';
  static const String sendFeedbackRoutePath = '/send-feedback';

  /// Full-page bug/feedback form. Uses root [Navigator] so it works from the
  /// tab shell without requiring a GoRouter hot restart after route changes.
  static Future<void> open(BuildContext context, SupportSubmissionType type) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: type == SupportSubmissionType.bug
              ? reportBugRouteName
              : sendFeedbackRouteName,
        ),
        builder: (_) => SupportSubmissionWidget(type: type),
      ),
    );
  }

  @override
  State<SupportSubmissionWidget> createState() =>
      _SupportSubmissionWidgetState();
}

class _SupportSubmissionWidgetState extends State<SupportSubmissionWidget> {
  late SupportSubmissionModel _model;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  bool _submitted = false;

  bool get _isBug => widget.type == SupportSubmissionType.bug;

  String get _pageTitle => _isBug ? 'Report a Bug' : 'Send Feedback';

  String get _pageSubtitle =>
      _isBug ? 'Tell us what went wrong' : 'Share your thoughts with the team';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportSubmissionModel());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _exitPage() {
    if (!mounted) return;
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (rootNav.canPop()) {
      rootNav.pop();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(FoCoCoTabWidget.routeName);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await SupportSubmissionService.submit(
        type: widget.type,
        title: _isBug ? _titleController.text : null,
        message: _messageController.text,
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ArgumentError
                ? e.message ?? 'Please check your message and try again.'
                : 'Could not submit. Check your connection and try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exitPage();
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          backgroundColor: theme.primaryBackground,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FoCoCoInlineScreenHeader(
                  title: _pageTitle,
                  subtitle: _pageSubtitle,
                  leading: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 44,
                    ),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: theme.primaryText,
                      size: 20,
                    ),
                    tooltip: 'Back',
                    onPressed: _exitPage,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: _submitted
                        ? _buildSuccessState(theme)
                        : _buildForm(theme),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Thank you',
      subtitle: _isBug
          ? 'Your bug report was received.'
          : 'Your feedback was received.',
      children: [
        const SizedBox(height: 16),
        Text(
          _isBug
              ? 'Our team will review your report and follow up at '
                  '${currentUserEmail.isNotEmpty ? currentUserEmail : 'your account email'} '
                  'if we need more detail.'
              : 'We read every message. Thanks for helping us improve FoCoCo.',
          style: theme.bodyMedium.copyWith(
            color: theme.secondaryText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        FFButtonWidget(
          onPressed: _exitPage,
          text: 'Done',
          options: FFButtonOptions(
            width: double.infinity,
            height: 52,
            color: theme.primary,
            textStyle: theme.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(FlutterFlowTheme theme) {
    return Form(
      key: _formKey,
      child: GlassDashboardCard(
        title: _pageTitle,
        subtitle: _isBug
            ? 'Include what you expected and what happened instead.'
            : 'What is working well? What could be better?',
        children: [
          const SizedBox(height: 16),
          if (_isBug) ...[
            TextFormField(
              controller: _titleController,
              style: theme.bodyMedium.copyWith(color: theme.primaryText),
              decoration: _inputDecoration(
                theme,
                label: 'Short summary (optional)',
                hint: 'e.g. GolfChat voice stops mid-sentence',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _messageController,
            minLines: _isBug ? 6 : 5,
            maxLines: _isBug ? 10 : 8,
            style: theme.bodyMedium.copyWith(color: theme.primaryText),
            decoration: _inputDecoration(
              theme,
              label: _isBug ? 'Describe the bug' : 'Your feedback',
              hint: _isBug
                  ? 'What were you doing? What happened?'
                  : 'Share your thoughts…',
            ),
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.length < 10) {
                return 'Please enter at least 10 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FFButtonWidget(
            onPressed: _isSubmitting ? null : _submit,
            text: _isSubmitting ? 'Submitting…' : 'Submit',
            options: FFButtonOptions(
              width: double.infinity,
              height: 52,
              color: theme.primary,
              textStyle: theme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    FlutterFlowTheme theme, {
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: theme.labelMedium.copyWith(color: theme.secondaryText),
      hintStyle: theme.bodySmall.copyWith(
        color: theme.secondaryText.withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: theme.secondaryBackground.withValues(alpha: 0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.alternate.withValues(alpha: 0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.alternate.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
