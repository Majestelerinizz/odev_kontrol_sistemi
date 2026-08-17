import 'package:cloud_firestore/cloud_firestore.dart';

/// Sayfalı Firestore sorguları için cursor tabanlı sonuç.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });

  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

class PaginationCursor {
  const PaginationCursor({this.lastDocument});

  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
}
