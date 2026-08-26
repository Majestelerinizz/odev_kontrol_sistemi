import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../classes/presentation/providers/class_providers.dart';
import '../../../students/presentation/providers/student_providers.dart';
import '../providers/exam_providers.dart';
import '../../domain/entities/exam_result_entity.dart';

class CreateExamResultScreen extends ConsumerStatefulWidget {
  const CreateExamResultScreen({super.key});

  @override
  ConsumerState<CreateExamResultScreen> createState() =>
      _CreateExamResultScreenState();
}

class _CreateExamResultScreenState
    extends ConsumerState<CreateExamResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();
  final _publisherController = TextEditingController();
  final _totalScoreController = TextEditingController();

  String? _selectedClassId;
  String? _selectedStudentId;
  DateTime _examDate = DateTime.now();

  final Map<String, TextEditingController> _correctControllers = {};
  final Map<String, TextEditingController> _wrongControllers = {};
  final Map<String, TextEditingController> _blankControllers = {};

  final List<String> _subjects = [
    'Matematik',
    'Türkçe',
    'Fen Bilimleri',
    'Sosyal Bilgiler',
    'İngilizce',
    'Din Kültürü',
  ];

  @override
  void initState() {
    super.initState();
    for (final s in _subjects) {
      _correctControllers[s] = TextEditingController(text: '0');
      _wrongControllers[s] = TextEditingController(text: '0');
      _blankControllers[s] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _examNameController.dispose();
    _publisherController.dispose();
    _totalScoreController.dispose();
    for (final c in _correctControllers.values) {
      c.dispose();
    }
    for (final w in _wrongControllers.values) {
      w.dispose();
    }
    for (final b in _blankControllers.values) {
      b.dispose();
    }
    super.dispose();
  }

  double _calculateTotalNet() {
    double sum = 0.0;
    for (final s in _subjects) {
      final c = int.tryParse(_correctControllers[s]?.text ?? '0') ?? 0;
      final w = int.tryParse(_wrongControllers[s]?.text ?? '0') ?? 0;
      sum += NetCalculator.calculate(c, w);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(teacherClassesStreamProvider);
    final user = ref.watch(currentUserProvider);
    final examState = ref.watch(examNotifierProvider);

    final totalNet = _calculateTotalNet();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Deneme Sonucu Gir'),
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(child: Text('Önce bir sınıf eklemelisiniz.'));
          }

          _selectedClassId ??= classes.first.id;
          final studentsAsync = ref.watch(classStudentsStreamProvider(
            (classId: _selectedClassId!, teacherId: user?.uid ?? ''),
          ));

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sınıf Seçimi ──────────────────────────────────────────
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClassId,
                    decoration: InputDecoration(
                      labelText: 'Sınıf Seçin',
                      prefixIcon: const Icon(Icons.group_rounded),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.inputRadius),
                      ),
                    ),
                    items: classes
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedClassId = val;
                          _selectedStudentId = null;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Öğrenci Seçimi ─────────────────────────────────────────
                  studentsAsync.when(
                    data: (students) {
                      if (students.isEmpty) {
                        return const Text('Bu sınıfta henüz öğrenci kaydı yok.',
                            style: TextStyle(color: AppColors.warning));
                      }
                      _selectedStudentId ??= students.first.id;

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedStudentId,
                        decoration: InputDecoration(
                          labelText: 'Öğrenci Seçin',
                          prefixIcon: const Icon(Icons.person_rounded),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.inputRadius),
                          ),
                        ),
                        items: students
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text('${s.name} (${s.schoolNumber})'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStudentId = val);
                          }
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, __) => Text('Öğrenciler okunamadı: $err'),
                  ),

                  const SizedBox(height: 16),

                  // ── Deneme Adı & Yayınevi ────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _examNameController,
                          label: 'Sınav Adı',
                          hint: 'Örn: Deneme 4',
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Zorunlu'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _publisherController,
                          label: 'Yayınevi',
                          hint: 'Örn: Özdebir',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Toplam Puan & Tarih ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _totalScoreController,
                          label: 'Toplam Puan',
                          hint: 'Örn: 425.5',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sınav Tarihi',
                                style: AppTextStyles.inputLabel),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _examDate,
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _examDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.inputRadius),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(_examDate.toTurkishDate(),
                                    style: AppTextStyles.bodyMedium),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Anlık Canlı Toplam Net Kartı ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.teacherPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                      border: Border.all(
                          color:
                              AppColors.teacherPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hesaplanan Toplam Net:', style: AppTextStyles.h4),
                        Text(
                          totalNet.toStringAsFixed(2),
                          style: AppTextStyles.h2
                              .copyWith(color: AppColors.teacherPrimary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text('Ders Bazlı Sonuçlar (D / Y / B)',
                      style: AppTextStyles.h4),
                  const SizedBox(height: 10),

                  // ── Ders Input Listesi ─────────────────────────────────────
                  ..._subjects.map((subject) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.cardRadius),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subject, style: AppTextStyles.labelLarge),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _correctControllers[subject],
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                      labelText: 'Doğru',
                                      prefixIcon: Icon(Icons.check_circle,
                                          color: AppColors.success, size: 18)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _wrongControllers[subject],
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                      labelText: 'Yanlış',
                                      prefixIcon: Icon(Icons.cancel,
                                          color: AppColors.error, size: 18)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _blankControllers[subject],
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                      labelText: 'Boş',
                                      prefixIcon: Icon(Icons.help_outline,
                                          color: AppColors.warning, size: 18)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  PrimaryButton(
                    label: 'Sınav Sonucunu Kaydet',
                    isLoading: examState.isLoading,
                    icon: Icons.save_rounded,
                    onPressed: () async {
                      if (_formKey.currentState!.validate() &&
                          _selectedClassId != null &&
                          _selectedStudentId != null) {
                        final scoresMap = <String, SubjectScore>{};
                        for (final s in _subjects) {
                          final c = int.tryParse(
                                  _correctControllers[s]?.text ?? '0') ??
                              0;
                          final w =
                              int.tryParse(_wrongControllers[s]?.text ?? '0') ??
                                  0;
                          final b =
                              int.tryParse(_blankControllers[s]?.text ?? '0') ??
                                  0;
                          scoresMap[s] = SubjectScore(
                            correct: c,
                            wrong: w,
                            blank: b,
                            net: NetCalculator.calculate(c, w),
                          );
                        }

                        final totalScore = double.tryParse(
                                _totalScoreController.text.trim()) ??
                            0.0;

                        final success = await ref
                            .read(examNotifierProvider.notifier)
                            .addExamResult(
                              studentId: _selectedStudentId!,
                              classId: _selectedClassId!,
                              teacherId: user?.uid ?? '',
                              examName: _examNameController.text.trim(),
                              publisher:
                                  _publisherController.text.trim().isEmpty
                                      ? null
                                      : _publisherController.text.trim(),
                              examDate: _examDate,
                              scores: scoresMap,
                              totalNet: totalNet,
                              totalScore: totalScore,
                            );

                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Sınav sonucu kaydedildi!')),
                          );
                          context.pop();
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Sınıflar yüklenemedi: $err')),
      ),
    );
  }
}
