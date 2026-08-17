import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchDashboardStats();
});

final teachersPickerProvider = FutureProvider<List<TeacherSummary>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchAllTeachersForPicker();
});

final activityProvider = FutureProvider<List<ActivityItem>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchRecentActivity();
});

class BroadcastService {
  BroadcastService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> sendBroadcast({
    required String title,
    required String body,
    required BroadcastAudience audience,
    String? teacherId,
  }) async {
    final callable = _functions.httpsCallable('sendBroadcast');
    final result = await callable.call<Map<String, dynamic>>({
      'title': title,
      'body': body,
      'audience': audience.value,
      if (teacherId != null) 'teacherId': teacherId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<int> estimateTargets({
    required BroadcastAudience audience,
    String? teacherId,
    required AdminRepository repository,
  }) {
    return repository.countBroadcastTargets(
      audience: audience.value,
      teacherId: teacherId,
    );
  }
}

final broadcastServiceProvider = Provider<BroadcastService>((ref) {
  return BroadcastService();
});
