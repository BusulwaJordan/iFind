import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/presentation/providers/b2b_provider.dart';
import 'package:ifind/features/needs/presentation/providers/need_provider.dart';

// ─── Business id resolution ─────────────────────────────────────────
// `interactions` (and `chats`) key businesses by the custom text id
// (e.g. "BIZ0122"), but `reviews` still keys by the UUID primary key on
// `businesses`. Resolve the UUID once so both families of tables can be
// queried correctly for the same business.
final _businessUuidProvider =
    FutureProvider.family.autoDispose<String?, String>((ref, businessId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final row = await supabase
      .from('businesses')
      .select('id')
      .eq('business_id', businessId)
      .maybeSingle();
  return row?['id'] as String?;
});

// ─── Real analytics data provider ──────────────────────────────────
final analyticsDataProvider = FutureProvider.family
    .autoDispose<Map<String, int>, String>((ref, businessId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final businessUuid =
      await ref.watch(_businessUuidProvider(businessId).future);

  final viewsRes = await supabase
      .from('interactions')
      .select('interaction_id')
      .eq('business_id', businessId)
      .eq('interaction_type', 'profile_view');

  final reviewsRes = businessUuid == null
      ? const []
      : await supabase
          .from('reviews')
          .select('id')
          .eq('business_id', businessUuid);

  return {
    'views': viewsRes.length,
    'reviews': reviewsRes.length,
  };
});

// ─── B2B matches — same candidate list shown on the B2B Matches page ──
final businessB2BMatchesProvider =
    FutureProvider.family.autoDispose<int, String>((ref, businessId) async {
  final candidates =
      await ref.watch(b2bPartnerCandidatesProvider(businessId).future);
  return candidates.length;
});

// ─── Time-series data for the performance chart ────────────────────
class DailyStat {
  final String label;
  final int views;
  const DailyStat({required this.label, required this.views});
}

typedef TimeSeriesParams = ({String businessId, int filter});

final analyticsTimeSeriesProvider = FutureProvider.family
    .autoDispose<List<DailyStat>, TimeSeriesParams>((ref, params) async {
  final supabase = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final boundaries = _bucketBoundaries(params.filter, now);

  final rows = await supabase
      .from('interactions')
      .select('timestamp')
      .eq('business_id', params.businessId)
      .eq('interaction_type', 'profile_view')
      .gte('timestamp', boundaries.first.toIso8601String());

  final data = (rows as List).cast<Map<String, dynamic>>();

  return List.generate(boundaries.length - 1, (i) {
    final bucketStart = boundaries[i];
    final bucketEnd = boundaries[i + 1];
    var views = 0;
    for (final row in data) {
      final ts = DateTime.tryParse(row['timestamp'] as String? ?? '');
      if (ts == null) continue;
      if (!ts.isBefore(bucketStart) && ts.isBefore(bucketEnd)) {
        views++;
      }
    }
    return DailyStat(
        label: _bucketLabel(params.filter, bucketStart), views: views);
  });
});

// filter: 0 = Today (4h buckets), 1 = Week (daily buckets), 2 = Month (5-day buckets)
List<DateTime> _bucketBoundaries(int filter, DateTime now) {
  switch (filter) {
    case 0:
      final start = DateTime(now.year, now.month, now.day);
      return List.generate(7, (i) => start.add(Duration(hours: i * 4)));
    case 2:
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 29));
      return List.generate(7, (i) => start.add(Duration(days: i * 5)));
    default:
      // Monday through Sunday of the current calendar week.
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      return List.generate(8, (i) => monday.add(Duration(days: i)));
  }
}

String _bucketLabel(int filter, DateTime bucketStart) {
  switch (filter) {
    case 0:
      final hour12 = bucketStart.hour % 12 == 0 ? 12 : bucketStart.hour % 12;
      final suffix = bucketStart.hour < 12 ? 'am' : 'pm';
      return '$hour12$suffix';
    case 2:
      return '${bucketStart.day}/${bucketStart.month}';
    default:
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[bucketStart.weekday - 1];
  }
}

