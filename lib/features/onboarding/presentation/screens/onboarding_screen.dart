import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';

// ── Page data ────────────────────────────────────────────────────────────────

class _PageData {
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData accentIcon1;
  final IconData accentIcon2;
  final Color gradientTop;
  final Color gradientBottom;
  final Color accentColor;

  const _PageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentIcon1,
    required this.accentIcon2,
    required this.gradientTop,
    required this.gradientBottom,
    required this.accentColor,
  });
}

const _kPages = [
  _PageData(
    title: "Discover Uganda's\nHidden Gems",
    subtitle:
        "Find local businesses near you — restaurants, boutiques, services and more, all in one place.",
    icon: Icons.explore_rounded,
    accentIcon1: Icons.location_pin,
    accentIcon2: Icons.storefront_rounded,
    gradientTop: Color(0xFF012B1E),
    gradientBottom: Color(0xFF006241),
    accentColor: Color(0xFF00C853),
  ),
  _PageData(
    title: "Connect\nDirectly",
    subtitle:
        "Chat with business owners, book appointments, and support your local economy with ease.",
    icon: Icons.forum_rounded,
    accentIcon1: Icons.chat_bubble_rounded,
    accentIcon2: Icons.phone_in_talk_rounded,
    gradientTop: Color(0xFF0A1929),
    gradientBottom: Color(0xFF1565C0),
    accentColor: Color(0xFF42A5F5),
  ),
  _PageData(
    title: "Grow\nTogether",
    subtitle:
        "Whether you're a customer or a business owner, iFind helps you thrive in the digital world.",
    icon: Icons.trending_up_rounded,
    accentIcon1: Icons.groups_rounded,
    accentIcon2: Icons.star_rounded,
    gradientTop: Color(0xFF1A0533),
    gradientBottom: Color(0xFF6A1B9A),
    accentColor: Color(0xFFCE93D8),
  ),
];

// ── Floating decoration data ─────────────────────────────────────────────────

class _Bubble {
  final double x; // 0–1 fraction of screen width
  final double y; // 0–1 fraction of screen height
  final double size;
  final double opacity;
  final double phase; // unique float phase offset
  const _Bubble(this.x, this.y, this.size, this.opacity, this.phase);
}

const _kBubbles = [
  [
    _Bubble(0.08, 0.12, 90, 0.07, 0.0),
    _Bubble(0.88, 0.08, 60, 0.08, 1.0),
    _Bubble(0.80, 0.55, 110, 0.05, 0.5),
    _Bubble(0.12, 0.62, 70, 0.07, 1.7),
    _Bubble(0.50, 0.04, 44, 0.09, 0.9),
    _Bubble(0.65, 0.30, 35, 0.06, 1.3),
  ],
  [
    _Bubble(0.06, 0.18, 85, 0.07, 0.3),
    _Bubble(0.90, 0.12, 55, 0.08, 1.2),
    _Bubble(0.78, 0.58, 100, 0.05, 0.8),
    _Bubble(0.14, 0.68, 65, 0.07, 1.5),
    _Bubble(0.55, 0.06, 40, 0.09, 0.4),
    _Bubble(0.35, 0.35, 30, 0.06, 1.9),
  ],
  [
    _Bubble(0.10, 0.15, 95, 0.07, 0.6),
    _Bubble(0.86, 0.10, 65, 0.08, 1.4),
    _Bubble(0.75, 0.60, 115, 0.05, 0.9),
    _Bubble(0.15, 0.65, 75, 0.07, 0.2),
    _Bubble(0.45, 0.05, 42, 0.09, 1.1),
    _Bubble(0.60, 0.28, 38, 0.06, 0.7),
  ],
];

