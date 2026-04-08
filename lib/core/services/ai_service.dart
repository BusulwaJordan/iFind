import 'dart:convert';
import 'package:flutter/foundation.dart';
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
          final result = json.decode(jsonStr) as Map<String, dynamic>;
          debugPrint('AI Analysis Success: $result');
          return result;
        }
      }
      
      // If we got a response but couldn't parse it, log and throw
      debugPrint('AI returned unparseable response: $textResponse');
      throw Exception('AI response could not be parsed as JSON');
    } catch (e) {
      debugPrint('AI Service Error: $e');
      // Re-throw the error so caller can handle it
      rethrow;
    }
  }

  /// Takes a user intent and a raw JSON list of businesses and returns top ranked items
  Future<List<Map<String, dynamic>>> rankNearbyBusinesses(String intent, List<Map<String, dynamic>> businesses) async {
    final prompt = '''
    You are a local business hyper-assistant. 
    A user's intent is: "$intent".
    Here is a JSON list of nearby businesses:
    ${jsonEncode(businesses)}

    Analyze the user's intent against these businesses (look at name, description, category, and distance).
    Return ONLY a JSON array of the top 3 matching businesses in this exact format:
    [
      {
        "business_id": "the uuid",
        "reason": "1 short sentence why this is a good match based on their intent."
      }
    ]
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final textResponse = response.text;
      
      if (textResponse != null) {
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(textResponse);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          final List<dynamic> result = json.decode(jsonStr);
          return List<Map<String, dynamic>>.from(result);
        }
      }
      throw Exception('Could not parse array from AI');
    } catch (e) {
      debugPrint('AI Ranking Error: $e');
      rethrow;
    }
  }
}
