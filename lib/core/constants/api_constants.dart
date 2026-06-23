import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  // Supabase Configuration
  // Prefer build-time defines for CI/release builds, then local .env for dev.
  static String get supabaseUrl {
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    return fromDefine.isNotEmpty
        ? fromDefine
        : dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    return fromDefine.isNotEmpty
        ? fromDefine
        : dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static const String appUpdateManifestUrl =
      'https://pub-731188e08dc6400ba34b53ac6113afcc.r2.dev/latest.json';

  // Table Names
  static const String usersTable = 'users';
  static const String businessesTable = 'businesses';
  static const String productsTable = 'products';
  static const String arcadesTable = 'arcades';
  static const String shopsTable = 'shops';
  static const String reviewsTable = 'reviews';
  static const String chatsTable = 'chats';
  static const String messagesTable = 'messages';
  static const String recommendationsTable = 'recommendations';
  // Storage Buckets
  static const String businessImagesBucket = 'business_images';
  static const String productImagesBucket = 'product_images';
  static const String profileImagesBucket = 'profile_images';

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 2);
}
