import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  late final GenerativeModel _model;
  AiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY';
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  /// Analyzes a user's raw text need to extract structured data
  /// Returns a map with {category, urgency, tags}
  Future<Map<String, dynamic>> analyzeNeed(String text) async {
    final prompt = '''
    Analyze this user request: "$text"
    Return ONLY a JSON object with:
    - category: string (one of: food, service, retail, unknown)
    - urgency: string (high, medium, low)
    - tags: list of strings (keywords)
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final textResponse = response.text;
      
      if (textResponse != null) {
        // Find JSON block if AI wrapped it in markdown
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(textResponse);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          return json.decode(jsonStr) as Map<String, dynamic>;
        }
      }
      return _mockParse(text); 
    } catch (e) {
      return _mockParse(text); // Fallback
    }
  }

  // Fallback parser since we don't have a real API key yet usually
  Map<String, dynamic> _mockParse(String text) {
    if (text.toLowerCase().contains('cake') || text.toLowerCase().contains('food')) {
      return {'category': 'food', 'urgency': 'medium', 'tags': ['food', 'cake']};
    }
    return {'category': 'service', 'urgency': 'low', 'tags': []};
  }
}
