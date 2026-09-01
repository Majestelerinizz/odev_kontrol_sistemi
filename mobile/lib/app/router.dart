import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/auth/presentation/screens/teacher_auth_flow_screen.dart';
import '../features/auth/presentation/screens/parent_auth_flow_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/dashboard/presentation/screens/teacher_home_screen.dart';
import '../features/dashboard/presentation/screens/parent_home_screen.dart';

import '../features/classes/presentation/screens/class_list_screen.dart';
import '../features/classes/presentation/screens/class_detail_screen.dart';
import '../features/students/presentation/screens/student_detail_screen.dart';
import '../features/homeworks/presentation/screens/teacher_homework_list_screen.dart';
import '../features/homeworks/presentation/screens/create_homework_screen.dart';
import '../features/homeworks/presentation/screens/homework_detail_screen.dart';
import '../features/homeworks/presentation/screens/parent_homework_list_screen.dart';
import '../features/exams/presentation/screens/teacher_exam_list_screen.dart';
import '../features/exams/presentation/screens/create_exam_result_screen.dart';
import '../features/analytics/presentation/screens/analytics_graph_screen.dart';
import '../features/exams/presentation/screens/parent_exam_list_screen.dart';
import '../features/messages/presentation/screens/teacher_new_message_screen.dart';
import '../features/messages/presentation/screens/teacher_messages_history_screen.dart';
import '../features/messages/presentation/screens/parent_messages_list_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';

/// GoRouter'ı auth değişiminde yeniden yaratmadan yenilemek için.
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Uygulama router'ı.
/// GoRouter ile rol tabanlı yönlendirme ve RoleGuard mantığı.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(authStateProvider, (_, __) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final user = authState.valueOrNull;
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final location = state.uri.toString();

      final isAuthPage = location.startsWith('/auth') ||
          location.startsWith('/role-selection') ||
          location.startsWith('/forgot-password') ||
          location.startsWith('/welcome') ||
          location.startsWith('/splash') ||
          location.startsWith('/join');

      // Stream / profil yüklenirken welcome'a atma
      if (authState.isLoading) return null;

      // Auth oturumu var, Firestore profili henüz yok — korumalı rotaya alma
      if (firebaseUser != null && user == null) {
        if (isAuthPage) return null;
        return '/splash';
      }

      final isLoggedIn = user != null;

      if (!isLoggedIn && (location == '/splash' || location == '/')) {
        return '/welcome';
      }

      if (!isLoggedIn && !isAuthPage) return '/welcome';

      if (isLoggedIn) {
        if (isAuthPage) {
          return user.isTeacher ? '/teacher/home' : '/parent/home';
        }

        if (user.isTeacher && location.startsWith('/parent')) {
          return '/teacher/home';
        }
        if (user.isParent && location.startsWith('/teacher')) {
          return '/parent/home';
        }
      }

      return null;
    },
    routes: [
      // ── Ortak rotalar ─────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/auth/teacher',
        builder: (context, state) => const TeacherAuthFlowScreen(),
      ),
      GoRoute(
        path: '/auth/parent',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          final studentId = state.uri.queryParameters['studentId'];
          if (code != null && code.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(invitePrefillProvider.notifier).setPrefill(
                    code: code,
                    studentId: studentId,
                  );
            });
          }
          return const ParentAuthFlowScreen();
        },
      ),
      GoRoute(
        path: '/join',
        redirect: (context, state) {
          final code = state.uri.queryParameters['code'];
          final studentId = state.uri.queryParameters['studentId'];
          final params = <String>[];
          if (code != null) params.add('code=$code');
          if (studentId != null) params.add('studentId=$studentId');
          final query = params.isEmpty ? '' : '?${params.join('&')}';
          return '/auth/parent$query';
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          final email = state.extra as String?;
          return ForgotPasswordScreen(initialEmail: email);
        },
      ),

      // ── Öğretmen rotaları ─────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return TeacherShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/teacher/home',
            builder: (context, state) => const TeacherHomeScreen(),
          ),
          GoRoute(
            path: '/teacher/classes',
            builder: (context, state) => const ClassListScreen(),
          ),
          GoRoute(
            path: '/teacher/classes/:classId',
            builder: (context, state) => ClassDetailScreen(
              classId: state.pathParameters['classId']!,
            ),
          ),
          GoRoute(
            path: '/teacher/students/:studentId',
            builder: (context, state) => StudentDetailScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
          GoRoute(
            path: '/teacher/homeworks',
            builder: (context, state) => const TeacherHomeworkListScreen(),
          ),
          GoRoute(
            path: '/teacher/homeworks/new',
            builder: (context, state) => const CreateHomeworkScreen(),
          ),
          GoRoute(
            path: '/teacher/homeworks/:homeworkId',
            builder: (context, state) => HomeworkDetailScreen(
              homeworkId: state.pathParameters['homeworkId']!,
            ),
          ),
          GoRoute(
            path: '/teacher/exams',
            builder: (context, state) => const TeacherExamListScreen(),
          ),
          GoRoute(
            path: '/teacher/exams/create',
            builder: (context, state) => const CreateExamResultScreen(),
          ),
          GoRoute(
            path: '/teacher/analytics/:studentId',
            builder: (context, state) => AnalyticsGraphScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
          GoRoute(
            path: '/teacher/messages',
            builder: (context, state) => const TeacherMessagesHistoryScreen(),
          ),
          GoRoute(
            path: '/teacher/messages/new',
            builder: (context, state) => const TeacherNewMessageScreen(),
          ),
          GoRoute(
            path: '/teacher/more',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Veli rotaları ─────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return ParentShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/parent/home',
            builder: (context, state) => const ParentHomeScreen(),
          ),
          GoRoute(
            path: '/parent/homeworks',
            builder: (context, state) => const ParentHomeworkListScreen(),
          ),
          GoRoute(
            path: '/parent/exams',
            builder: (context, state) => const ParentExamListScreen(),
          ),
          GoRoute(
            path: '/parent/messages',
            builder: (context, state) => const ParentMessagesListScreen(),
          ),
          GoRoute(
            path: '/parent/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Sayfa bulunamadı: ${state.uri}'),
      ),
    ),
  );
});

