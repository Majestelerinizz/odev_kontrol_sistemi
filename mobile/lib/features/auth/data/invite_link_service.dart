import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/auth_providers.dart';

/// Davet linki: https://eduly-server.web.app/join?code=OT-XXXX&studentId=optional
class InviteLinkService {
  InviteLinkService(this._ref);

  final Ref _ref;
  final AppLinks _appLinks = AppLinks();

  Future<void> initialize() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);

      _appLinks.uriLinkStream.listen(_handleUri, onError: (Object e) {
        debugPrint('Invite link error: $e');
      });
    } catch (e) {
      debugPrint('Invite link init: $e');
    }
  }

  void handleUri(Uri uri) => _handleUri(uri);

  void _handleUri(Uri uri) {
    if (!_isJoinLink(uri)) return;

    final code = uri.queryParameters['code']?.trim().toUpperCase();
    final studentId = uri.queryParameters['studentId']?.trim();

    if (code == null || code.isEmpty) return;

    _ref.read(invitePrefillProvider.notifier).setPrefill(
          code: code,
          studentId: studentId,
        );
  }

  bool _isJoinLink(Uri uri) {
    final path = uri.path.toLowerCase();
    return path == '/join' ||
        path.endsWith('/join') ||
        uri.host.contains('eduly-server');
  }
}

final inviteLinkServiceProvider = Provider<InviteLinkService>((ref) {
  return InviteLinkService(ref);
});
