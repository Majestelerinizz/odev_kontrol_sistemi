import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/messages_repository.dart';
import '../../domain/entities/message_entity.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository();
});

/// Öğretmenin attığı duyuru mesajları akışı
final teacherMessagesStreamProvider =
    StreamProvider.autoDispose<List<MessageEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isTeacher) {
    return Stream.value([]);
  }
  final repo = ref.watch(messagesRepositoryProvider);
  return repo.getTeacherMessagesStream(user.uid);
});

/// Velinin aldığı öğretmen mesajları akışı
final parentMessagesStreamProvider =
    StreamProvider.autoDispose<List<MessageEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isParent) {
    return Stream.value([]);
  }
  final repo = ref.watch(messagesRepositoryProvider);
  return repo.getParentMessagesStream(user.uid);
});
