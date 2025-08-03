# 💞 SyncMe – Tinder Tarzı Eşleşme Uygulaması

**SyncMe**, kullanıcıların birbirleriyle eşleşmesini sağlayan, Flutter ile geliştirilmiş modern bir mobil tanışma uygulamasıdır. Kartları sağa, sola ve yukarı kaydırarak etkileşim kurma imkânı sunar. Veriler Firebase üzerinden yönetilir, resimler ise Cloudinary ile güvenli ve hızlı bir şekilde sunulur.

## ✨ Özellikler

- 🔥 Tinder benzeri swipe (kaydırma) kart yapısı
- 📤 Kullanıcı fotoğraf yükleme (Cloudinary üzerinden)
- 🔐 Firebase Authentication ile güvenli kayıt & giriş
- ☁️ Firebase Firestore ile kullanıcı verisi saklama
- 🎯 Eşleşme mantığı: her iki taraf da sağa kaydırınca eşleşme
- 💬 Mesajlaşma altyapısına hazır mimari
- 🖼️ Profil kartlarında yaş, çalıştığı yer, isim ve fotoğraf gösterimi

## 🧑‍💻 Kullanılan Teknolojiler

- Flutter
- Dart
- Firebase Auth & Firestore
- Cloudinary (resim depolama)
- `flutter_tindercard` veya `flutter_card_swiper` paketi
- Provider / Riverpod (state management - tercihe göre)

## 🛠️ Kurulum

```bash
git clone https://github.com/kullanici-adi/syncme.git
cd syncme
flutter pub get
flutter run
