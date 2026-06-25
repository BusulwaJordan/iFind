import 'dart:async' as java_timer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/loading_widget.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/needs/presentation/providers/need_provider.dart';

class PostNeedScreen extends ConsumerStatefulWidget {
  const PostNeedScreen({super.key});

  @override
  ConsumerState<PostNeedScreen> createState() => _PostNeedScreenState();
}

class _PostNeedScreenState extends ConsumerState<PostNeedScreen> {
  final _textController = TextEditingController();
  final _descController = TextEditingController();
  bool _hasAnalyzed = false;
  Map<String, dynamic>? _analysisResult;
  java_timer.Timer? _debounce; // Added debounce timer

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged); // Added listener
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged); // Removed listener
    _textController.dispose();
    _descController.dispose();
    _debounce?.cancel(); // Cancelled debounce timer
    super.dispose();
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = java_timer.Timer(const Duration(milliseconds: 800), () {
      if (_textController.text.trim().length > 5) {
        _analyze(silent: true);
      }
    });
  }

  void _analyze({bool silent = false}) async {
    // Modified signature
    if (_textController.text.trim().isEmpty) return;

    // Unfocus keyboard
    if (!silent) {
      // Conditional unfocus
      FocusScope.of(context).unfocus();
    }

    await ref.read(postNeedProvider.notifier).analyzeText(_textController.text);
    if (!mounted) return;

    final state = ref.read(postNeedProvider);
    if (state.aiAnalysis != null) {
      setState(() {
        _hasAnalyzed = true;
        _analysisResult = state.aiAnalysis;
      });
    }
  }

  void _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final success = await ref.read(postNeedProvider.notifier).submitNeed(
          userId: user.id,
          title: _textController.text,
          description: _descController.text,
          category: _analysisResult?['category'] ?? 'General',
        );

    if (success && mounted) {
      // Show success animation or dialog
      showDialog(
        context: context,
        builder: (_) => _SuccessDialog(),
      );
    }
  }

  InputDecoration _fieldDecoration({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postNeedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(36)),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 14, 20, 36),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF003D2B),
                      Color(0xFF006241),
                      Color(0xFF0B7A5A)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 16),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: 20),
                        const Icon(Icons.campaign_rounded,
                            size: 44, color: Colors.amber)
                            .animate()
                            .scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut,
                                begin: const Offset(0.6, 0.6)),
                        const SizedBox(height: 12),
                        Text('Post a Need',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900))
                            .animate()
                            .fadeIn(delay: 150.ms)
                            .slideY(begin: 0.2),
                        const SizedBox(height: 6),
                        Text(
                          'Tell us what you need — AI finds the best match nearby.',
                          style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              height: 1.5),
                        ).animate().fadeIn(delay: 220.ms),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main input card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What do you need?',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _textController,
                          maxLines: 4,
                          style: GoogleFonts.outfit(fontSize: 16),
                          decoration: _fieldDecoration(
                            hint:
                                'e.g. "I need a chocolate birthday cake for tomorrow"',
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!_hasAnalyzed)
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.isAnalyzing ? null : _analyze,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: state.isAnalyzing
                                  ? const LoadingWidget(size: 24)
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.auto_awesome,
                                            color: Colors.amber),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Find Best Match',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AI result area
                  if (_hasAnalyzed && _analysisResult != null)
                    _buildAnalysisResult(context, state.isSubmitting),

                  // Matching businesses
                  if (_hasAnalyzed && state.matchingBusinesses.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Matching Businesses Nearby',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.matchingBusinesses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final business = state.matchingBusinesses[index];
                          return _MatchingBusinessCard(business: business)
                              .animate()
                              .fadeIn(delay: (500 + index * 100).ms)
                              .slideX();
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(BuildContext context, bool isSubmitting) {
    final category = _analysisResult!['category'] as String? ?? '';
    final urgency = _analysisResult!['urgency'] as String? ?? '';
    final tags = _analysisResult!['tags'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Analysis',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Complete',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Info chips row
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.category_rounded,
                  color: Colors.blue,
                  value: category,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoChip(
                  icon: Icons.bolt_rounded,
                  color: Colors.amber,
                  value: urgency,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: tags.map<Widget>((tag) {
              return Chip(
                label: Text(tag.toString()),
                backgroundColor: Colors.white,
                labelStyle: GoogleFonts.outfit(fontSize: 12),
                padding: EdgeInsets.zero,
                side: BorderSide(color: Colors.grey.shade200),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Additional details field
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Add more details (Optional)',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.primaryGreen, width: 1.5),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 20),

          // Broadcast button
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const LoadingWidget(size: 24)
                  : Text(
                      'Broadcast Need',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchingBusinessCard extends StatelessWidget {
  final Business business;
  const _MatchingBusinessCard({required this.business});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business-details', extra: business),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  business.coverImageUrl ?? 'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.store, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        business.rating.toString(),
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppColors.primaryGreen, size: 48),
            ).animate().scale().shake(delay: 200.ms),
            const SizedBox(height: 24),
            Text(
              'Need Broadcasted!',
              style:
                  GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We notified 12 relevant businesses near you. Expect offers soon!',
              style: GoogleFonts.outfit(color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.pop(); // Close success dialog
                  context.pop(); // Return to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkText,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Great!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
