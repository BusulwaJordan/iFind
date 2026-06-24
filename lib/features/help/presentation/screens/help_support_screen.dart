import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    _FAQ(
      question: 'How does iFind AI recommend businesses?',
      answer:
          'iFind uses a hybrid AI model that combines your interaction history (views, searches, saves, chats) with proximity data. The system scores businesses using category affinity (55%), ratings (25%), popularity (15%), and exploration factors (5%) to surface the most relevant results for you.',
    ),
    _FAQ(
      question: 'How is my location used?',
      answer:
          'Your GPS location is used only to find nearby businesses and calculate distances. You can adjust the search radius (1–50 km) using the Radius button on the Discover screen. We never share your location with third parties.',
    ),
    _FAQ(
      question: 'What are B2C Matches?',
      answer:
          'B2C Matches are AI-powered recommendations tailored to you as a customer. When you browse, search, or interact with businesses, the AI learns your preferences and suggests businesses you are likely to love. Access them via the "For You" section.',
    ),
    _FAQ(
      question: 'What are B2B Matches?',
      answer:
          'B2B Matches help business owners find complementary partner businesses. The AI analyses category compatibility and proximity to score how well two businesses could work together — for example, a fashion store and a beauty salon. Business owners access this from their shop profile.',
    ),
    _FAQ(
      question: 'How do I save a business to Favourites?',
      answer:
          'Open any business profile and tap the bookmark icon (top right). The business will be saved to your Favourites list, accessible from your Profile or Settings. You can remove it any time.',
    ),
    _FAQ(
      question: 'How do I post a need?',
      answer:
          'From the Home screen tap "Post a Need". Describe what you are looking for and nearby businesses will be notified. Interested businesses can respond via the chat. You will receive a notification when there is a match.',
    ),
    _FAQ(
      question: 'How do I contact a business?',
      answer:
          'Open the business profile and tap "INBOX" to start a chat, or tap the phone icon to call directly. Your chat history is saved under the Chat tab.',
    ),
    _FAQ(
      question: 'Why are my recommendations the same every time?',
      answer:
          'Recommendations improve as you use the app more. The AI needs at least a few interactions (profile views, chats, saves) to learn your preferences. Keep exploring and your "For You" picks will get more personalised over time.',
    ),
    _FAQ(
      question: 'How do I create my business profile?',
      answer:
          'Tap the B2B tab at the bottom, then "Create Shop". Fill in your business details, location, and upload photos. Once submitted, our team will verify your business within 24–48 hours.',
    ),
    _FAQ(
      question: 'How do I manage products and services?',
      answer:
          'Go to your shop dashboard and tap "Manage Products". You can add, edit, or remove products with images, descriptions, prices, and availability status.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.deepGreen,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.deepGreen, AppColors.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.help_outline_rounded,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'SUPPORT',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Help & Support',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Frequently asked questions',
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Contact card
                  _ContactCard(),
                  const SizedBox(height: 24),
                  Text(
                    'Frequently Asked Questions',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_faqs.map((faq) => _FAQTile(faq: faq))),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.1),
            AppColors.deepGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need more help?',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Our support team is available Mon–Fri, 8am–6pm EAT.',
            style:
                GoogleFonts.outfit(fontSize: 13, color: AppColors.lightText),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  icon: Icons.email_rounded,
                  label: 'Email Us',
                  color: Colors.blue,
                  onTap: () => launchUrl(
                      Uri.parse('mailto:support@ifind.ug')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: Colors.green,
                  onTap: () => launchUrl(
                      Uri.parse('https://wa.me/256700000000')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  const _FAQTile({required this.faq});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          onExpansionChanged: (v) => setState(() => _expanded = v),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _expanded
                  ? Icons.remove_rounded
                  : Icons.add_rounded,
              color: AppColors.primaryGreen,
              size: 16,
            ),
          ),
          trailing: const SizedBox.shrink(),
          title: Text(
            widget.faq.question,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.faq.answer,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.lightText,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQ {
  final String question;
  final String answer;
  const _FAQ({required this.question, required this.answer});
}
