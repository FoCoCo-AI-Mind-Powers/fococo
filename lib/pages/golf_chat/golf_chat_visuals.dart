import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Renders the client-side visual specs (charts/tables) the GolfChat model
/// emits via Gemini function calling. Each spec is a plain map with a `type`
/// of 'chart' or 'table'. Malformed specs are skipped rather than thrown.
class GolfChatVisuals extends StatelessWidget {
  const GolfChatVisuals({
    super.key,
    required this.visuals,
    required this.theme,
    required this.textColor,
  });

  final List<Map<String, dynamic>> visuals;
  final FlutterFlowTheme theme;
  final Color textColor;

  static const List<Color> _palette = [
    Color(0xFF4F8DFD),
    Color(0xFF34C77B),
    Color(0xFFF2A33C),
    Color(0xFFB57BEE),
    Color(0xFFEF6F6C),
  ];

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final spec in visuals) {
      final widget = _buildSpec(spec);
      if (widget != null) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 10),
          child: widget,
        ));
      }
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget? _buildSpec(Map<String, dynamic> spec) {
    switch ((spec['type'] ?? '').toString()) {
      case 'chart':
        return _buildChart(spec);
      case 'table':
        return _buildTable(spec);
      default:
        return null;
    }
  }

  // ── Chart ──────────────────────────────────────────────────────────────
  Widget? _buildChart(Map<String, dynamic> spec) {
    final series = _parseSeries(spec['series']);
    if (series.isEmpty) return null;

    var chartType = (spec['chart_type'] ?? 'bar').toString();
    // Radar requires at least 3 points per series; degrade to bar otherwise.
    if (chartType == 'radar' && series.any((s) => s.points.length < 3)) {
      chartType = 'bar';
    }

    final Widget chart;
    switch (chartType) {
      case 'line':
        chart = _lineChart(series);
        break;
      case 'radar':
        chart = _radarChart(series);
        break;
      case 'bar':
      default:
        chart = _barChart(series);
    }

    final title = (spec['title'] ?? '').toString().trim();
    return _framed(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 180, child: chart),
          if (series.length > 1) ...[
            const SizedBox(height: 8),
            _legend(series),
          ],
        ],
      ),
    );
  }

  Widget _barChart(List<_Series> series) {
    final labels = series.first.points.map((p) => p.label).toList();
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < labels.length; i++) {
      final rods = <BarChartRodData>[];
      for (var s = 0; s < series.length; s++) {
        if (i < series[s].points.length) {
          rods.add(BarChartRodData(
            toY: series[s].points[i].value,
            color: _palette[s % _palette.length],
            width: series.length > 1 ? 6 : 12,
            borderRadius: BorderRadius.circular(3),
          ));
        }
      }
      groups.add(BarChartGroupData(x: i, barRods: rods));
    }

    return BarChart(BarChartData(
      barGroups: groups,
      gridData: _grid(),
      borderData: FlBorderData(show: false),
      titlesData: _titles(labels),
      barTouchData: BarTouchData(enabled: false),
    ));
  }

  Widget _lineChart(List<_Series> series) {
    final labels = series.first.points.map((p) => p.label).toList();
    final bars = <LineChartBarData>[];
    for (var s = 0; s < series.length; s++) {
      final color = _palette[s % _palette.length];
      bars.add(LineChartBarData(
        spots: [
          for (var i = 0; i < series[s].points.length; i++)
            FlSpot(i.toDouble(), series[s].points[i].value),
        ],
        isCurved: true,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: series.length == 1,
          color: color.withValues(alpha: 0.12),
        ),
      ));
    }

    return LineChart(LineChartData(
      lineBarsData: bars,
      gridData: _grid(),
      borderData: FlBorderData(show: false),
      titlesData: _titles(labels),
      lineTouchData: const LineTouchData(enabled: false),
    ));
  }

  Widget _radarChart(List<_Series> series) {
    final labels = series.first.points.map((p) => p.label).toList();
    return RadarChart(RadarChartData(
      radarShape: RadarShape.polygon,
      dataSets: [
        for (var s = 0; s < series.length; s++)
          RadarDataSet(
            dataEntries: series[s]
                .points
                .map((p) => RadarEntry(value: p.value))
                .toList(),
            fillColor: _palette[s % _palette.length].withValues(alpha: 0.18),
            borderColor: _palette[s % _palette.length],
            borderWidth: 2,
            entryRadius: 2,
          ),
      ],
      getTitle: (index, angle) => RadarChartTitle(
        text: index < labels.length ? labels[index] : '',
      ),
      titleTextStyle: theme.labelSmall.copyWith(
        color: textColor.withValues(alpha: 0.7),
        fontSize: 9,
      ),
      tickCount: 3,
      ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 1),
      tickBorderData: BorderSide(color: textColor.withValues(alpha: 0.12)),
      gridBorderData: BorderSide(color: textColor.withValues(alpha: 0.12)),
      radarBorderData: BorderSide(color: textColor.withValues(alpha: 0.12)),
    ));
  }

  FlGridData _grid() => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: textColor.withValues(alpha: 0.08), strokeWidth: 1),
      );

  FlTitlesData _titles(List<String> labels) => FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              child: Text(
                _compact(value),
                style: theme.labelSmall
                    .copyWith(color: textColor.withValues(alpha: 0.6), fontSize: 9),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final i = value.round();
              if (i < 0 || i >= labels.length || (value - i).abs() > 0.01) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  labels[i],
                  style: theme.labelSmall.copyWith(
                      color: textColor.withValues(alpha: 0.6), fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
      );

  Widget _legend(List<_Series> series) => Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          for (var s = 0; s < series.length; s++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _palette[s % _palette.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  series[s].name.isEmpty ? 'Series ${s + 1}' : series[s].name,
                  style: theme.labelSmall
                      .copyWith(color: textColor.withValues(alpha: 0.75)),
                ),
              ],
            ),
        ],
      );

  // ── Table ──────────────────────────────────────────────────────────────
  Widget? _buildTable(Map<String, dynamic> spec) {
    final columns = (spec['columns'] is List)
        ? (spec['columns'] as List).map((c) => c.toString()).toList()
        : <String>[];
    final rows = (spec['rows'] is List)
        ? (spec['rows'] as List)
            .whereType<List>()
            .map((r) => r.map((c) => c.toString()).toList())
            .toList()
        : <List<String>>[];
    if (columns.isEmpty || rows.isEmpty) return null;

    final borderColor = textColor.withValues(alpha: 0.2);
    final title = (spec['title'] ?? '').toString().trim();

    return _framed(
      title: title,
      child: Table(
        border: TableBorder.all(color: borderColor, width: 1),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(
            decoration:
                BoxDecoration(color: textColor.withValues(alpha: 0.06)),
            children: [
              for (final c in columns)
                _cell(c, theme.bodySmall.copyWith(
                    color: textColor, fontWeight: FontWeight.w700)),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [
                for (var i = 0; i < columns.length; i++)
                  _cell(i < row.length ? row[i] : '',
                      theme.bodySmall.copyWith(color: textColor)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(String text, TextStyle style) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(text, style: style),
      );

  // ── Shared frame (optional title + scroll guard for wide content) ────────
  Widget _framed({required String title, required Widget child}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: theme.bodySmall
                  .copyWith(color: textColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
          ],
          child,
        ],
      );

  String _compact(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  List<_Series> _parseSeries(dynamic raw) {
    final out = <_Series>[];
    if (raw is! List) return out;
    for (final s in raw) {
      if (s is! Map) continue;
      final points = <_Pt>[];
      final rawPoints = s['points'];
      if (rawPoints is List) {
        for (final p in rawPoints) {
          if (p is! Map) continue;
          final value = p['value'] is num
              ? (p['value'] as num).toDouble()
              : double.tryParse('${p['value']}');
          if (value != null) {
            points.add(_Pt((p['label'] ?? '').toString(), value));
          }
        }
      }
      if (points.isNotEmpty) {
        out.add(_Series((s['name'] ?? '').toString(), points));
      }
    }
    return out;
  }
}

class _Series {
  const _Series(this.name, this.points);
  final String name;
  final List<_Pt> points;
}

class _Pt {
  const _Pt(this.label, this.value);
  final String label;
  final double value;
}
