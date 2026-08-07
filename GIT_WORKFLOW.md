# 🌿 MatPusula — Git Branch & Çalışma Rehberi

Bu proje, ana kod tabanını (`main`) korumak ve ekip üyelerinin birbirinin kodunu ezmeden eşzamanlı geliştirmeler yapabilmesi amacıyla **Branch Bazlı Çalışma Modeli (Git Flow)** ile yapılandırılmıştır.

---

## 👥 Ekip Branch'leri

| Ekip Üyesi | Sorumluluk Alanı | Git Branch Adı |
|---|---|---|
| 👑 **Yusuf** | Proje Lideri & Mobil UI/UX Mimarı | `yusuf` |
| 🤖 **Seyid** | Yapay Zeka & Görüntü İşleme Uzmanı | `seyid` |
| 🐘 **Anıl** | Backend & Veritabanı Mimarı | `anil` |
| 📱 **Abdullah** | Entegrasyon, SMS & DevOps Uzmanı | `abdullah` |

---

## 🚀 Kendi Branch'inizde Çalışma Adımları

### 1. Kendi Branch'inize Geçin
Geliştirme yapmadan önce mutlaka kendi branch'inizde olduğunuzdan emin olun:

```bash
# Yusuf için:
git checkout yusuf

# Seyid için:
git checkout seyid

# Anıl için:
git checkout anil

# Abdullah için:
git checkout abdullah
```

Hangi branch'te olduğunuzu kontrol etmek için:
```bash
git branch
```

---

### 2. Değişikliklerinizi Commit Edin ve Sunucuya Gönderin
Kendi branch'inizde geliştirmelerinizi yaptıktan sonra:

```bash
# 1. Değişiklikleri ekleyin
git add .

# 2. Anlamlı bir commit mesajı yazın
git commit -m "feat: [Modül Adı] yapılan geliştirme özeti"

# 3. Kendi branch'inizi GitHub'a push edin
git push origin <branch-adiniz>
```

---

## 🔀 Ana Projeye (`main`) Dokunmadan Test Etme & Birleştirme (Merge)

### 1. Ana Projedeki (`main`) Güncellemeleri Kendi Branch'inize Çekme
Başka bir arkadaşınız `main`'e yenilik eklediyse veya `main` güncellendiyse kendi branch'inizi güncellemek için:

```bash
git checkout <branch-adiniz>
git pull origin main
```

---

### 2. Geliştirmeler Bittiğinde `main` İle Birleştirme (Son Adım)
Tüm testlerinizi kendi branch'inizde başarıyla tamamladıktan sonra ana projeyle birleştirmek için:

#### Seçenek A: GitHub Üzerinden Pull Request (PR) Açma *(Önerilen)*
1. GitHub web sitesine gidin.
2. `New Pull Request` butonuna tıklayın.
3. Base branch: `main`, Compare branch: `<kendi-branch'iniz>` seçin.
4. Yusuf (Proje Lideri) inceleyip onayladıktan sonra PR merge edilir.

#### Seçenek B: Terminal Üzerinden Doğrudan Merge
```bash
# 1. Main branch'ine geçin
git checkout main

# 2. En son hali çekin
git pull origin main

# 3. Kendi branch'inizi main ile birleştirin
git merge <kendi-branch-adiniz>

# 4. Güncellenmiş main'i GitHub'a push edin
git push origin main
```

---

## ⚠️ Dikkat Edilmesi Gerekenler
- ❌ **Kesinlikle test etmeden ve emin olmadan doğrudan `main` branch'inde geliştirme yapmayın.**
- ✅ Kod yazmaya başlamadan önce her zaman `git checkout <kendi-branch-adiniz>` yaptığınızdan emin olun.
- 💡 Çakışma (Conflict) yaşanırsa, `main` ile birleştirmeden önce kendi branch'inizde `git pull origin main` yaparak çakışmaları çözün.
