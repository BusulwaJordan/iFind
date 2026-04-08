import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/recommendations/presentation/providers/recommendation_providers.dart';

class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key});

  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _currentQuery = query;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('AI Matchmaker', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.deepGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What are you looking for?',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'e.g. "I need an expert phone mechanic"',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.auto_awesome, color: Colors.white),
                        onPressed: _performSearch,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _currentQuery.isEmpty
                ? Center(
                    child: Text(
                      'Type above to let AI find local matches.',
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                  )
                : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    // Note: Using hardcoded coordinates for Kampala purely for testing readiness.
    // In production, integrate this with a location provider like Geolocator.
    final recommendationsAsync = ref.watch(aiMatchmakingProvider(
      intent: _currentQuery,
      latitude: 0.347596,
      longitude: 32.582520,
    ));

    return recommendationsAsync.when(
      data: (recs) {
        if (recs.isEmpty) {
          return Center(child: Text('No relevant matches found nearby.', style: GoogleFonts.outfit()));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: recs.length,
          itemBuilder: (context, index) {
            final rec = recs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), 
                    blurRadius: 10, 
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                       const Icon(Icons.auto_awesome, color: Colors.amber),
                       const SizedBox(width: 8),
                       Text('Match #${index + 1}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.deepGreen)),
                    ]
                   ),
                   const SizedBox(height: 12),
                   Text(rec.aiReasoning, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4)),
                   const SizedBox(height: 12),
                   Align(
                     alignment: Alignment.centerRight,
                     child: TextButton.icon(
                       onPressed: () { 
                         // Logic to navigate to shop using rec.businessId
                       },
                       icon: const Icon(Icons.storefront, size: 16),
                       label: const Text('View Shop'),
                     )
                   )
                ],
              ),
            );
          },
        );
      },
      loading: () => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('AI is scanning local shops...', style: GoogleFonts.outfit(color: Colors.grey)),
        ],
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('AI Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
