import 'foco_map_placeholder_widget.dart';

// Conditional import - use placeholder when dependencies are missing
// To enable full map functionality, add these to pubspec.yaml:
// google_maps_flutter: ^2.5.0
// location: ^5.0.0
// speech_to_text: ^6.6.0  
// geolocator: ^10.1.0

// Then import the full widget:
// import 'foco_map_widget.dart';

import 'package:flutter/material.dart';

/// Conditional FoCoMap widget that shows placeholder until dependencies are added
class FoCoMapConditionalWidget extends StatelessWidget {
  const FoCoMapConditionalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, always use placeholder until dependencies are added
    // Once dependencies are added, switch to: return const FoCoMapWidget();
    return const FoCoMapPlaceholderWidget();
  }
}
