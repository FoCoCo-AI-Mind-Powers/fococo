#!/usr/bin/env python3

import os
import re

def fix_file(filepath, fixes):
    """Apply a list of fixes to a file."""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        for pattern, replacement in fixes:
            content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
        
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed: {filepath}")
    except Exception as e:
        print(f"Error fixing {filepath}: {e}")

# Fix unused imports in AI integration files
ai_files = [
    'lib/ai_integration/ai_client.dart',
    'lib/ai_integration/examples/cartesia_demo_widget.dart',
    'lib/ai_integration/index.dart',
    'lib/ai_integration/models/ai_models.dart',
    'lib/ai_integration/models/audio_intelligence_models.dart',
    'lib/ai_integration/models/gemini_models.dart',
    'lib/ai_integration/services/ai_coaching_service.dart',
    'lib/ai_integration/services/ai_cost_tracker.dart',
    'lib/ai_integration/services/ai_insight_service.dart',
    'lib/ai_integration/services/audio_intelligence_service.dart',
    'lib/ai_integration/services/cartesia_tts_service.dart',
    'lib/ai_integration/services/conversation_manager.dart',
    'lib/ai_integration/services/gemini_cost_tracker.dart',
    'lib/ai_integration/services/mental_coach_system.dart',
    'lib/ai_integration/utils/ai_utils.dart',
    'lib/ai_integration/widgets/ai_insight_audio_player.dart',
    'lib/ai_integration/widgets/ai_insight_widget.dart',
]

for file in ai_files:
    if os.path.exists(file):
        fix_file(file, [
            (r"^import '/backend/schema/index\.dart';\n", ""),
        ])

# Fix backend schema files
schema_files = [
    'lib/backend/schema/achievements_record.dart',
    'lib/backend/schema/activity_record.dart',
    'lib/backend/schema/ai_insights_record.dart',
    'lib/backend/schema/app_settings_record.dart',
    'lib/backend/schema/coaching_modules_record.dart',
    'lib/backend/schema/dashboard_data_record.dart',
    'lib/backend/schema/golf_rounds_record.dart',
    'lib/backend/schema/home_data_record.dart',
    'lib/backend/schema/mental_sessions_record.dart',
    'lib/backend/schema/round_logs_record.dart',
    'lib/backend/schema/scorecard_record.dart',
    'lib/backend/schema/shot_logs_record.dart',
    'lib/backend/schema/user_achievements_record.dart',
    'lib/backend/schema/user_record.dart',
    'lib/backend/schema/user_subscriptions_record.dart',
]

for file in schema_files:
    if os.path.exists(file):
        fix_file(file, [
            (r"^import 'index\.dart';\n", ""),
        ])

# Fix specific files
if os.path.exists('lib/ai_integration/services/gemini_live_service.dart'):
    fix_file('lib/ai_integration/services/gemini_live_service.dart', [
        (r"^import 'dart:typed_data';\n", ""),
    ])

if os.path.exists('lib/backend/schema/activity_record.dart'):
    fix_file('lib/backend/schema/activity_record.dart', [
        (r"^import 'package:collection/collection\.dart';\n", ""),
        (r" as Map<String, dynamic>", ""),
    ])

if os.path.exists('lib/backend/schema/dashboard_data_record.dart'):
    fix_file('lib/backend/schema/dashboard_data_record.dart', [
        (r"^import 'package:collection/collection\.dart';\n", ""),
    ])

if os.path.exists('lib/backend/schema/app_settings_record.dart'):
    fix_file('lib/backend/schema/app_settings_record.dart', [
        (r"^import '/flutter_flow/flutter_flow_util\.dart';\n", ""),
    ])

if os.path.exists('lib/pages/vark_onboarding/vark_onboarding_widget.dart'):
    fix_file('lib/pages/vark_onboarding/vark_onboarding_widget.dart', [
        (r"^import 'package:cloud_firestore/cloud_firestore\.dart';\n", ""),
    ])

if os.path.exists('lib/pages/progress/progress_widget.dart'):
    fix_file('lib/pages/progress/progress_widget.dart', [
        (r"^import 'package:font_awesome_flutter/font_awesome_flutter\.dart';\n", ""),
    ])

# Fix deprecated VoiceChatModal usage
if os.path.exists('lib/ai_integration/widgets/voice_chat_button.dart'):
    fix_file('lib/ai_integration/widgets/voice_chat_button.dart', [
        (r'VoiceChatModal', 'FoCoCoVoiceChatModal'),
    ])

# Fix null-aware operators
null_aware_files = [
    'lib/ai_integration/widgets/voice_chat_button.dart',
    'lib/ai_integration/widgets/voice_chat_modal.dart',
]

for file in null_aware_files:
    if os.path.exists(file):
        fix_file(file, [
            (r'widget\?\.', 'widget.'),
            (r'mounted\?\.', 'mounted.'),
        ])

# Fix push notification files
push_files = [
    'lib/backend/push_notifications/notification_settings_widget.dart',
    'lib/backend/push_notifications/push_notifications_handler.dart',
    'lib/backend/push_notifications/push_notifications_util.dart',
]

for file in push_files:
    if os.path.exists(file):
        fix_file(file, [
            (r"^import '/backend/schema/index\.dart';\n", ""),
        ])

print("\nAll fixes completed!")
