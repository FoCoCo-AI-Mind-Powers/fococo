import 'foco_map_widget.dart';

// Full map functionality enabled with dependencies:
// ✅ apple_maps_flutter: ^1.0.2
// ✅ maplibre_gl: ^0.20.0
// ✅ location: ^8.0.1
// ✅ geolocator: ^13.0.1
// ✅ speech_to_text: ^7.1.1

import 'package:flutter/material.dart';

/// FoCoMap widget with full real map functionality
class FoCoMapConditionalWidget extends StatelessWidget {
  const FoCoMapConditionalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Now using the real FoCoMapWidget with Apple Maps/MapLibre integration
    return const FoCoMapWidget();
  }
}
