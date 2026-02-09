class ApiConstants {
  ApiConstants._();

  // Supabase Configuration
  // IMPORTANT: These should be loaded from environment variables in production
  // For now, placeholders that will be replaced with actual values
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yykzwfzlibszwldawgex.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5a3p3ZnpsaWJzendsZGF3Z2V4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NDEyMTEsImV4cCI6MjA4NjIxNzIxMX0.XMGb8dpBuzP66F8mPu6j2V-1gdQYbY5x4-ywPIdNn5s',
  );

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
