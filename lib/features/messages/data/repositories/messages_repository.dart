import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message_entity.dart';
import '../models/message_model.dart';

class MessagesRepository {
  final FirebaseFirestore _firestore;

  MessagesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Toplu veya Bireysel Mesaj Gönderimi
  Future<void> sendMessage({
    required String teacherId,
    String? teacherName,
    String? classId,
    String? className,
    String? targetStudentId,
    required String title,
    required String body,
  }) async {
    List<String> targetParentIds = [];
    List<String> targetStudentIds = [];

    if (targetStudentId != null) {
      // Tek öğrenciye özel mesaj
      final studentDoc =
          await _firestore.collection('students').doc(targetStudentId).get();
      if (studentDoc.exists) {
        final data = studentDoc.data() ?? {};
        targetStudentIds.add(targetStudentId);
        final parents = List<String>.from(data['parentIds'] as List? ?? []);
        targetParentIds.addAll(parents);
      }
    } else if (classId != null) {
      // Belirli bir sınıfa toplu duyuru
      final studentsSnap = await _firestore
          .collection('students')
          .where('classId', isEqualTo: classId)
          .where('teacherId', isEqualTo: teacherId)
          .get();

      for (final doc in studentsSnap.docs) {
        targetStudentIds.add(doc.id);
        final parents = List<String>.from(doc.data()['parentIds'] as List? ?? []);
        targetParentIds.addAll(parents);
      }
    } else {
      // Öğretmenin tüm sınıflarına/öğrencilerine toplu duyuru
      final studentsSnap = await _firestore
          .collection('students')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      for (final doc in studentsSnap.docs) {
        targetStudentIds.add(doc.id);
        final parents = List<String>.from(doc.data()['parentIds'] as List? ?? []);
        targetParentIds.addAll(parents);
      }
    }

    // Uniq parent ID'ler
    final uniqueParentIds = targetParentIds.toSet().toList();

    final messageRef = _firestore.collection('messages').doc();

    final messageModel = MessageModel(
      id: messageRef.id,
      teacherId: teacherId,
      teacherName: teacherName,
      parentIds: uniqueParentIds,
      studentIds: targetStudentIds,
      classId: classId,
      className: className,
      title: title,
      body: body,
      type: targetStudentId != null ? MessageType.individual : MessageType.bulk,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(messageRef, messageModel.toFirestore());

    // Velilere anlık uygulama içi bildirim (`notifications`) üret
    for (final parentId in uniqueParentIds) {
      final notifRef = _firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': parentId,
        'title': '📩 $title',
        'body': body,
        'type': 'message',
        'data': {'messageId': messageRef.id},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Öğretmenin gönderdiği tüm mesajlar akışı
  Stream<List<MessageEntity>> getTeacherMessagesStream(String teacherId) {
    return _firestore
        .collection('messages')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Velinin aldığı tüm öğretmen mesajları akışı
  Stream<List<MessageEntity>> getParentMessagesStream(String parentId) {
    return _firestore
        .collection('messages')
        .where('parentIds', arrayContains: parentId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
