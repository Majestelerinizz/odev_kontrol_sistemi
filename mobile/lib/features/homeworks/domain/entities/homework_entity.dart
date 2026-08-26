import 'package:flutter/foundation.dart';

/// Ödev ana bilgilerini temsil eden domain entity.
@immutable
class HomeworkEntity {
  const HomeworkEntity({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.title,
    required this.subject,
    this.description,
    this.sourceName,
    this.questionRange,
    required this.dueDate,
    this.attachmentUrls = const [],
    this.assignedToAll = true,
    this.studentIds = const [],
    required this.createdAt,
  });

  final String id;
  final String teacherId;
  final String classId;
  final String title;
  final String subject; // Örn: 'Matematik', 'Türkçe'
  final String? description;
  final String? sourceName; // Örn: 'Bilgi Sarmal'
  final String? questionRange; // Örn: '1-40'
  final DateTime dueDate;
  final List<String> attachmentUrls;
  final bool assignedToAll;
  /// Atanan öğrenci id'leri (Firestore rules + veli okuma için denormalize).
  final List<String> studentIds;
  final DateTime createdAt;

  bool get isOverdue => DateTime.now().isAfter(dueDate);

  HomeworkEntity copyWith({
    String? id,
    String? teacherId,
    String? classId,
    String? title,
    String? subject,
    String? description,
    String? sourceName,
    String? questionRange,
    DateTime? dueDate,
    List<String>? attachmentUrls,
    bool? assignedToAll,
    List<String>? studentIds,
    DateTime? createdAt,
  }) {
    return HomeworkEntity(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      sourceName: sourceName ?? this.sourceName,
      questionRange: questionRange ?? this.questionRange,
      dueDate: dueDate ?? this.dueDate,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      assignedToAll: assignedToAll ?? this.assignedToAll,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
