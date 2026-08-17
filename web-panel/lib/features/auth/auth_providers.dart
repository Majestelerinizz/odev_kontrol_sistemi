import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AdminUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentAdminProvider = Provider<AdminUser?>((ref) {
  return ref.watch(authStateProvider).value;
});
