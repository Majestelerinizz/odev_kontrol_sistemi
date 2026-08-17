import 'package:equatable/equatable.dart';

enum MessageType {
  bulk,
  individual;

  String get label {
    switch (this) {
      case MessageType.bulk:
        return 'Toplu Duyuru';
      case MessageType.individual:
        return 'Bireysel Mesaj';
    }
  }

  static MessageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'individual':
        return MessageType.individual;
      case 'bulk':
      default:
        return MessageType.bulk;
    }
  }
}

/// Veliye veya sınıfa gönderilen öğretmen mesaj/duyuru varlığı
class MessageEntity extends Equatable {
  final String id;
  final String teacherId;
  final String? teacherName;
  final List<String> parentIds;
  final List<String> studentIds;
  final String? classId;
  final String? className;
  final String title;
  final String body;
  final MessageType type;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.teacherId,
    this.teacherName,
    required this.parentIds,
    required this.studentIds,
    this.classId,
    this.className,
    required this.title,
    required this.body,
    this.type = MessageType.bulk,
    required this.createdAt,
  });

  bool isTargetingParent(String parentId) => parentIds.contains(parentId);

  MessageEntity copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    List<String>? parentIds,
    List<String>? studentIds,
    String? classId,
    String? className,
    String? title,
    String? body,
    MessageType? type,
    DateTime? createdAt,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      parentIds: parentIds ?? this.parentIds,
      studentIds: studentIds ?? this.studentIds,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        teacherId,
        teacherName,
        parentIds,
        studentIds,
        classId,
        className,
        title,
        body,
        type,
        createdAt,
      ];
}
