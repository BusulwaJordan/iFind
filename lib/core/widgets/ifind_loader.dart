import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── 3-D Ring Loader ─────────────────────────────────────────────────────────
// Faithfully replicates the CSS rotating 3-D ring spinner:
//   4 coloured arcs, each tilted at a unique 3-D angle, all spinning on Z.
//
// Colours  : pink #FF8DF9 | red #FF416A | cyan #00FFFF | orange #FCB737
// Ring size: 190 px reference (scaled via [size] parameter)
// Duration : 2 s per revolution (same as the CSS animation)
// ────────────────────────────────────────────────────────────────────────────

class IFindLoader extends StatefulWidget {
  final double size;
  final bool showLabel;
  final String label;

  const IFindLoader({
    super.key,
    this.size = 120,
    this.showLabel = true,
    this.label = 'loading',
  });

  @override
  State<IFindLoader> createState() => _IFindLoaderState();
}

class _IFindLoaderState extends State<IFindLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value * 2 * math.pi; // 0 → 2π per revolution
        final s = widget.size;

        return SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ring 1 – pink
              // CSS: rotateX(50deg) rotateZ(110deg → 470deg)
              _Ring3D(
                size: s,
                color: const Color(0xFFFF8DF9),
                rotX: 50 * math.pi / 180,
                rotZ: 110 * math.pi / 180 + t,
              ),

              // Ring 2 – red
              // CSS: rotateX(20deg) rotateY(50deg) rotateZ(20deg → 380deg)
              _Ring3D(
                size: s,
                color: const Color(0xFFFF416A),
                rotX: 20 * math.pi / 180,
                rotY: 50 * math.pi / 180,
                rotZ: 20 * math.pi / 180 + t,
              ),

              // Ring 3 – cyan (counter-clockwise)
              // CSS: rotateX(40deg) rotateY(130deg) rotateZ(450deg → 90deg)
              _Ring3D(
                size: s,
                color: const Color(0xFF00FFFF),
                rotX: 40 * math.pi / 180,
                rotY: 130 * math.pi / 180,
                rotZ: 450 * math.pi / 180 - t,
              ),

              // Ring 4 – orange
              // CSS: rotateX(70deg) rotateZ(270deg → 630deg)
              _Ring3D(
                size: s,
                color: const Color(0xFFFCB737),
                rotX: 70 * math.pi / 180,
                rotZ: 270 * math.pi / 180 + t,
              ),

              // Centre label
              if (widget.showLabel)
                Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: s * 0.10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Single 3-D ring ───────────────────────────────────────────────────────────

class _Ring3D extends StatelessWidget {
  final double size;
  final Color color;
  final double rotX;
  final double rotY;
  final double rotZ;

  const _Ring3D({
    required this.size,
    required this.color,
    required this.rotX,
    this.rotY = 0,
    required this.rotZ,
  });

  @override
  Widget build(BuildContext context) {
    // Perspective + 3-D rotation (matches CSS rotateX/Y/Z order)
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.002) // perspective (≈ 1/500 px)
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..rotateZ(rotZ);

    return Transform(
      transform: matrix,
      alignment: Alignment.center,
      child: CustomPaint(
        painter: _ArcPainter(
          color: color,
          strokeWidth: 8.0 * size / 190.0,
        ),
        size: Size(size, size),
      ),
    );
  }
}

// ── Arc painter (simulates CSS border-bottom on a circle) ─────────────────────

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _ArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Draw the bottom-half arc (0 → π sweeps from 3 o'clock to 9 o'clock
    // going through 6 o'clock — replicates CSS border-bottom on a circle)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,        // start at right
      math.pi,  // 180° sweep through the bottom
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ── Full-page loading screen (dark background) ─────────────────────────────────

class IFindLoadingPage extends StatelessWidget {
  final String label;
  const IFindLoadingPage({super.key, this.label = 'loading'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: IFindLoader(size: 140, showLabel: true, label: label),
      ),
    );
  }
}

// ── Inline loader for use inside app screens ───────────────────────────────────
// Use this on light backgrounds. Wraps the spinner in a dark pill.

class IFindLoaderInline extends StatelessWidget {
  final double size;
  final String? label;

  const IFindLoaderInline({super.key, this.size = 80, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IFindLoader(size: size, showLabel: false),
            if (label != null) ...[
              const SizedBox(height: 14),
              Text(
                label!,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
