import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  // Supabase Configuration
  // Strictly loaded from environment variables (.env)
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

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
