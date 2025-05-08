import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ucanble_tinder/services/firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Kullanıcı kayıt olma fonksiyonu
  Future<User?> signUpWithEmail(
    String email,
    String password,
    String ad,
    int yas,
    String workplace,
  ) async {
    try {
      if (!isValidEmail(email)) {
        throw "Geçersiz e-posta formatı! Lütfen doğru bir e-posta girin.";
      }

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Firebase Firestore'a kullanıcı verisini kaydet
        await _firebaseService.saveUserData(
          userId: userCredential.user!.uid,
          email: email,
          name: ad,
          age: yas,
          workplace: workplace,
        );
      }

      return userCredential.user; // Başarılı olursa kullanıcıyı döndür
    } catch (e) {
      print("Kayıt Hatası: $e");
      return null; // Hata olursa null döndür
    }
  }

  // Kullanıcı giriş fonksiyonu
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Kullanıcı başarılı giriş yaptı
        String userId = user.uid;
        print("Giriş yapan kullanıcı ID: $userId");

        // Firebase Firestore'dan kullanıcının verilerini almak mümkün
        final userData = await _firebaseService.getUserData(userId);
        if (userData != null) {
          print("Kullanıcı verileri alındı: ${userData['name']}");
        }

        return user; // Kullanıcıyı döndürüyoruz
      } else {
        print("Kullanıcı girişi başarısız!");
        return null;
      }
    } catch (e) {
      print("Giriş Hatası: $e");
      return null; // Hata olursa null döndür
    }
  }

  // Mevcut giriş yapmış kullanıcıyı döndürme
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Kullanıcı oturumunu kapatma
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // E-posta formatını kontrol eden fonksiyon
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+',
    );
    return emailRegex.hasMatch(email);
  }
}
