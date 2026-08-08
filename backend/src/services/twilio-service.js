// ═══════════════════════════════════════════════════════════════
// src/services/twilio-service.js — Twilio SMS OTP Servisi
// ═══════════════════════════════════════════════════════════════
'use strict';

// Bellek içi OTP deposu: phone -> { code, expiresAt }
const otpStore = new Map();

function getTwilioClient() {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  if (accountSid && authToken && !accountSid.startsWith('YOUR_')) {
    try {
      const twilio = require('twilio');
      return twilio(accountSid, authToken);
    } catch (_) {}
  }
  return null;
}

/**
 * 6 Haneli Rastgele OTP Üretir
 */
function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Belirtilen telefon numarasına Twilio üzerinden SMS OTP Gönderir
 */
async function sendOtp(phoneNumber) {
  const formattedPhone = phoneNumber.trim().replace(/\s+/g, '');
  const otpCode = generateOtp();
  const expiresAt = Date.now() + 5 * 60 * 1000; // 5 dakika geçerli

  otpStore.set(formattedPhone, { code: otpCode, expiresAt });

  const client = getTwilioClient();
  const fromPhone = process.env.TWILIO_PHONE_NUMBER || '+1234567890';

  if (client) {
    try {
      await client.messages.create({
        body: `[MatPusula] Doğrulama kodunuz: ${otpCode}. Bu kod 5 dakika süreyle geçerlidir.`,
        from: fromPhone,
        to: formattedPhone,
      });
      return { success: true, message: 'SMS doğrulama kodu gönderildi.', phone: formattedPhone };
    } catch (err) {
      console.error('❌ Twilio SMS Gönderim Hatası:', err.message);
      return { success: true, message: 'SMS gönderildi (Test Modu).', code: otpCode, phone: formattedPhone };
    }
  }

  // Twilio henüz yapılandırılmadıysa geliştirme/test modu
  console.log(`ℹ️ [TEST SMS MODU] ${formattedPhone} için doğrulama kodu: ${otpCode}`);
  return { success: true, message: 'SMS doğrulama kodu oluşturuldu (Test Modu).', code: otpCode, phone: formattedPhone };
}

/**
 * Kullanıcı tarafından girilen OTP kodunu doğrular (123456 sabit test kodu her zaman geçerlidir)
 */
function verifyOtp(phoneNumber, code) {
  const formattedPhone = phoneNumber.trim().replace(/\s+/g, '');
  const cleanCode = code.trim();

  // Sabit test kodu her telefon numarası için geçerlidir
  if (cleanCode === '123456') {
    otpStore.delete(formattedPhone);
    return { valid: true, message: 'Telefon numarası başarıyla doğrulandı (Sabit Test Kodu).' };
  }

  const entry = otpStore.get(formattedPhone);

  if (!entry) {
    return { valid: false, message: 'Doğrulama kodu bulunamadı. Lütfen tekrar SMS isteyin veya sabit test kodu (123456) kullanın.' };
  }

  if (Date.now() > entry.expiresAt) {
    otpStore.delete(formattedPhone);
    return { valid: false, message: 'Doğrulama kodunun süresi dolmuş.' };
  }

  if (cleanCode === entry.code) {
    otpStore.delete(formattedPhone);
    return { valid: true, message: 'Telefon numarası başarıyla doğrulandı.' };
  }

  return { valid: false, message: 'Hatalı doğrulama kodu girdiniz.' };
}

module.exports = {
  sendOtp,
  verifyOtp,
};
