import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles auth deep links from email verification and OAuth callbacks.
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  Future<void> initialize() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleAuthUri(initialUri);
    }

    _appLinks.uriLinkStream.listen(
      (uri) => _handleAuthUri(uri),
      onError: (Object error) => debugPrint('Deep link stream error: $error'),
    );
  }

  Future<void> _handleAuthUri(Uri uri) async {
    final isAuthLink = uri.host == 'auth' || uri.host == 'login-callback';
    if (!isAuthLink) return;

    try {
      // This establishes the session from the email verification link
      // The auth state listener in AuthNotifier will automatically pick this up
      // and update the auth state, triggering a redirect to home via the router
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      debugPrint('Auth session established via deep link - email verified');
    } catch (e) {
      debugPrint('Failed to handle auth deep link: $e');
    }
  }
}
