import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
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

    // Firestore batch max 500 ops: 1 message + N notifications
    final firstBatch = _firestore.batch();
    firstBatch.set(messageRef, messageModel.toFirestore());

    var index = 0;
    const roomForNotifs = 449;
    final firstEnd = uniqueParentIds.length < roomForNotifs
        ? uniqueParentIds.length
        : roomForNotifs;
    for (; index < firstEnd; index++) {
      final notifRef = _firestore.collection('notifications').doc();
      firstBatch.set(notifRef, {
        'userId': uniqueParentIds[index],
        'title': title,
        'body': body,
        'type': 'message',
        'data': {'messageId': messageRef.id},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await firstBatch.commit();

    while (index < uniqueParentIds.length) {
      final batch = _firestore.batch();
      final end = (index + 450) > uniqueParentIds.length
          ? uniqueParentIds.length
          : index + 450;
      for (; index < end; index++) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': uniqueParentIds[index],
          'title': title,
          'body': body,
          'type': 'message',
          'data': {'messageId': messageRef.id},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  /// Öğretmenin gönderdiği tüm mesajlar akışı
  Stream<List<MessageEntity>> getTeacherMessagesStream(String teacherId) {
    return _firestore
        .collection('messages')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  /// Velinin aldığı tüm öğretmen mesajları akışı
  Stream<List<MessageEntity>> getParentMessagesStream(String parentId) {
    return _firestore
        .collection('messages')
        .where('parentIds', arrayContains: parentId)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }
}
