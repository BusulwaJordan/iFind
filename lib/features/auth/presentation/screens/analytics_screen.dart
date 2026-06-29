import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';

// ─── Real analytics data provider ──────────────────────────────────
final analyticsDataProvider =
    FutureProvider.family<Map<String, int>, String>((ref, businessId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final viewsRes = await supabase
      .from('interactions')
      .select('id')
      .eq('business_id', businessId)
      .eq('interaction_type', 'profile_view');

  final inquiriesRes = await supabase
      .from('interactions')
      .select('id')
      .eq('business_id', businessId)
      .eq('interaction_type', 'inquiry_sent');

  final matchesRes = await supabase
      .from('b2b_matches')
      .select('id')
      .or('business_a_id.eq.$businessId,business_b_id.eq.$businessId');

  final reviewsRes = await supabase
      .from('reviews')
      .select('id')
      .eq('business_id', businessId);

  return {
    'views': (viewsRes as List).length,
    'inquiries': (inquiriesRes as List).length,
    'matches': (matchesRes as List).length,
    'reviews': (reviewsRes as List).length,
  };
});

// ─── Analytics Screen ──────────────────────────────────────────────
class AnalyticsScreen extends ConsumerStatefulWidget {
  final String businessId;

  const AnalyticsScreen({super.key, required this.businessId});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  // Time filter: 0 = Today, 1 = Week, 2 = Month
  int _selectedFilter = 1;

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF0A5C36);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── KPI Cards ──────────────────────────────────────────
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            _buildKpiRow(context),

            const SizedBox(height: 28),

            // ─── Performance Chart ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Performance Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                _buildFilterChips(),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerformanceChart(context),

            const SizedBox(height: 28),

            // ─── Category Breakdown ────────────────────────────────
            const Text(
              'Category Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryBreakdown(),

            const SizedBox(height: 28),

            // ─── Insights ──────────────────────────────────────────
            const Text(
              'Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            _buildInsights(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    const darkGreen = Color(0xFF0A5C36);
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        padding: const EdgeInsets.only(top: 40, bottom: 12, left: 20, right: 16),
        decoration: BoxDecoration(
          color: darkGreen,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Text(
              'Analytics',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getBusinessName(),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBusinessName() {
    // In a real implementation, you'd get this from a provider.
    // For now, we'll return a placeholder.
    return 'My Business';
  }

  // ─── KPI Row ──────────────────────────────────────────────────────
  Widget _buildKpiRow(BuildContext context) {
    const darkGreen = Color(0xFF0A5C36);
    final analyticsAsync = ref.watch(analyticsDataProvider(widget.businessId));

    return analyticsAsync.when(
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        final views = stats['views'] ?? 0;
        final inquiries = stats['inquiries'] ?? 0;
        final matches = stats['matches'] ?? 0;
        final reviews = stats['reviews'] ?? 0;
        final conversion = views > 0
            ? '${(inquiries / views * 100).toStringAsFixed(1)}%'
            : '0%';

        final kpis = [
          {'label': 'Views', 'value': '$views', 'icon': Icons.visibility_rounded},
          {'label': 'Inquiries', 'value': '$inquiries', 'icon': Icons.chat_bubble_outline_rounded},
          {'label': 'Matches', 'value': '$matches', 'icon': Icons.handshake_rounded},
          {'label': 'Reviews', 'value': '$reviews', 'icon': Icons.star_outline_rounded},
          {'label': 'Conversion', 'value': conversion, 'icon': Icons.trending_up_rounded},
        ];

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kpis.map((kpi) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 60) / 3,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(kpi['icon'] as IconData, size: 16, color: darkGreen),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            kpi['label'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      kpi['value'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ─── Filter Chips ─────────────────────────────────────────────────
  Widget _buildFilterChips() {
    final filters = ['Today', 'Week', 'Month'];

    return Row(
      children: filters.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isSelected = _selectedFilter == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedFilter = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0A5C36) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey.shade300,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Performance Chart ───────────────────────────────────────────
  Widget _buildPerformanceChart(BuildContext context) {
    const darkGreen = Color(0xFF0A5C36);

    // Mock data: 7 days
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final views = [12, 18, 14, 22, 29, 17, 24];
    final inquiries = [3, 5, 2, 7, 9, 4, 6];

    final maxValue = views.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              _buildLegend(darkGreen, 'Views'),
              const SizedBox(width: 16),
              _buildLegend(darkGreen.withValues(alpha: 0.4), 'Inquiries'),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final viewHeight = (views[index] / maxValue) * 100;
                final inquiryHeight = (inquiries[index] / maxValue) * 100;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Inquiry bar (shorter, lighter)
                      Container(
                        width: 12,
                        height: inquiryHeight.clamp(4.0, 120.0),
                        decoration: BoxDecoration(
                          color: darkGreen.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // View bar (taller, darker)
                      Container(
                        width: 12,
                        height: viewHeight.clamp(4.0, 120.0),
                        decoration: BoxDecoration(
                          color: darkGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[index],
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Mini stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total views: ${views.reduce((a, b) => a + b)}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Avg: ${(views.reduce((a, b) => a + b) / views.length).toStringAsFixed(0)}/day',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ─── Category Breakdown ──────────────────────────────────────────
  Widget _buildCategoryBreakdown() {
    const darkGreen = Color(0xFF0A5C36);

    final categories = [
      {'name': 'Contracting', 'count': 12, 'total': 47},
      {'name': 'Cleaning', 'count': 9, 'total': 47},
      {'name': 'Catering', 'count': 7, 'total': 47},
      {'name': 'Electrical', 'count': 6, 'total': 47},
      {'name': 'Plumbing', 'count': 5, 'total': 47},
      {'name': 'Other', 'count': 8, 'total': 47},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: categories.map((cat) {
          final count = cat['count'] as int;
          final total = cat['total'] as int;
          final percentage = (count / total) * 100;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        cat['name'] as String,
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkText),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentage > 50 ? darkGreen : darkGreen.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Insights ─────────────────────────────────────────────────────
  Widget _buildInsights(BuildContext context) {
    const darkGreen = Color(0xFF0A5C36);

    final insights = [
      {
        'icon': Icons.trending_up_rounded,
        'title': 'Best performing day',
        'description': 'Friday brings 30% more inquiries than average. Consider boosting your ads on Thursdays.',
      },
      {
        'icon': Icons.people_outline_rounded,
        'title': 'New audience',
        'description': 'Your profile views are up 12% this month. Update your gallery to convert more visitors.',
      },
      {
        'icon': Icons.handshake_rounded,
        'title': 'Match quality',
        'description': 'B2B matches have a 67% conversion rate. Your profile is attracting the right partners.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: darkGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    insight['icon'] as IconData,
                    size: 20,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        insight['description'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}