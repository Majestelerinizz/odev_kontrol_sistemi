import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/services/ai_vision_service.dart';

/// MatPusula — AI Vision Yapay Zeka ile Fotoğraftan Ödev ve Deneme Analiz Ekranı
class AiExamScannerScreen extends ConsumerStatefulWidget {
  const AiExamScannerScreen({super.key});

  @override
  ConsumerState<AiExamScannerScreen> createState() => _AiExamScannerScreenState();
}

class _AiExamScannerScreenState extends ConsumerState<AiExamScannerScreen> {
  bool _isScanning = false;
  Map<String, dynamic>? _analysisResult;
  String _selectedSubject = 'Matematik';

  final List<String> _subjects = [
    'Matematik',
    'Türkçe',
    'Fen Bilimleri',
    'Sosyal Bilgiler',
    'İngilizce',
  ];

  Future<void> _startAiScan() async {
    setState(() {
      _isScanning = true;
      _analysisResult = null;
    });

    // Yapay zeka tarama simülasyonu gecikmesi
    await Future.delayed(const Duration(seconds: 2));

    final result = await AiVisionService.analyzeExamPhoto(
      imageBase64: 'sample_base64_data',
      subject: _selectedSubject,
    );

    if (mounted) {
      setState(() {
        _isScanning = false;
        _analysisResult = result;
      });
      context.showSnackBar('✨ Gemini AI Yapay Zeka fotoğraf analizini tamamladı!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '📷 AI Fotoğraf Analizi',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Üst Bilgi Kartı ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.teacherPrimary, Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yapay Zeka Sınav Tarayıcı',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Test kağıdı veya optik formun fotoğrafını çekin, Gemini AI netlerinizi saniyeler içinde hesaplasın.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Ders Seçimi ────────────────────────────────────────────
              Text('Ders Seçiniz', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedSubject,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSubject = val);
                },
              ),

              const SizedBox(height: 20),

              // ── Fotoğraf Çek / Yükle Alanı ──────────────────────────────
              GestureDetector(
                onTap: _isScanning ? null : _startAiScan,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.teacherPrimary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: _isScanning
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.teacherPrimary),
                            SizedBox(height: 16),
                            Text(
                              'Gemini AI Fotoğrafı Analiz Ediyor...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.teacherPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Doğru, yanlış ve net sayıları çıkarılıyor',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.teacherPrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_enhance_rounded,
                                size: 48,
                                color: AppColors.teacherPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Fotoğraf Çek veya Galeriden Seç',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Test sayfasını net bir açıyla hizalayın',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Yapay Zeka Sonuç Kartı ──────────────────────────────────
              if (_analysisResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(
                            'AI Analiz Sonucu (${_analysisResult!['subject']})',
                            style: AppTextStyles.h4,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatBadge('Doğru', '${_analysisResult!['correctCount']}', AppColors.success),
                          _buildStatBadge('Yanlış', '${_analysisResult!['wrongCount']}', AppColors.error),
                          _buildStatBadge('Boş', '${_analysisResult!['emptyCount']}', AppColors.warning),
                          _buildStatBadge('Net', '${_analysisResult!['net']}', AppColors.teacherPrimary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '💡 ${_analysisResult!['notes']}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Netleri Sınav Formuna Aktar',
                        onPressed: () {
                          context.showSnackBar('Netler deneme sınavı formuna aktarıldı!');
                          context.pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
