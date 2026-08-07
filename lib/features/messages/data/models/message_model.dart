import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.teacherId,
    super.teacherName,
    required super.parentIds,
    required super.studentIds,
    super.classId,
    super.className,
    required super.title,
    required super.body,
    super.type,
    required super.createdAt,
  });

  factory MessageModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MessageModel(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      teacherName: data['teacherName'] as String?,
      parentIds: List<String>.from(data['parentIds'] as List? ?? []),
      studentIds: List<String>.from(data['studentIds'] as List? ?? []),
      classId: data['classId'] as String?,
      className: data['className'] as String?,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: MessageType.fromString(data['type'] as String? ?? 'bulk'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String?,
      parentIds: List<String>.from(map['parentIds'] as List? ?? []),
      studentIds: List<String>.from(map['studentIds'] as List? ?? []),
      classId: map['classId'] as String?,
      className: map['className'] as String?,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: MessageType.fromString(map['type'] as String? ?? 'bulk'),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teacherId': teacherId,
      if (teacherName != null) 'teacherName': teacherName,
      'parentIds': parentIds,
      'studentIds': studentIds,
      if (classId != null) 'classId': classId,
      if (className != null) 'className': className,
      'title': title,
      'body': body,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      teacherId: entity.teacherId,
      teacherName: entity.teacherName,
      parentIds: entity.parentIds,
      studentIds: entity.studentIds,
      classId: entity.classId,
      className: entity.className,
      title: entity.title,
      body: entity.body,
      type: entity.type,
      createdAt: entity.createdAt,
    );
  }
}
