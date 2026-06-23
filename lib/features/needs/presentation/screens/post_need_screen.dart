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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postNeedProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Post a Need',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What do you need?',
              style:
                  GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text(
              'Describe it, and our AI will find the best match nearby.',
              style: GoogleFonts.outfit(color: Colors.grey[600]),
            ).animate().fadeIn().slideY(begin: 0.2, delay: 100.ms),
            const SizedBox(height: 32),

            // Input Area
            TextField(
              controller: _textController,
              maxLines: 3,
              style: GoogleFonts.outfit(fontSize: 18),
              decoration: InputDecoration(
                hintText:
                    'e.g. "I need a chocolate birthday cake for tomorrow"',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ).animate().fadeIn().scale(delay: 200.ms),

            const SizedBox(height: 24),

            // Analyze Button
            if (!_hasAnalyzed)
              SizedBox(
                height: 56,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text('Find Best Match',
                                style: GoogleFonts.outfit(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 300.ms),

            // AI Result Area
            if (_hasAnalyzed && _analysisResult != null) ...[
              _buildAnalysisResult(context, state.isSubmitting),
              if (state.matchingBusinesses.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Matching Businesses Nearby',
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult(BuildContext context, bool isSubmitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'AI Analysis Complete',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen),
                  ),
                ],
              ),
              const Divider(height: 24),
              _ResultRow(
                  label: 'Category', value: _analysisResult!['category']),
              const SizedBox(height: 8),
              _ResultRow(label: 'Urgency', value: _analysisResult!['urgency']),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: (_analysisResult!['tags'] as List).map<Widget>((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.white,
                    labelStyle: GoogleFonts.outfit(fontSize: 12),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 24),
        TextField(
          controller: _descController,
          decoration: InputDecoration(
            labelText: 'Add more details (Optional)',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: isSubmitting
                ? const LoadingWidget(size: 24)
                : Text(
                    'Broadcast Need',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.grey[600])),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ],
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
