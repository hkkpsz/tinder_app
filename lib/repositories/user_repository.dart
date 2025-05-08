import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ucanble_tinder/services/firebase_service.dart';
import 'package:ucanble_tinder/users.dart';

class UserRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Mevcut oturum açmış kullanıcıyı döndür
  auth.User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Tüm kullanıcıları getir
  Future<List<User>> getAllUsers() async {
    try {
      print("UserRepository.getAllUsers çağrıldı");

      // Firebase'den kullanıcıları al
      final usersData = await _firebaseService.getAllUsers();
      print("${usersData.length} kullanıcı verisi alındı");

      List<User> users = [];
      for (var userData in usersData) {
        String userId = userData['id'];
        print("Kullanıcı işleniyor: $userId");

        // Kullanıcının resimlerini al
        List<String> images = await _firebaseService.getUserImages(userId);
        print("Kullanıcı $userId için ${images.length} resim alındı");

        // Resim URL'leri nedir kontrol et
        if (images.isNotEmpty) {
          print("İlk resim URL: ${images[0]}");
        }

        User user = User(
          userId: userId,
          name: userData['name'] ?? 'İsimsiz Kullanıcı',
          age: userData['age'] ?? 0,
          workplace: userData['workplace'] ?? '',
          imagePath: images.isNotEmpty ? images[0] : null,
          additionalImages: images.length > 1 ? images.sublist(1) : [],
          cvUrl: userData['cvUrl'],
        );
        users.add(user);
        print("Kullanıcı eklendi: ${user.name}");
      }

      print("Toplam ${users.length} kullanıcı dönüldü");
      return users;
    } catch (e) {
      print("Kullanıcılar getirilirken hata: $e");
      return [];
    }
  }

  // Kullanıcı resimleri güncelleme
  Future<void> updateUserImages(String userId, List<String> imageUrls) async {
    await _firebaseService.updateUserImages(
      userId: userId,
      imageUrls: imageUrls,
    );
  }

  // Kullanıcı CV güncelleme
  Future<void> updateUserCv(String userId, String cvUrl) async {
    await _firebaseService.updateUserCv(userId: userId, cvUrl: cvUrl);
  }

  // Kullanıcı detaylarını getir
  Future<User?> getUserDetails(String userId) async {
    try {
      print("UserRepository.getUserDetails çağrıldı - userId: $userId");

      final userData = await _firebaseService.getUserData(userId);
      if (userData != null) {
        print("Kullanıcı verileri alındı");

        List<String> images = await _firebaseService.getUserImages(userId);
        print("Kullanıcı için ${images.length} resim alındı");

        // Resim URL'leri nedir kontrol et
        if (images.isNotEmpty) {
          print("İlk resim URL: ${images[0]}");
        }

        return User(
          userId: userData['id'],
          name: userData['name'] ?? 'İsimsiz Kullanıcı',
          age: userData['age'] ?? 0,
          workplace: userData['workplace'] ?? '',
          imagePath: images.isNotEmpty ? images[0] : null,
          additionalImages: images.length > 1 ? images.sublist(1) : [],
          cvUrl: userData['cvUrl'],
        );
      }
      print("Kullanıcı bulunamadı: $userId");
      return null;
    } catch (e) {
      print("Kullanıcı detayları getirilirken hata: $e");
      return null;
    }
  }

  // Kullanıcı resimleri getir
  Future<List<String>> getUserImages(String userId) async {
    try {
      return await _firebaseService.getUserImages(userId);
    } catch (e) {
      print("Kullanıcı resimleri getirilirken hata: $e");
      return [];
    }
  }
}
