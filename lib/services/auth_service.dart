import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı kayıt olma fonksiyonu
  Future<User?> signUpWithEmail(String email, String password, String ad, int yas, String workplace) async {
    try {
      if (!isValidEmail(email)) {
        throw "Geçersiz e-posta formatı! Lütfen doğru bir e-posta girin.";
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'a kullanıcı verisini kaydet
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
        'ad': ad,
        'yas': yas,
        'createdAt': Timestamp.now(),
        'workplace' : workplace,
      }).catchError((e) {
        print("Firestore Kaydetme Hatası: $e");
        return null;
      });

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
        // Kullanıcı başarılı giriş yaptı, uid'yi alabiliriz
        String userId = user.uid;
        print("Giriş yapan kullanıcı ID: $userId");

        // Firestore'dan kullanıcının verilerini almak da mümkün
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          // Kullanıcı verilerini kullanabilirsiniz
          var userData = userDoc.data();
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

  // E-posta formatını kontrol eden fonksiyon
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+');
    return emailRegex.hasMatch(email);
  }
}