// ── Main Screen ──────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageCtrl;

  // Continuous animations
  late final AnimationController _floatCtrl;   // bubble float
  late final AnimationController _pulseCtrl;   // icon ring pulse
  late final AnimationController _rotateCtrl;  // slow background ring rotation

  // Per-page content entrance animation
  late final AnimationController _enterCtrl;

  int _currentPage = 0;
  double _pageValue = 0; // smooth offset while swiping

  @override
  void initState() {
    super.initState();

    _pageCtrl = PageController();
    _pageCtrl.addListener(_onScroll);

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..forward();
  }

  @override
  void dispose() {
    _pageCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() => _pageValue = _pageCtrl.page ?? 0);
  }

  void _onPageChanged(int page) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = page);
    _enterCtrl
      ..reset()
      ..forward();
  }

  // ── Lerp background gradient across pages ────────────────────────────────

  Color _lerpTop() => _lerpPageColor(
      (p) => p.gradientTop, _pageValue.clamp(0.0, _kPages.length - 1.0));

  Color _lerpBottom() => _lerpPageColor(
      (p) => p.gradientBottom, _pageValue.clamp(0.0, _kPages.length - 1.0));

  Color _lerpPageColor(Color Function(_PageData) pick, double v) {
    final i = v.floor().clamp(0, _kPages.length - 2);
    final t = v - i;
    return Color.lerp(pick(_kPages[i]), pick(_kPages[i + 1]), t) ??
        pick(_kPages[_currentPage]);
  }

  // ── Entrance animation helpers ────────────────────────────────────────────

  double _entranceValue(double start, double end) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      )
          .animate(CurvedAnimation(
            parent: _enterCtrl,
            curve: Interval(start, end, curve: Curves.easeOut),
          ))
          .value;

  double _iconScale() => Tween<double>(begin: 0.25, end: 1.0)
      .animate(CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ))
      .value;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: Listenable.merge(
              [_floatCtrl, _pulseCtrl, _rotateCtrl, _enterCtrl]),
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_lerpTop(), _lerpBottom()],
                ),
              ),
              child: Stack(
                children: [
                  // ── Slow-rotating giant ring ──────────────────────────────
                  Positioned(
                    top: -size.width * 0.3,
                    left: -size.width * 0.3,
                    child: Transform.rotate(
                      angle: _rotateCtrl.value * 2 * math.pi,
                      child: Container(
                        width: size.width * 1.6,
                        height: size.width * 1.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.04),
                            width: 60,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Floating bubbles ──────────────────────────────────────
                  ..._buildBubbles(size),

                  // ── Main content ──────────────────────────────────────────
                  Column(
                    children: [
                      _buildTopBar(context),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageCtrl,
                          onPageChanged: _onPageChanged,
                          itemCount: _kPages.length,
                          itemBuilder: (_, i) => _buildPageContent(i, size),
                        ),
                      ),
                      _buildBottomNav(),
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 24),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Top bar: logo + skip ─────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 20, 0),
        child: Row(
          children: [
            // iFind wordmark
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'iFind',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (_currentPage < _kPages.length - 1)
              GestureDetector(
                onTap: _skipToLast,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1),
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Floating bubbles ──────────────────────────────────────────────────────

  List<Widget> _buildBubbles(Size size) {
    final bubbles = _kBubbles[_currentPage];
    return bubbles.map((b) {
      final dy =
          math.sin((_floatCtrl.value + b.phase) * math.pi) * 14;
      return Positioned(
        left: b.x * size.width - b.size / 2,
        top: b.y * size.height + dy - b.size / 2,
        child: Container(
          width: b.size,
          height: b.size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: b.opacity),
            shape: BoxShape.circle,
          ),
        ),
      );
    }).toList();
  }

  // ── Page content (icon + text) ────────────────────────────────────────────

  Widget _buildPageContent(int index, Size size) {
    final page = _kPages[index];
    final isCurrent = index == _currentPage;

    final iconSc = isCurrent ? _iconScale() : 1.0;
    final titleOp = isCurrent ? _entranceValue(0.30, 0.70) : 1.0;
    final titleDy = isCurrent
        ? (1.0 - _entranceValue(0.30, 0.70)) * 40
        : 0.0;
    final descOp = isCurrent ? _entranceValue(0.50, 0.90) : 1.0;
    final descDy = isCurrent
        ? (1.0 - _entranceValue(0.50, 0.90)) * 40
        : 0.0;

    // Pulse ring scale
    final pulse = Tween<double>(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(
            parent: _pulseCtrl, curve: Curves.easeInOut))
        .value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Icon with rings ────────────────────────────────────────
          Transform.scale(
            scale: iconSc,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outermost pulse ring
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                // Middle ring
                Container(
                  width: 158,
                  height: 158,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                // Inner container
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.13),
                  ),
                ),
                // Icon itself
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: Icon(page.icon, size: 44, color: Colors.white),
                ),

                // Small accent icons orbiting
                _OrbitIcon(
                  angle: -math.pi / 4,
                  radius: 72,
                  icon: page.accentIcon1,
                  rotateVal: _rotateCtrl.value,
                  size: 20,
                ),
                _OrbitIcon(
                  angle: math.pi * 0.65,
                  radius: 72,
                  icon: page.accentIcon2,
                  rotateVal: _rotateCtrl.value,
                  size: 18,
                ),
              ],
            ),
          ),

          const SizedBox(height: 52),

          // ── Title ─────────────────────────────────────────────────
          Transform.translate(
            offset: Offset(0, titleDy),
            child: Opacity(
              opacity: titleOp.clamp(0.0, 1.0),
              child: Text(
                page.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Subtitle ──────────────────────────────────────────────
          Transform.translate(
            offset: Offset(0, descDy),
            child: Opacity(
              opacity: descOp.clamp(0.0, 1.0),
              child: Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.65,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom navigation ─────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final page = _kPages[_currentPage];
    final isLast = _currentPage == _kPages.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      child: Column(
        children: [
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_kPages.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == i ? 30 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 36),

          // Buttons
          if (isLast)
            // Last page — full-width CTA
            SizedBox(
              width: double.infinity,
              height: 62,
              child: ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: page.gradientBottom,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        color: page.gradientBottom,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded,
                        size: 20, color: page.gradientBottom),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                // Skip pill
                GestureDetector(
                  onTap: _skipToLast,
                  child: Container(
                    height: 62,
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Next pill
                GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: page.gradientBottom,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _nextPage() {
    HapticFeedback.lightImpact();
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  void _skipToLast() {
    HapticFeedback.lightImpact();
    _pageCtrl.animateToPage(
      _kPages.length - 1,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    await ref.read(onboardingCompleteProvider.notifier).completeOnboarding();
    if (mounted) context.go('/login');
  }
}

// ── Orbiting accent icon ──────────────────────────────────────────────────────

class _OrbitIcon extends StatelessWidget {
  final double angle;
  final double radius;
  final IconData icon;
  final double rotateVal; // 0–1 from AnimationController
  final double size;

  const _OrbitIcon({
    required this.angle,
    required this.radius,
    required this.icon,
    required this.rotateVal,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // slow orbit — one full revolution per 20 s (same as _rotateCtrl)
    final theta = angle + rotateVal * 2 * math.pi * 0.15;
    final dx = math.cos(theta) * radius;
    final dy = math.sin(theta) * radius;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.22), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