// ─── Likes (rating-based) provider ─────────────────────────────────
final businessLikesProvider = FutureProvider.family
    .autoDispose<Map<String, int>, String>((ref, businessId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final businessUuid =
      await ref.watch(_businessUuidProvider(businessId).future);
  if (businessUuid == null) {
    return {'likes': 0, 'total': 0, '5': 0, '4': 0, '3': 0, '2': 0, '1': 0};
  }

  final res = await supabase
      .from('reviews')
      .select('rating')
      .eq('business_id', businessUuid);

  final ratings = (res as List).map((r) => r['rating'] as int).toList();
  final distribution = {for (var star = 5; star >= 1; star--) star: 0};
  for (final r in ratings) {
    if (distribution.containsKey(r)) distribution[r] = distribution[r]! + 1;
  }
  final likes = ratings.where((r) => r >= 4).length;

  return {
    'likes': likes,
    'total': ratings.length,
    '5': distribution[5]!,
    '4': distribution[4]!,
    '3': distribution[3]!,
    '2': distribution[2]!,
    '1': distribution[1]!,
  };
});

// ─── Posts received (matching "Need" posts) ─────────────────────────
// Same category + 20km matching logic as the Leads Dashboard, but
// unfiltered by contact status — a cumulative count of every Need post
// that has ever matched this business, not just the actionable ones.
final businessPostsReceivedProvider =
    FutureProvider.family.autoDispose<int, String>((ref, businessId) async {
  final business = await ref.watch(businessProvider(businessId).future);
  if (business == null) return 0;

  final repository = ref.watch(needsRepositoryProvider);
  final needs = await repository.getNearbyNeeds(
    business.latitude,
    business.longitude,
    20.0,
  );

  return needs
      .where((need) =>
          businessCategoryForNeedCategory(need.category) == business.category)
      .length;
});

// ─── Contacts (unique customers + businesses this business has been in
// contact with, across both B2C and B2B chats) ─────────────────────────
final businessContactsProvider =
    FutureProvider.family.autoDispose<int, String>((ref, businessId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final customerRes = await supabase
      .from('chats')
      .select('customer_id')
      .eq('business_id', businessId)
      .eq('is_b2b', false);
  final uniqueCustomers = (customerRes as List)
      .map((c) => c['customer_id'] as String?)
      .whereType<String>()
      .toSet();

  final b2bRes = await supabase
      .from('chats')
      .select('business_a_id, business_b_id')
      .eq('is_b2b', true)
      .or('business_a_id.eq.$businessId,business_b_id.eq.$businessId');
  final uniquePartnerBusinesses = <String>{};
  for (final row in (b2bRes as List)) {
    final aId = row['business_a_id'] as String?;
    final bId = row['business_b_id'] as String?;
    if (aId != null && aId != businessId) uniquePartnerBusinesses.add(aId);
    if (bId != null && bId != businessId) uniquePartnerBusinesses.add(bId);
  }

  return uniqueCustomers.length + uniquePartnerBusinesses.length;
});

// Minimum sample size before a computed percentage is considered stable
// enough to show — below this, small counts swing wildly (e.g. 1 view on
// an otherwise-empty week reads as "700% above average").
const _kMinSampleForPercent = 10;

// ─── Insights (computed from real view history) ────────────────────
class BusinessInsights {
  final String? bestDay;
  final double? bestDayShareOfViews; // % of total views that fell on bestDay — always 0-100
  final double? viewsTrendPercent; // null = not enough history to compare
  const BusinessInsights({
    this.bestDay,
    this.bestDayShareOfViews,
    this.viewsTrendPercent,
  });
}