// ── Öğretmen Shell (Bottom Navigation) ───────────────────────────────────────

class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getTeacherIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onTeacherNav(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Öğrenciler',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Ödevler',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Sonuçlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'Diğer',
          ),
        ],
      ),
    );
  }

  int _getTeacherIndex(String location) {
    if (location.startsWith('/teacher/home')) return 0;
    if (location.startsWith('/teacher/classes') ||
        location.startsWith('/teacher/students')) {
      return 1;
    }
    if (location.startsWith('/teacher/homeworks')) return 2;
    if (location.startsWith('/teacher/exams')) return 3;
    return 4;
  }

  void _onTeacherNav(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/teacher/home');
      case 1:
        context.go('/teacher/classes');
      case 2:
        context.go('/teacher/homeworks');
      case 3:
        context.go('/teacher/exams');
      case 4:
        context.go('/teacher/more');
    }
  }
}

// ── Veli Shell (Bottom Navigation) ───────────────────────────────────────────

class ParentShell extends StatelessWidget {
  const ParentShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getParentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onParentNav(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Ödevler',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Sonuçlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message_rounded),
            label: 'Mesajlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  int _getParentIndex(String location) {
    if (location.startsWith('/parent/home')) return 0;
    if (location.startsWith('/parent/homeworks')) return 1;
    if (location.startsWith('/parent/exams')) return 2;
    if (location.startsWith('/parent/messages')) return 3;
    return 4;
  }

  void _onParentNav(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/parent/home');
      case 1:
        context.go('/parent/homeworks');
      case 2:
        context.go('/parent/exams');
      case 3:
        context.go('/parent/messages');
      case 4:
        context.go('/parent/profile');
    }
  }
}
