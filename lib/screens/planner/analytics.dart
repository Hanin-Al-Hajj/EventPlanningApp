import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/models/analytics_model.dart';
import 'package:event_planner/repositories/analytics_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String? _error;

  AnalyticsData _analytics = const AnalyticsData.empty();

  static const Color _card = Color(0xFFFFFFFF);
  static const Color _badgeBg = Color(0xFFF5E8E8);

  static const List<Color> _donutColors = [
    AppColors.darkpink,
    AppColors.coral,
    AppColors.green,
    Color(0xFFD4A8A2),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsRepository.analytics.addListener(_onAnalyticsChanged);

    final cachedAnalytics = AnalyticsRepository.cachedAnalytics;
    if (cachedAnalytics != null) {
      _applyAnalytics(cachedAnalytics);
      _isLoading = false;
      unawaited(AnalyticsRepository.refreshInBackground());
    } else {
      unawaited(_loadAnalytics());
    }
  }

  @override
  void dispose() {
    AnalyticsRepository.analytics.removeListener(_onAnalyticsChanged);
    super.dispose();
  }

  void _onAnalyticsChanged() {
    if (!mounted) return;

    final cachedAnalytics = AnalyticsRepository.cachedAnalytics;
    if (cachedAnalytics == null) return;

    setState(() {
      _applyAnalytics(cachedAnalytics);
      _isLoading = false;
      _error = null;
    });
  }

  void _applyAnalytics(AnalyticsData analytics) {
    _analytics = analytics;
  }

  Future<void> _loadAnalytics({bool forceRefresh = true}) async {
    final hasCache = AnalyticsRepository.hasCache;

    if (!hasCache) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final analytics = await AnalyticsRepository.loadAnalytics(
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _applyAnalytics(analytics);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      if (hasCache) {
        setState(() => _error = null);
        return;
      }

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatRevenue(num value) {
    final n = value.toDouble();
    if (n >= 1000) return '\$${(n / 1000).toStringAsFixed(1)}k';
    return '\$$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        toolbarHeight: 76,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(22),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.arrowLeft,
                      size: 20,
                      color: AppColors.darkpink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Analytics',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.darkpink),
            )
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              color: AppColors.darkpink,
              onRefresh: () => _loadAnalytics(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 16),
                  _buildLineChartCard(),
                  const SizedBox(height: 16),
                  _buildDonutCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF6B6B6B)),
        const SizedBox(height: 12),
        const Text(
          'Could not load analytics',
          style: TextStyle(color: Color(0xFF6B6B6B)),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkpink),
          onPressed: () => _loadAnalytics(forceRefresh: true),
          child: const Text('Retry', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  Widget _buildStatCards() {
    final stats = _analytics.stats;
    final cards = [
      _StatItem(
        icon: Icons.trending_up_rounded,
        badge: '+12%',
        value: '${stats.totalEvents}',
        label: 'Total Events',
      ),
      _StatItem(
        icon: Icons.attach_money_rounded,
        badge: '+18%',
        value: _formatRevenue(stats.totalRevenue),
        label: 'Revenue',
      ),
      _StatItem(
        icon: Icons.check_box_outlined,
        badge: '+5%',
        value: '${stats.taskCompletionRate.toStringAsFixed(0)}%',
        label: 'Task Rate',
      ),
      _StatItem(
        icon: Icons.star_border_rounded,
        badge: '+0.3',
        value: '${stats.avgSatisfaction}/10',
        label: 'Satisfaction',
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _buildStatCard(cards[i]),
    );
  }

  Widget _buildStatCard(_StatItem item) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, color: AppColors.green, size: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.badge,
                style: const TextStyle(
                  color: AppColors.burgundy,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item.value,
          style: const TextStyle(
            color: AppColors.burgundy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: const TextStyle(color: AppColors.green, fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _buildLineChartCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Events',
          style: TextStyle(
            color: AppColors.burgundy,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: _analytics.monthlyData.isEmpty
              ? const Center(
                  child: Text(
                    'No data',
                    style: TextStyle(color: AppColors.green),
                  ),
                )
              : _LineChart(
                  data: _analytics.monthlyData,
                  color: AppColors.darkpink,
                ),
        ),
      ],
    ),
  );

  Widget _buildDonutCard() {
    final eventTypeStats = _analytics.eventTypeStats;
    final total = _analytics.eventTypeTotal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'By Type',
            style: TextStyle(
              color: AppColors.burgundy,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutPainter(
                    data: eventTypeStats,
                    total: total,
                    colors: _donutColors,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.burgundy,
                          ),
                        ),
                        const Text(
                          'EVENTS',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.green,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: List.generate(eventTypeStats.length, (i) {
                    final e = eventTypeStats[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _donutColors[i % _donutColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.name,
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${e.count}',
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String badge, value, label;
  const _StatItem({
    required this.icon,
    required this.badge,
    required this.value,
    required this.label,
  });
}

class _LineChart extends StatelessWidget {
  final List<MonthlyAnalyticsPoint> data;
  final Color color;
  const _LineChart({required this.data, required this.color});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _LineChartPainter(data: data, color: color),
    size: Size.infinite,
  );
}

class _LineChartPainter extends CustomPainter {
  final List<MonthlyAnalyticsPoint> data;
  final Color color;
  _LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const double leftPad = 28, bottomPad = 24, topPad = 8;
    final double chartW = size.width - leftPad,
        chartH = size.height - bottomPad - topPad;
    final counts = data.map((e) => e.count).toList();
    final maxVal = counts.reduce(math.max).toDouble();
    final range = maxVal == 0 ? 1.0 : maxVal;
    final gridPaint = Paint()
      ..color = const Color(0xFFE8E0D5)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: AppColors.burgundy.withOpacity(0.4),
      fontSize: 10,
    );
    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartH - (i / 4) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      _drawText(
        canvas,
        '${(i / 4 * maxVal).round()}',
        Offset(0, y - 6),
        labelStyle,
      );
    }
    final points = <Offset>[
      for (int i = 0; i < data.length; i++)
        Offset(
          _xForIndex(i, leftPad, chartW),
          topPad + chartH - (counts[i] / range) * chartH,
        ),
    ];
    final fillPath = Path()..moveTo(points.first.dx, topPad + chartH);
    fillPath.lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        points[i - 1].dy,
      );
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      fillPath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i].dx,
        points[i].dy,
      );
    }
    fillPath
      ..lineTo(points.last.dx, topPad + chartH)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.20), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH)),
    );
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        points[i - 1].dy,
      );
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      linePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i].dx,
        points[i].dy,
      );
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    final xStyle = TextStyle(
      color: AppColors.burgundy.withOpacity(0.4),
      fontSize: 10,
    );
    for (int i = 0; i < data.length; i++) {
      _drawText(
        canvas,
        data[i].month,
        Offset(_xForIndex(i, leftPad, chartW) - 10, size.height - 16),
        xStyle,
      );
    }
  }

  double _xForIndex(int index, double leftPad, double chartW) {
    if (data.length == 1) return leftPad + chartW / 2;
    return leftPad + (index / (data.length - 1)) * chartW;
  }

  void _drawText(Canvas c, String t, Offset o, TextStyle s) {
    (TextPainter(
      text: TextSpan(text: t, style: s),
      textDirection: TextDirection.ltr,
    )..layout()).paint(c, o);
  }

  @override
  bool shouldRepaint(_LineChartPainter o) => o.data != data;
}

class _DonutPainter extends CustomPainter {
  final List<EventTypeAnalyticsStat> data;
  final int total;
  final List<Color> colors;
  _DonutPainter({
    required this.data,
    required this.total,
    required this.colors,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    double startAngle = -math.pi / 2;
    for (int i = 0; i < data.length; i++) {
      final count = data[i].count;
      if (count <= 0) continue;

      final sweep = total == 0 ? 0.0 : (count / total) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = 18
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.data != data || o.total != total;
}
