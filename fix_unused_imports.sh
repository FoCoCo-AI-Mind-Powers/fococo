#!/bin/bash

echo "Fixing unused imports..."

# Remove unused import of '/backend/schema/index.dart' from AI integration files
find lib/ai_integration -name "*.dart" -type f -exec sed -i '/^import.*\/backend\/schema\/index\.dart.*$/d' {} \;

# Remove unused import of 'index.dart' from schema files
find lib/backend/schema -name "*.dart" -type f -exec sed -i '/^import.*index\.dart.*$/d' {} \;

# Remove specific unused imports
sed -i '/^import.*dart:typed_data.*$/d' lib/ai_integration/services/gemini_live_service.dart
sed -i '/^import.*package:collection\/collection\.dart.*$/d' lib/backend/schema/activity_record.dart
sed -i '/^import.*package:collection\/collection\.dart.*$/d' lib/backend/schema/dashboard_data_record.dart
sed -i '/^import.*\/flutter_flow\/flutter_flow_util\.dart.*$/d' lib/backend/schema/app_settings_record.dart
sed -i '/^import.*package:cloud_firestore\/cloud_firestore\.dart.*$/d' lib/pages/vark_onboarding/vark_onboarding_widget.dart
sed -i '/^import.*package:font_awesome_flutter\/font_awesome_flutter\.dart.*$/d' lib/pages/progress/progress_widget.dart

echo "Completed fixing unused imports"