final businessInsightsProvider = FutureProvider.family
    .autoDispose<BusinessInsights, String>((ref, businessId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final now = DateTime.now();
  final sixtyDaysAgo = now.subtract(const Duration(days: 60));

  final rows = await supabase
      .from('interactions')
      .select('timestamp')
      .eq('business_id', businessId)
      .eq('interaction_type', 'profile_view')
      .gte('timestamp', sixtyDaysAgo.toIso8601String());

  final timestamps = (rows as List)
      .map((r) => DateTime.tryParse(r['timestamp'] as String? ?? ''))
      .whereType<DateTime>()
      .toList();

  if (timestamps.isEmpty) return const BusinessInsights();

  // Best performing day of week — expressed as its share of total views,
  // which is always naturally within 0-100 (unlike a "% above average"
  // comparison, which can exceed 100 and reads as an unreal figure).
  final countsByWeekday = {for (var d = 1; d <= 7; d++) d: 0};
  for (final ts in timestamps) {
    countsByWeekday[ts.weekday] = countsByWeekday[ts.weekday]! + 1;
  }
  final bestWeekday =
      countsByWeekday.entries.reduce((a, b) => a.value >= b.value ? a : b);
  const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final bestDayShare = timestamps.length >= _kMinSampleForPercent
      ? (bestWeekday.value / timestamps.length) * 100
      : null;

  // Month-over-month trend
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  final recentCount =
      timestamps.where((ts) => ts.isAfter(thirtyDaysAgo)).length;
  final priorCount =
      timestamps.where((ts) => !ts.isAfter(thirtyDaysAgo)).length;
  final trendPercent =
      (priorCount > 0 && recentCount + priorCount >= _kMinSampleForPercent)
          ? ((recentCount - priorCount) / priorCount) * 100
          : null;

  return BusinessInsights(
    bestDay: dayNames[bestWeekday.key - 1],
    bestDayShareOfViews: bestDayShare,
    viewsTrendPercent: trendPercent,
  );
});

// ─── Average response time (real, from message timestamps) ─────────
// For each B2C chat, the time from the customer's first message to the
// business's first reply after it, averaged across all chats that have
// both a customer message and a business reply.
final businessResponseTimeProvider =
    FutureProvider.family.autoDispose<Duration?, String>((ref, businessId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final chatsRes = await supabase
      .from('chats')
      .select('id, customer_id')
      .eq('business_id', businessId)
      .eq('is_b2b', false);
  final chats = (chatsRes as List).cast<Map<String, dynamic>>();
  if (chats.isEmpty) return null;

  final chatIds = chats.map((c) => c['id'] as String).toList();
  final customerByChat = {
    for (final c in chats) c['id'] as String: c['customer_id'] as String?
  };

  final messagesRes = await supabase
      .from('messages')
      .select('chat_id, sender_id, created_at')
      .inFilter('chat_id', chatIds)
      .order('created_at', ascending: true);
  final messages = (messagesRes as List).cast<Map<String, dynamic>>();

  final messagesByChat = <String, List<Map<String, dynamic>>>{};
  for (final m in messages) {
    messagesByChat.putIfAbsent(m['chat_id'] as String, () => []).add(m);
  }

  final responseTimes = <Duration>[];
  for (final entry in messagesByChat.entries) {
    final customerId = customerByChat[entry.key];
    if (customerId == null) continue;

    DateTime? firstCustomerMsgAt;
    for (final m in entry.value) {
      if (m['sender_id'] == customerId) {
        firstCustomerMsgAt = DateTime.tryParse(m['created_at'] as String? ?? '');
        break;
      }
    }
    if (firstCustomerMsgAt == null) continue;

    for (final m in entry.value) {
      if (m['sender_id'] != customerId) {
        final replyAt = DateTime.tryParse(m['created_at'] as String? ?? '');
        if (replyAt != null && replyAt.isAfter(firstCustomerMsgAt)) {
          responseTimes.add(replyAt.difference(firstCustomerMsgAt));
          break;
        }
      }
    }
  }

  if (responseTimes.isEmpty) return null;

  final totalMicroseconds =
      responseTimes.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
  return Duration(microseconds: totalMicroseconds ~/ responseTimes.length);
});

