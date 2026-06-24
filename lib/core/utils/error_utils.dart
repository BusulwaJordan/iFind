import 'dart:io';

String friendlyError(Object e) {
  final msg = e.toString().toLowerCase();
  if (e is SocketException || msg.contains('no internet') || msg.contains('failed host lookup')) {
    return 'No internet connection. Check your network and try again.';
  }
  if (msg.contains('timeout') || msg.contains('timed out')) {
    return 'Request timed out. Please try again.';
  }
  if (msg.contains('401') || msg.contains('unauthorized') || msg.contains('unauthenticated')) {
    return 'Session expired. Please sign in again.';
  }
  if (msg.contains('403') || msg.contains('forbidden') || msg.contains('permission')) {
    return 'You don\'t have permission to do that.';
  }
  if (msg.contains('404') || msg.contains('not found')) {
    return 'The requested item could not be found.';
  }
  if (msg.contains('500') || msg.contains('server error') || msg.contains('internal')) {
    return 'Server error. Please try again later.';
  }
  if (msg.contains('postgrest') || msg.contains('supabase')) {
    return 'Server error. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
