// ═══════════════════════════════════════════════════════════════
// src/services/ai-vision-service.js — Gemini AI Vision Sınav & Ödev Analiz Motoru
// ═══════════════════════════════════════════════════════════════
'use strict';

/**
 * Optik form veya test kağıdı fotoğrafını yapay zeka ile analiz eder.
 * @param {string} imageBase64 - Fotoğrafın base64 verisi
 * @param {string} [subjectHint] - İsteğe bağlı ders adı ipucu
 */
async function analyzeExamPhoto(imageBase64, subjectHint = 'Matematik') {
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY') {
    return {
      success: false,
      error: 'GEMINI_API_KEY yapılandırılmamış. Sahte analiz döndürülmez.',
      subject: subjectHint,
    };
  }

  try {
    const { GoogleGenAI } = require('@google/genai');
    const ai = new GoogleGenAI({ apiKey });

    const prompt = `Sen bir eğitim ve sınav analiz uzmanısın. Bu fotoğraftaki optik formu veya test kağıdını incele.
Ders adı: ${subjectHint}.
Fotoğraftan:
1. Doğru Sayısı (correctCount)
2. Yanlış Sayısı (wrongCount)
3. Boş Sayısı (emptyCount)
4. Toplam Soru Sayısı (totalQuestions)
bilgilerini tespit et.
4 yanlış 1 doğruyu götürür kuralıyla net sayısını (net = correctCount - wrongCount / 4) hesapla.
Yanıtını kesinlikle sadece şu JSON formatında dön:
{
  "subject": "${subjectHint}",
  "correctCount": number,
  "wrongCount": number,
  "emptyCount": number,
  "totalQuestions": number,
  "net": number,
  "score": number,
  "confidence": number (0-1 arası),
  "notes": "Analiz açıklaması"
}`;

    const response = await ai.models.generateContent({
      model: 'gemini-1.5-flash',
      contents: [
        prompt,
        {
          inlineData: {
            mimeType: 'image/jpeg',
            data: imageBase64.replace(/^data:image\/\w+;base64,/, ''),
          },
        },
      ],
    });

    const text = response.text;
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return { success: true, ...parsed };
    }

    return {
      success: false,
      error: 'AI yanıtı ayrıştırılamadı.',
      subject: subjectHint,
    };
  } catch (err) {
    console.error('❌ Gemini AI Vision Analiz Hatası:', err.message);
    return {
      success: false,
      error: err.message || 'AI analiz başarısız.',
      subject: subjectHint,
    };
  }
}

module.exports = {
  analyzeExamPhoto,
};
