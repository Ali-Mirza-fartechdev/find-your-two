import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';

class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key});

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolunteerProvider>().fetchImpact();
    });
  }

  static const _badgeEmojis = {
    'first_step': '🌱',
    'ten_hours': '⏰',
    'rising_star': '🌟',
    'champion': '🏆',
    'on_fire': '🔥',
    'diamond': '💎',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VolunteerProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: -295,
            top: -261,
            width: 898,
            height: 1764,
            child: SvgPicture.asset(
              'assets/images/home_bg_blob.svg',
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: provider.isLoading && provider.impactData == null
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFFF4A583)),
                  )
                : RefreshIndicator(
                    color: const Color(0xFFF4A583),
                    onRefresh: () => provider.fetchImpact(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildHeader(context),
                          const SizedBox(height: 30),
                          _buildTotalHoursCard(provider),
                          const SizedBox(height: 24),
                          _buildStatsRow(provider),
                          const SizedBox(height: 24),
                          _buildImpactScore(provider),
                          const SizedBox(height: 24),
                          _buildMonthlyHoursChart(provider),
                          const SizedBox(height: 24),
                          _buildAchievements(provider),
                          const SizedBox(height: 150),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Row(
      children: [
        if (canPop) ...[
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF262222).withValues(alpha: 0.6),
                  width: 0.7,
                ),
              ),
              child: const Icon(
                IconlyLight.arrow_left,
                size: 16,
                color: Color(0xFF262222),
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Impact',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            Text(
              'Keep making a difference every day',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF262222),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalHoursCard(VolunteerProvider provider) {
    final hours = provider.totalHours;
    final hoursDisplay =
        hours == hours.roundToDouble() ? '${hours.toInt()}' : hours.toStringAsFixed(1);
    final equivalent = provider.impactEquivalent;

    return Container(
      width: double.infinity,
      height: 149,
      decoration: BoxDecoration(
        color: const Color(0xFFF4A583).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF4A583), width: 0.7),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Total Volunteer Hours',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF4A583),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hoursDisplay,
                style: GoogleFonts.inter(
                  fontSize: 67,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF4A583),
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'hrs',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF4A583),
                ),
              ),
            ],
          ),
          if (equivalent.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '🌍 $equivalent',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFF4A583),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(VolunteerProvider provider) {
    return Row(
      children: [
        _buildStatCard(
          'assets/icons/events_done.svg',
          '${provider.eventsDone}',
          'Events Done',
        ),
        const SizedBox(width: 11),
        _buildStatCard(
          'assets/icons/communities.svg',
          '${provider.communities}',
          'Communities',
        ),
        const SizedBox(width: 11),
        _buildStatCard(
          'assets/icons/day_streak.svg',
          '${provider.dayStreak}',
          'Day Streak',
        ),
      ],
    );
  }

  Widget _buildStatCard(String svgPath, String value, String label) {
    return Expanded(
      child: Container(
        height: 113,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(svgPath, width: 17, height: 17),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF262222).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyHoursChart(VolunteerProvider provider) {
    final data = provider.monthlyHours;

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Hours',
              style: GoogleFonts.inter(
                fontSize: 14.9,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No data yet — volunteer to see your chart!',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF262222).withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    final months = data.map((e) => e['month'] as String? ?? '').toList();
    final values =
        data.map((e) => (e['hours'] as num?)?.toDouble() ?? 0).toList();
    final maxVal = values.reduce(math.max);
    final chartMax = maxVal > 0 ? maxVal : 1.0;
    final totalHours = values.fold<double>(0, (a, b) => a + b);
    final avg = (totalHours / values.length).round();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Hours',
                    style: GoogleFonts.inter(
                      fontSize: 14.9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  Text(
                    'Last ${months.length} month${months.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF262222),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF262222).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(68),
                  border: Border.all(
                    color: const Color(0xFF262222).withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/trending_up.svg',
                      width: 11,
                      height: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Avg ${avg}h/mo',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF262222),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(months.length, (i) {
                final barHeight = (values[i] / chartMax) * 75;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: math.max(barHeight, 4),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF4A583), Color(0x40F4A583)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        months[i].length > 3
                            ? months[i].substring(0, 3)
                            : months[i],
                        style: GoogleFonts.inter(
                          fontSize: 9.3,
                          color: const Color(0xFF262222),
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
    );
  }

  Widget _buildImpactScore(VolunteerProvider provider) {
    final score = provider.impactScore;
    final total = (score['total'] as num?)?.toInt() ?? 0;
    final max = (score['max'] as num?)?.toInt() ?? 1000;
    final reliability = (score['reliability'] as num?)?.toInt() ?? 0;
    final consistency = (score['consistency'] as num?)?.toInt() ?? 0;
    final community = (score['community'] as num?)?.toInt() ?? 0;
    final progress = max > 0 ? total / max : 0.0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impact Score',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              SizedBox(
                width: 106,
                height: 106,
                child: CustomPaint(
                  painter: _CircularScorePainter(
                    progress: progress,
                    strokeWidth: 14,
                    bgColor: const Color(0xFFF1F5F9),
                    fgColor: const Color(0xFFF4A583),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF262222),
                          ),
                        ),
                        Text(
                          '/ $max',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: const Color(0xFF262222)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildScoreBar(
                        'Reliability', reliability / 100, '$reliability%'),
                    const SizedBox(height: 12),
                    _buildScoreBar(
                        'Consistency', consistency / 100, '$consistency%'),
                    const SizedBox(height: 12),
                    _buildScoreBar(
                        'Community', community / 100, '$community%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double value, String percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF262222).withValues(alpha: 0.5),
              ),
            ),
            Text(
              percent,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(9285),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 5.6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFFF4A583)),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements(VolunteerProvider provider) {
    final achievements = provider.achievements;
    final earned = achievements.where((a) => a['earned'] == true).length;

    if (achievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Start volunteering to unlock achievements!',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF262222).withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                ),
              ),
              Text(
                '$earned/${achievements.length} earned',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF262222).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 11,
              crossAxisSpacing: 11,
              childAspectRatio: 92 / 102,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              final badgeId = a['badge_id'] as String? ?? '';
              final name = a['name'] as String? ?? '';
              final description = a['description'] as String? ?? '';
              final isEarned = a['earned'] as bool? ?? false;
              final emoji = _badgeEmojis[badgeId] ?? '✨';

              final descWords = description.split(' ');
              final mid = (descWords.length / 2).ceil();
              final line1 = descWords.take(mid).join(' ');
              final line2 = descWords.skip(mid).join(' ');

              return Opacity(
                opacity: isEarned ? 1.0 : 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    color: isEarned
                        ? const Color(0xFFF4A583).withValues(alpha: 0.1)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isEarned
                          ? const Color(0xFFF4A583).withValues(alpha: 0.6)
                          : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isEarned ? emoji : '🔒',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF262222),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      if (line1.isNotEmpty)
                        Text(
                          line1,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: const Color(0xFF65758B),
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (line2.isNotEmpty)
                        Text(
                          line2,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            color: const Color(0xFF65758B),
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CircularScorePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color bgColor;
  final Color fgColor;

  _CircularScorePainter({
    required this.progress,
    required this.strokeWidth,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularScorePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
