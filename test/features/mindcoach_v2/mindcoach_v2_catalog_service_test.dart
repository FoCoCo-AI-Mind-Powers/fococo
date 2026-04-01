import 'package:flutter_test/flutter_test.dart';

import 'package:fo_co_co/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import 'package:fo_co_co/features/mindcoach_v2/services/mindcoach_v2_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog asset exposes the screenshot-matched home structure', () async {
    final catalog = await MindCoachV2CatalogService.instance.load();

    expect(catalog.homeSubtitle, 'Select a pillar to strengthen');
    expect(
      catalog.pillars.map((pillar) => pillar.label).toList(),
      ['FOCUS', 'CONFIDENCE', 'CONTROL'],
    );
  });

  test('catalog contains focus, confidence, and control session lists',
      () async {
    final catalog = await MindCoachV2CatalogService.instance.load();
    final focus = catalog.pillar(MindCoachV2Pillar.focus);
    final confidence = catalog.pillar(MindCoachV2Pillar.confidence);
    final control = catalog.pillar(MindCoachV2Pillar.control);

    expect(
      focus.rowDescriptors[MindCoachV2ContextMode.duringRound],
      'Stay present. Shot by shot.',
    );
    expect(
      confidence.rowDescriptors[MindCoachV2ContextMode.beforeRound],
      'Walk in ready to commit.',
    );
    expect(
      control.context(MindCoachV2ContextMode.afterRound).durationHint,
      '60-90 sec',
    );

    final focusDuringRound =
        focus.context(MindCoachV2ContextMode.duringRound).sessions;
    expect(
      focusDuringRound.map((session) => session.name).toList(),
      ['Before Shot', 'During Shot', 'After Shot', 'Between Shots'],
    );
    expect(
      focusDuringRound.map((session) => session.durationSec).toList(),
      [10, 10, 15, 15],
    );
  });
}
