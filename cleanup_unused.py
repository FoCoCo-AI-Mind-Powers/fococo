#!/usr/bin/env python3

import os
import re

# Files with unused elements to fix
fixes = {
    'lib/ai_integration/widgets/voice_chat_modal.dart': [
        # Remove unused _buildThinkingProcess method
        (r'  Widget _buildThinkingProcess\([^}]+}\n\n', ''),
        # Remove unused _formatMessageTime method  
        (r'  String _formatMessageTime\([^}]+}\n\n', ''),
    ],
    'lib/pages/coaching_modules/coaching_modules_widget.dart': [
        # Remove unused _buildCalmInspiredBottomNav method
        (r'  Widget _buildCalmInspiredBottomNav\([^}]+}\n\n', ''),
    ],
    'lib/pages/progress/progress_widget.dart': [
        # Remove unused _buildNavItem method
        (r'  Widget _buildNavItem\([^}]+}\n\n', ''),
    ],
    'lib/pages/vark_onboarding/vark_onboarding_widget.dart': [
        # Remove unused _isMultiModal method
        (r'  bool _isMultiModal\([^}]+}\n\n', ''),
        # Remove unused import
        (r"^import '/flutter_flow/fococo_ui_components\.dart';\n", ""),
        # Fix volumeUp deprecated
        (r'Icons\.volumeUp', 'Icons.volumeHigh'),
    ],
    'lib/services/voice_logging_service.dart': [
        # Remove unused _onSpeechResult method
        (r'  void _onSpeechResult\([^}]+}\n\n', ''),
        # Remove unused _parseAIResponse method
        (r'  Map<String, dynamic>\? _parseAIResponse\([^}]+}\n\n', ''),
    ],
    'lib/ai_integration/widgets/voice_chat_button.dart': [
        # Remove unused _voiceState field
        (r'  final VoiceState _voiceState = VoiceState\.idle;\n', ''),
    ],
    'lib/pages/foco_map/foco_map_model.dart': [
        # Remove unused import
        (r"^import '/backend/schema/index\.dart';\n", ""),
    ],
    'lib/pages/foco_map/foco_map_placeholder_widget.dart': [
        # Remove unused import
        (r"^import '/backend/schema/index\.dart';\n", ""),
    ],
    'lib/pages/profile/profile_modals.dart': [
        # Remove unused import
        (r"^import '/backend/schema/index\.dart';\n", ""),
    ],
    'lib/services/foco_map_live_service.dart': [
        # Remove unused import
        (r"^import '/backend/schema/index\.dart';\n", ""),
    ],
    'lib/services/voice_logging_service.dart': [
        # Remove unused import
        (r"^import '/backend/schema/index\.dart';\n", ""),
    ],
}

for filepath, patterns in fixes.items():
    if os.path.exists(filepath):
        try:
            with open(filepath, 'r') as f:
                content = f.read()
            
            for pattern, replacement in patterns:
                content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)
            
            with open(filepath, 'w') as f:
                f.write(content)
            print(f"Fixed: {filepath}")
        except Exception as e:
            print(f"Error fixing {filepath}: {e}")

print("\nCleanup completed!")
