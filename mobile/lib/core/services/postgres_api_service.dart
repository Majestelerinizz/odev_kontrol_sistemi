/// Legacy PostgreSQL sync API — lansman yolunda kullanılmaz.
class PostgresApiService {
  PostgresApiService._();
  static final PostgresApiService instance = PostgresApiService._();

  static const bool enabled = false;

  Future<Map<String, dynamic>?> checkHealth() async => null;

  Future<Map<String, dynamic>?> getSyncStats() async => null;

  Future<bool> triggerFullSync() async => false;

  Future<List<Map<String, dynamic>>> fetchStudentsFromPostgres({
    String? teacherId,
    String? classId,
  }) async =>
      const [];

  Future<List<Map<String, dynamic>>> fetchExamResultsFromPostgres(
    String studentId,
  ) async =>
      const [];

  Future<List<Map<String, dynamic>>> fetchSyncLog({int limit = 20}) async =>
      const [];

  Future<bool> isBackendAlive() async => false;
}
