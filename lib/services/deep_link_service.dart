import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  /// Callback invoked when a group join token is received.
  void Function(String token)? onGroupJoinToken;

  Future<void> init() async {
    // Handle the initial link if the app was launched from a deep link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    // Listen for subsequent deep links while the app is running
    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    // Handle: findyourtwo.org/join-group/?token=...
    if (uri.path.contains('join-group')) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        onGroupJoinToken?.call(token);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
