import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/services/ai_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class HomeScreen extends ConsumerStatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> _recommendations = [];
  bool _loadingRecs = false;
  String? _myBusinessId;
  bool _fetchingBusinessId = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  // TEMPORARY: Hardcode a business ID that exists in the backend CSV.
  // Later, replace with the original Supabase query.
  Future<void> _loadBusinessId() async {
    if (_myBusinessId != null || _fetchingBusinessId) return;
    setState(() => _fetchingBusinessId = true);
    // Simulate a short async delay
    await Future.delayed(Duration.zero);
    setState(() {
      // Use any valid business_id from your businesses_clean.csv (e.g., BIZ0034)
      _myBusinessId = 'BIZ0034';
      _fetchingBusinessId = false;
    });
  }

  Future<void> _fetchRecommendations() async {
    if (_myBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not a business owner. No recommendations available.')),
      );
      return;
    }
    setState(() => _loadingRecs = true);
    try {
      final recs = await AiService().getHybridRecommendations(_myBusinessId!, 5);
      setState(() {
        _recommendations = recs;
        _loadingRecs = false;
      });
    } catch (e) {
      setState(() => _loadingRecs = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching recommendations: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredBusinessesProvider);
          ref.invalidate(nearbyBusinessesProvider);
          return await ref.read(featuredBusinessesProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBroadcastBanner(context),
                    const SizedBox(height: 32),
                    _buildTestButton(),
                    const SizedBox(height: 32),
                    if (_recommendations.isNotEmpty) _buildRecommendationsSection(),
                    const SizedBox(height: 16),
                    _buildGettingStarted(context),
                    const SizedBox(height: 32),
                    _buildCategoriesSection(context),
                    const SizedBox(height: 32),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    _buildFeaturedSection(context),
                    const SizedBox(height: 32),
                    _buildNearbySection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton() {
    if (_fetchingBusinessId) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myBusinessId == null) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.warning_amber_rounded),
          label: const Text('No Business Found (You are not a business owner)'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        ),
      );
    }
    return Center(
      child: ElevatedButton.icon(
        onPressed: _loadingRecs ? null : _fetchRecommendations,
        icon: _loadingRecs
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.recommend, color: Colors.white),
        label: Text(_loadingRecs ? 'Fetching...' : 'Get My AI Recommendations'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '🤖 AI Recommended for You'),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recommendations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rec = _recommendations[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec['name'] ?? 'No name',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${rec['category']} • ${rec['neighbourhood']}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${rec['distance_km']} km',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                'Score: ${(rec['final_score'] as double).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Navigate to business details
                      },
                      icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // Existing widgets (unchanged, except removed unnecessary ref parameters)
  // ----------------------------------------------------------------------
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.deepGreen,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w400),
                ),
                Text(
                  widget.user.fullName.split(' ').first,
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.black, Colors.grey.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withAlpha(26), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Text('AI Assistant', style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Text('What are you looking for today?', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.1)),
          const SizedBox(height: 8),
          Text('Describe your need and we\'ll find the best match nearby.', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/ai-search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Find it for me', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGettingStarted(BuildContext context) {
    final steps = [
      {'title': 'Post a Need', 'desc': 'Tell us what you need and let shops find you.', 'icon': Icons.edit_note_rounded, 'color': Colors.blue, 'onTap': () => context.push('/post-need')},
      {'title': 'Explore Shops', 'desc': 'Discover the best local businesses nearby.', 'icon': Icons.explore_rounded, 'color': Colors.orange, 'onTap': () => context.go('/discover')},
      {'title': 'Launch Shop', 'desc': 'Start your own digital shop and grow.', 'icon': Icons.rocket_launch_rounded, 'color': Colors.purple, 'onTap': () => context.push('/create-business')},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const _SectionHeader(title: 'Getting Started'),
              const Spacer(),
              Text('Step 1 of 3', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.lightText, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (step['color'] as Color).withAlpha(13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (step['color'] as Color).withAlpha(26)),
                ),
                child: InkWell(
                  onTap: step['onTap'] as VoidCallback,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(step['icon'] as IconData, color: step['color'] as Color, size: 28),
                      const Spacer(),
                      Text(step['title'] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(step['desc'] as String, style: const TextStyle(fontSize: 10, color: AppColors.lightText), maxLines: 2),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = [
      {'name': 'Food', 'image': 'assets/images/Screenshot 2026-02-11 112211.png', 'cat': BusinessCategory.food},
      {'name': 'Fashion', 'image': 'assets/images/Color Gradient T-shirts Display.png', 'cat': BusinessCategory.fashion},
      {'name': 'Electronics', 'image': 'assets/images/Contemporary VR Headsets Display.png', 'cat': BusinessCategory.electronics},
      {'name': 'Home', 'image': 'assets/images/Modern Workspace Setup.png', 'cat': BusinessCategory.home},
      {'name': 'Beauty', 'image': 'assets/images/Screenshot 2026-02-11 112656.png', 'cat': BusinessCategory.beauty},
      {'name': 'Services', 'image': 'assets/images/Screenshot 2026-02-11 112734.png', 'cat': BusinessCategory.service},
      {'name': 'Automotive', 'image': 'assets/images/Screenshot 2026-02-11 112759.png', 'cat': BusinessCategory.automotive},
      {'name': 'Health', 'image': 'assets/images/Screenshot 2026-02-11 112816.png', 'cat': BusinessCategory.health},
      {'name': 'Sports', 'image': 'assets/images/Screenshot 2026-02-11 112843.png', 'cat': BusinessCategory.sports},
      {'name': 'Kids', 'image': 'assets/images/Screenshot 2026-02-11 112917.png', 'cat': BusinessCategory.kids},
      {'name': 'Education', 'image': 'assets/images/Screenshot 2026-02-11 112931.png', 'cat': BusinessCategory.education},
      {'name': 'Events', 'image': 'assets/images/Screenshot 2026-02-11 113011.png', 'cat': BusinessCategory.entertainment},
      {'name': 'Travel', 'image': 'assets/images/Screenshot 2026-02-11 113031.png', 'cat': BusinessCategory.travel},
      {'name': 'Properties', 'image': 'assets/images/Screenshot 2026-02-11 113047.png', 'cat': BusinessCategory.realEstate},
      {'name': 'Pets', 'image': 'assets/images/Screenshot 2026-02-11 113102.png', 'cat': BusinessCategory.pets},
      {'name': 'Finance', 'image': 'assets/images/Screenshot 2026-02-11 113140.png', 'cat': BusinessCategory.finance},
    ];
    final row1 = categories.sublist(0, (categories.length / 2).ceil());
    final row2 = categories.sublist((categories.length / 2).ceil());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(title: 'Popular Categories'),
              Text('Swipe for more', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: row1.map((cat) => _ThreeDCategoryCard(name: cat['name'] as String, image: cat['image'] as String, category: cat['cat'] as BusinessCategory)).toList()),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: row2.map((cat) => _ThreeDCategoryCard(name: cat['name'] as String, image: cat['image'] as String, category: cat['cat'] as BusinessCategory)).toList()),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(width: 160, child: _QuickActionButton(title: 'Discover', subtitle: 'Explore local shops', icon: Icons.search_rounded, color: AppColors.primaryGreen, onTap: () => context.go('/discover'))),
                const SizedBox(width: 16),
                SizedBox(width: 160, child: _QuickActionButton(title: 'Create Shop', subtitle: 'Reach more people', icon: Icons.add_business_rounded, color: AppColors.deepGreen, onTap: () => context.push('/create-business'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection(BuildContext context) {
    final businessesAsync = ref.watch(featuredBusinessesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: _SectionHeader(title: 'Featured Businesses')),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: businessesAsync.when(
            data: (businesses) {
              if (businesses.isEmpty) return const Center(child: Text('No featured businesses yet'));
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: businesses.length,
                itemBuilder: (context, index) => _FeaturedBusinessCard(business: businesses[index]).animate().fadeIn(delay: (index * 100).ms).scale(begin: const Offset(0.9, 0.9)),
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (_, __) => Container(width: 280, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(24))),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbySection(BuildContext context) {
    final nearbyBusinessesAsync = ref.watch(nearbyBusinessesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Nearby Top Rated'),
          const SizedBox(height: 16),
          nearbyBusinessesAsync.when(
            data: (businesses) {
              if (businesses.isEmpty) return const _NearbyPlaceholder();
              return Column(children: businesses.map((business) => _NearbyBusinessCard(business: business).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1)).toList());
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}

// ---------- Helper widgets (unchanged, just copied below) ----------
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.deepGreen));
}

class _FeaturedBusinessCard extends StatelessWidget {
  final Business business;
  const _FeaturedBusinessCard({required this.business});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push('/business-details', extra: business),
        child: Container(
          width: 280,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(image: NetworkImage(business.coverImageUrl ?? 'https://via.placeholder.com/300'), fit: BoxFit.cover, onError: (_, __) {}),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withAlpha(204)]),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(business.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [const Icon(Icons.star, color: Colors.amber, size: 16), const SizedBox(width: 4), Text('${business.rating} (${business.reviewCount} reviews)', style: const TextStyle(color: Colors.white70, fontSize: 12))]),
              ],
            ),
          ),
        ),
      );
}

class _ThreeDCategoryCard extends StatelessWidget {
  final String name, image;
  final BusinessCategory category;
  const _ThreeDCategoryCard({required this.name, required this.image, required this.category});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.go('/discover', extra: category),
        child: Container(
          width: 140,
          height: 150,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            children: [
              Positioned(bottom: 12, left: 15, right: 15, child: Container(height: 20, decoration: BoxDecoration(boxShadow: [BoxShadow(color: AppColors.primaryGreen.withAlpha(38), blurRadius: 25, spreadRadius: -2)]))),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 15, offset: const Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      Positioned(top: -40, left: -40, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(128)))),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Hero(
                                tag: 'cat_img_$name',
                                child: Transform(
                                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(-0.1)..rotateY(0.1),
                                  alignment: Alignment.center,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, color: Colors.grey)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(8, 0, 8, 16), child: Text(name, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText, letterSpacing: -0.2))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _QuickActionButton extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: color.withAlpha(13), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withAlpha(26))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 32), const SizedBox(height: 16), Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.lightText))]),
        ),
      );
}

class _NearbyBusinessCard extends StatelessWidget {
  final Business business;
  const _NearbyBusinessCard({required this.business});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push('/business-details', extra: business),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Row(
            children: [
              Container(width: 70, height: 70, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: DecorationImage(image: NetworkImage(business.logoUrl ?? 'https://via.placeholder.com/150'), fit: BoxFit.cover))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4), Text('${business.rating} (${business.reviewCount})', style: const TextStyle(color: AppColors.lightText, fontSize: 12)), const SizedBox(width: 8), const Icon(Icons.circle, size: 4, color: Colors.grey), const SizedBox(width: 8), Text(business.category.name.toUpperCase(), style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold))]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      );
}

class _NearbyPlaceholder extends StatelessWidget {
  const _NearbyPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Row(
          children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.lightGreen.withAlpha(51), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.location_on_rounded, color: AppColors.primaryGreen, size: 32)),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Finding nearby...', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text('Scan for shops in your local arcade or street.', style: TextStyle(color: AppColors.lightText, fontSize: 13))])),
          ],
        ),
      );
}