String _formatResponseTime(Duration d) {
  if (d.inMinutes < 60) {
    return '${d.inMinutes} minute${d.inMinutes == 1 ? '' : 's'}';
  }
  if (d.inHours < 24) {
    return '${d.inHours} hour${d.inHours == 1 ? '' : 's'}';
  }
  return '${d.inDays} day${d.inDays == 1 ? '' : 's'}';
}

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
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).padding.bottom + 40,
        ),
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

            // ─── Likes ──────────────────────────────────────────────
            const Text(
              'Likes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            _buildLikesSection(context),

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
        padding:
            const EdgeInsets.only(top: 40, bottom: 12, left: 20, right: 16),
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
          ],
        ),
      ),
    );
  }

  // ─── KPI Row ──────────────────────────────────────────────────────
  Widget _buildKpiRow(BuildContext context) {
    const darkGreen = Color(0xFF0A5C36);
    final analyticsAsync = ref.watch(analyticsDataProvider(widget.businessId));
    final postsReceived = ref
            .watch(businessPostsReceivedProvider(widget.businessId))
            .valueOrNull ??
        0;
    final contacts =
        ref.watch(businessContactsProvider(widget.businessId)).valueOrNull ?? 0;
    final matches =
        ref.watch(businessB2BMatchesProvider(widget.businessId)).valueOrNull ??
            0;

    return analyticsAsync.when(
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Could not load analytics: $e',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.red[400]),
        ),
      ),
      data: (stats) {
        final views = stats['views'] ?? 0;
        final reviews = stats['reviews'] ?? 0;

        final kpis = [
          {
            'label': 'Views',
            'value': '$views',
            'icon': Icons.visibility_rounded
          },
          {
            'label': 'Posts Received',
            'value': '$postsReceived',
            'icon': Icons.campaign_rounded
          },
          {
            'label': 'Contacts',
            'value': '$contacts',
            'icon': Icons.person_add_alt_1_rounded
          },
          {
            'label': 'Matches',
            'value': '$matches',
            'icon': Icons.handshake_rounded
          },
          {
            'label': 'Reviews',
            'value': '$reviews',
            'icon': Icons.star_outline_rounded
          },
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
                        Icon(kpi['icon'] as IconData,
                            size: 16, color: darkGreen),
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
    final seriesAsync = ref.watch(analyticsTimeSeriesProvider(
      (businessId: widget.businessId, filter: _selectedFilter),
    ));

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
          seriesAsync.when(
            loading: () => const SizedBox(
              height: 140,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, __) => SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Could not load chart data',
                  style:
                      GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            ),
            data: (buckets) {
              final values = buckets.map((b) => b.views).toList();
              final maxValue =
                  max(1, values.isEmpty ? 0 : values.reduce(max)).toDouble();
              final total = values.fold<int>(0, (sum, v) => sum + v);
              final avg = buckets.isEmpty ? 0 : total / buckets.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 140,
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        values: values,
                        maxValue: maxValue,
                        color: darkGreen,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(height: 1.5, color: Colors.grey.shade300),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(buckets.length, (i) {
                      return Expanded(
                        child: Text(
                          buckets[i].label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total views: $total',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'Avg: ${avg.toStringAsFixed(0)}/period',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Likes ─────────────────────────────────────────────────────────
  Widget _buildLikesSection(BuildContext context) {
    const darkGreen = Color(0xFF0A5C36);
    final likesAsync = ref.watch(businessLikesProvider(widget.businessId));

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
      child: likesAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, __) => Text(
          'Could not load likes',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
        ),
        data: (stats) {
          final likes = stats['likes'] ?? 0;
          final total = stats['total'] ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Colors.pink, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$likes ${likes == 1 ? 'person likes' : 'people like'} your business',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          total == 0
                              ? 'No ratings yet'
                              : 'Based on $total review${total == 1 ? '' : 's'} (4★ and above)',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 16),
                for (var star = 5; star >= 1; star--) ...[
                  _buildStarBar(
                    darkGreen,
                    star,
                    stats['$star'] ?? 0,
                    max(
                        1,
                        [for (var s = 1; s <= 5; s++) stats['$s'] ?? 0]
                            .reduce(max)),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStarBar(Color darkGreen, int star, int count, int maxCount) {
    final percentage = count / maxCount;

    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Row(
            children: [
              Text(
                '$star',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText),
              ),
              const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
            ],
          ),
        ),
        SizedBox(
          width: 175,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                star >= 4 ? darkGreen : darkGreen.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText),
          ),
        ),
      ],
    );
  }

  // ─── Insights ─────────────────────────────────────────────────────
  Widget _buildInsights(BuildContext context) {
    const darkGreen = Color(0xFF0A5C36);
    final insightsAsync =
        ref.watch(businessInsightsProvider(widget.businessId));
    final views = ref
            .watch(analyticsDataProvider(widget.businessId))
            .valueOrNull?['views'] ??
        0;
    final contacts =
        ref.watch(businessContactsProvider(widget.businessId)).valueOrNull ?? 0;
    final responseTime =
        ref.watch(businessResponseTimeProvider(widget.businessId)).valueOrNull;

    return insightsAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, __) => Text(
        'Could not load insights',
        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
      ),
      data: (insightsData) {
        final insights = <Map<String, dynamic>>[];

        if (insightsData.bestDay != null) {
          final pct = insightsData.bestDayShareOfViews;
          insights.add({
            'icon': Icons.trending_up_rounded,
            'title': 'Best performing day',
            'description': pct != null
                ? '${insightsData.bestDay} accounts for ${pct.toStringAsFixed(0)}% of your profile views.'
                : '${insightsData.bestDay} is your most active day for profile views.',
          });
        }

        if (insightsData.viewsTrendPercent != null) {
          final trend = insightsData.viewsTrendPercent!;
          insights.add({
            'icon': Icons.people_outline_rounded,
            'title': trend >= 0 ? 'Growing audience' : 'Views slowing down',
            'description': trend >= 0
                ? 'Your profile views are up ${trend.toStringAsFixed(0)}% compared to the previous 30 days.'
                : 'Your profile views are down ${trend.abs().toStringAsFixed(0)}% compared to the previous 30 days.',
          });
        }

        if (views > 0) {
          final contactRate = (contacts / views * 100).clamp(0, 100);
          insights.add({
            'icon': Icons.handshake_rounded,
            'title': 'Contact rate',
            'description':
                '${contactRate.toStringAsFixed(1)}% of your profile viewers have reached out to you.',
          });
        }

        if (responseTime != null) {
          insights.add({
            'icon': Icons.speed_rounded,
            'title': 'Response time',
            'description':
                'You typically reply to customers within ${_formatResponseTime(responseTime)}.',
          });
        }

        if (insights.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Text(
              'Not enough activity yet — insights will appear here as your profile gets views and contacts.',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: Colors.grey[600], height: 1.4),
            ),
          );
        }

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
      },
    );
  }
}

// ─── Performance chart line painter ──────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<int> values;
  final double maxValue;
  final Color color;

  static const double _topPadding = 16;
  static const double _bottomPadding = 6;

  const _LineChartPainter({
    required this.values,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final plotHeight = size.height - _topPadding - _bottomPadding;
    final points = List.generate(values.length, (i) {
      final dx = (i + 0.5) * (size.width / values.length);
      final dy = _topPadding + (1 - values[i] / maxValue) * plotHeight;
      return Offset(dx, dy);
    });

    // Recessive gridlines so magnitude is readable without a number on
    // every point.
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = _topPadding + plotHeight * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    // Gradient fill under the line.
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line stroke.
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Data point markers (white ring + solid center) so they pop against
    // both the line and the fill.
    final markerRing = Paint()..color = Colors.white;
    final markerCenter = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 6, markerRing);
      canvas.drawCircle(point, 4, markerCenter);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.color != color;
  }
}
