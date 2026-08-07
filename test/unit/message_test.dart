import 'package:flutter_test/flutter_test.dart';
import 'package:odev_takip/features/messages/domain/entities/message_entity.dart';
import 'package:odev_takip/features/messages/data/models/message_model.dart';

void main() {
  group('MessageEntity Tests', () {
    final now = DateTime(2026, 8, 7, 10, 0);

    test('MessageEntity kopyalama (copyWith) ve eşitlik testi', () {
      final msg = MessageEntity(
        id: 'msg-1',
        teacherId: 'teacher-123',
        parentIds: const ['parent-1', 'parent-2'],
        studentIds: const ['student-1'],
        title: 'Ödev Hatırlatması',
        body: 'Yarına kadar 30 soru çözülecek.',
        type: MessageType.bulk,
        createdAt: now,
      );

      expect(msg.isTargetingParent('parent-1'), true);
      expect(msg.isTargetingParent('parent-3'), false);

      final updated = msg.copyWith(title: 'Güncellenmiş Başlık');
      expect(updated.title, 'Güncellenmiş Başlık');
      expect(updated.id, 'msg-1');
    });

    test('MessageModel Map serileştirme ve dönüştürme testi', () {
      final map = {
        'teacherId': 't-100',
        'teacherName': 'Ahmet Öğretmen',
        'parentIds': ['p-1', 'p-2'],
        'studentIds': ['s-1', 's-2'],
        'classId': 'c-8A',
        'className': '8-A Sınıfı',
        'title': 'Veli Toplantısı',
        'body': 'Cuma günü saat 15:00',
        'type': 'bulk',
        'createdAt': DateTime(2026, 8, 7, 12, 0),
      };

      final model = MessageModel.fromMap(map, 'msg-99');

      expect(model.id, 'msg-99');
      expect(model.teacherName, 'Ahmet Öğretmen');
      expect(model.type, MessageType.bulk);
      expect(model.parentIds.length, 2);

      final firestoreData = model.toFirestore();
      expect(firestoreData['title'], 'Veli Toplantısı');
      expect(firestoreData['type'], 'bulk');
    });
  });
}
