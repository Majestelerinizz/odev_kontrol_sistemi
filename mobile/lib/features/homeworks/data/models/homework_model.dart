import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/homework_entity.dart';

/// Firestore ile entegre HomeworkModel
class HomeworkModel extends HomeworkEntity {
  const HomeworkModel({
    required super.id,
    required super.teacherId,
    required super.classId,
    required super.title,
    required super.subject,
    super.description,
    super.sourceName,
    super.questionRange,
    required super.dueDate,
    super.attachmentUrls,
    super.assignedToAll,
    required super.createdAt,
  });

  factory HomeworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawAttachments = data['attachmentUrls'] as List<dynamic>? ?? [];
    return HomeworkModel(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      subject: data['subject'] as String? ?? 'Matematik',
      description: data['description'] as String?,
      sourceName: data['sourceName'] as String?,
      questionRange: data['questionRange'] as String?,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachmentUrls: rawAttachments.map((e) => e.toString()).toList(),
      assignedToAll: data['assignedToAll'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teacherId': teacherId,
      'classId': classId,
      'title': title,
      'subject': subject,
      'description': description,
      'sourceName': sourceName,
      'questionRange': questionRange,
      'dueDate': Timestamp.fromDate(dueDate),
      'attachmentUrls': attachmentUrls,
      'assignedToAll': assignedToAll,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
