import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Kullanıcı verilerini Firestore'a kaydetme
  Future<void> saveUserData({
    required String userId,
    required String email,
    required String name,
    required int age,
    required String workplace,
    String? cvUrl,
  }) async {
    try {
      print("saveUserData çağrıldı - userId: $userId, name: $name, age: $age");

      // Standart veri yapısı
      final userData = {
        'email': email,
        'name': name, // Standart alan adı 'name'
        'ad': name, // Geriye dönük uyumluluk için 'ad' alanı da ekleniyor
        'age': age, // Standart alan adı 'age'
        'yas': age, // Geriye dönük uyumluluk için 'yas' alanı da ekleniyor
        'workplace': workplace,
        'cvUrl': cvUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'images': [], // Başlangıçta boş resim dizisi
      };

      await _firestore.collection('users').doc(userId).set(userData);
      print("Kullanıcı verileri Firestore'a kaydedildi: $userId");
      print("Kaydedilen veri: $userData");
    } catch (e) {
      print("Firestore'a veri kaydedilirken hata: $e");
      throw e;
    }
  }

  // Kullanıcı görüntü URL'lerini güncelleme
  Future<void> updateUserImages({
    required String userId,
    required List<String> imageUrls,
  }) async {
    try {
      print(
        "updateUserImages çağrıldı - userId: $userId, imageUrls: $imageUrls",
      );

      await _firestore.collection('users').doc(userId).update({
        'images': imageUrls,
      });
      print("Kullanıcı görüntüleri güncellendi: $userId");
    } catch (e) {
      print("Kullanıcı görüntüleri güncellenirken hata: $e");
      throw e;
    }
  }

  // Kullanıcının CV URL'sini güncelleme
  Future<void> updateUserCv({
    required String userId,
    required String cvUrl,
  }) async {
    try {
      print("updateUserCv çağrıldı - userId: $userId, cvUrl: $cvUrl");

      await _firestore.collection('users').doc(userId).update({'cvUrl': cvUrl});
      print("Kullanıcı CV'si güncellendi: $userId");
    } catch (e) {
      print("Kullanıcı CV'si güncellenirken hata: $e");
      throw e;
    }
  }

  // Tüm kullanıcıları getirme (mevcut kullanıcı hariç)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print("getAllUsers çağrıldı");

      // Mevcut kullanıcı kimliğini al
      String? currentUserId = _auth.currentUser?.uid;
      print("Mevcut kullanıcı ID: $currentUserId");

      // Firestore'dan tüm kullanıcıları çek
      final QuerySnapshot snapshot = await _firestore.collection('users').get();
      print("Firestore'dan ${snapshot.docs.length} kullanıcı çekildi");

      List<Map<String, dynamic>> users = [];
      for (var doc in snapshot.docs) {
        // Mevcut kullanıcıyı listeden çıkar
        if (doc.id != currentUserId) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Belge ID'sini ekle

          // Alan adı standartlaştırması - 'ad' alanı 'name' alanına kopyalanır
          if (data.containsKey('ad') && !data.containsKey('name')) {
            data['name'] = data['ad'];
          }

          // Alan adı standartlaştırması - 'yas' alanı 'age' alanına kopyalanır
          if (data.containsKey('yas') && !data.containsKey('age')) {
            data['age'] = data['yas'];
          }

          users.add(data);
          print(
            "Kullanıcı eklendi: ${data['name'] ?? 'İsimsiz'}, ID: ${doc.id}",
          );
        }
      }

      print("Toplam ${users.length} kullanıcı listeye eklendi");
      return users;
    } catch (e) {
      print("Kullanıcılar getirilirken hata: $e");
      return [];
    }
  }

  // Kullanıcı verilerini getirme
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      print("getUserData çağrıldı - userId: $userId");

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // ID'yi de ekle

        // Alan adı standartlaştırması - 'ad' alanı 'name' alanına kopyalanır
        if (data.containsKey('ad') && !data.containsKey('name')) {
          data['name'] = data['ad'];
        }

        // Alan adı standartlaştırması - 'yas' alanı 'age' alanına kopyalanır
        if (data.containsKey('yas') && !data.containsKey('age')) {
          data['age'] = data['yas'];
        }

        print(
          "Kullanıcı verisi bulundu: ${data['name'] ?? 'İsimsiz'}, ID: $userId",
        );
        return data;
      } else {
        print("Kullanıcı bulunamadı: $userId");
        return null;
      }
    } catch (e) {
      print("Kullanıcı verileri getirilirken hata: $e");
      return null;
    }
  }

  // Kullanıcı resimlerini getirme
  Future<List<String>> getUserImages(String userId) async {
    try {
      print("getUserImages çağrıldı - userId: $userId");

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> images = data['images'] ?? [];
        print("Kullanıcı için ${images.length} resim bulundu");

        if (images.isEmpty) {
          print(
            "Kullanıcı için hiç resim bulunamadı, varsayılan resim kullanılacak",
          );
          return [
            'https://res.cloudinary.com/dkkp7qiwb/image/upload/v1746467909/ucanble_tinder_images/osxku0wkujc3hwiqgj7z.jpg',
          ];
        }

        return images.cast<String>();
      } else {
        print("Kullanıcı bulunamadı: $userId, varsayılan resim kullanılacak");
        return [
          'https://res.cloudinary.com/dkkp7qiwb/image/upload/v1746467909/ucanble_tinder_images/osxku0wkujc3hwiqgj7z.jpg',
        ];
      }
    } catch (e) {
      print("Kullanıcı görüntüleri getirilirken hata: $e");
      return [
        'https://res.cloudinary.com/dkkp7qiwb/image/upload/v1746467909/ucanble_tinder_images/osxku0wkujc3hwiqgj7z.jpg',
      ];
    }
  }

  // Firestore'da kullanıcı olup olmadığını kontrol et
  Future<bool> checkUserExists(String userId) async {
    try {
      print("checkUserExists çağrıldı - userId: $userId");
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      final exists = doc.exists;
      print("Kullanıcı $userId var mı: $exists");
      return exists;
    } catch (e) {
      print("Kullanıcı kontrolü sırasında hata: $e");
      return false;
    }
  }

  // Kullanıcının okunmamış mesaj sayısını kontrol et
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      int totalUnreadCount = 0;

      // Kullanıcının eşleşmelerini bul (hem user1Id hem de user2Id olarak)
      final matchesQuery1 =
          await _firestore
              .collection('matches')
              .where('user1Id', isEqualTo: userId)
              .where('hasUnreadMessages', isEqualTo: true)
              .where('lastMessageSenderId', isNotEqualTo: userId)
              .get();

      final matchesQuery2 =
          await _firestore
              .collection('matches')
              .where('user2Id', isEqualTo: userId)
              .where('hasUnreadMessages', isEqualTo: true)
              .where('lastMessageSenderId', isNotEqualTo: userId)
              .get();

      // Eşleşmeleri birleştir
      final matchDocs = [...matchesQuery1.docs, ...matchesQuery2.docs];

      // Her bir eşleşme için okunmamış mesaj sayısını topla
      for (var doc in matchDocs) {
        final matchId = doc.id;

        // Okunmamış mesajları bul
        final messagesSnapshot =
            await _firestore
                .collection('matches')
                .doc(matchId)
                .collection('messages')
                .where('senderId', isNotEqualTo: userId)
                .where('read', isEqualTo: false)
                .get();

        totalUnreadCount += messagesSnapshot.docs.length;
      }

      return totalUnreadCount;
    } catch (e) {
      print('Okunmamış mesajlar sayılırken hata: $e');
      return 0;
    }
  }
}
