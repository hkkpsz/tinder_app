import 'package:postgres/postgres.dart';

class DatabaseService {
  late PostgreSQLConnection connection;

  // Bağlantıyı başlat
  Future<void> connect() async {
    connection = PostgreSQLConnection(
      "10.0.2.2", // Emülatörde bu şekilde olmalı, gerçek veritabanı IP'siyle değiştir.
      5432, // PostgreSQL portu
      "postgres", // Veritabanı adı
      username: "postgres", // Veritabanı kullanıcı adı
      password: "hktokat0660", // Veritabanı şifresi
    );

    await connection.open();
    print("PostgreSQL bağlantısı başarılı!");
  }

  // Kullanıcıyı veritabanına ekleme
  Future<void> insertUser(
    String email,
    String password,
    String name,
    int age,
    String workplace,
    String firebaseUid,
  ) async {
    await connection.query(
      "INSERT INTO users (email, password, name, age, workplace, firebase_uid) VALUES (@email, @password, @name, @age, @workplace, @firebaseUid)",
      substitutionValues: {
        "email": email,
        "password": password.hashCode, // Şifreyi hashlemeyi unutma!
        "name": name,
        "age": age,
        "workplace": workplace,
        "firebaseUid": firebaseUid,
      },
    );
    print("Kullanıcı başarıyla kaydedildi! Firebase UID: $firebaseUid");
  }

  // Firebase UID'yi güncelleme
  Future<void> updateUserFirebaseUid(String email, String firebaseUid) async {
    // Veritabanına bağlanmamıza gerek yok, çünkü zaten bağlantı var
    await connection.query(
      'UPDATE users SET firebase_uid = @firebaseUid WHERE email = @email',
      substitutionValues: {
        'firebaseUid': firebaseUid, // Firebase ID
        'email': email, // Kullanıcı email
      },
    );
    print("Firebase UID başarıyla güncellendi!");
  }

  // Tüm kullanıcıları ve resimlerini çekme
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    // Kullanıcıları ve resimleri birleştirerek çekme
    final results = await connection.mappedResultsQuery('''
      SELECT u.id, u.name, u.age, u.workplace
      FROM users u
      ''');

    // Verileri düzenli bir liste haline getirme
    List<Map<String, dynamic>> users = [];
    for (var row in results) {
      users.add({
        'id': row['users']?['id'],
        'name': row['users']?['name'],
        'age': row['users']?['age'],
        'workplace': row['users']?['workplace'],
      });
    }

    print("Veritabanından ${users.length} kullanıcı çekildi");
    return users;
  }

  // Bir kullanıcının tüm resimlerini getiren metod - Cloudinary URL'lerini kullanır
  Future<List<String>> getUserImages(int userId) async {
    try {
      // Sadece resim URL'lerini çekiyoruz
      final results = await connection.query(
        'SELECT image_url FROM image WHERE user_id = @userId ORDER BY id',
        substitutionValues: {'userId': userId},
      );

      List<String> imageUrls = [];
      for (var row in results) {
        if (row[0] != null) {
          final urlString = row[0] as String;

          // Cloudinary URL'i ile başlıyorsa doğrudan kullan
          if (urlString.contains('cloudinary.com')) {
            imageUrls.add(urlString);
            print("Cloudinary URL'si bulundu: $urlString");
          } else {
            // Diğer URL'ler için geçerli URL oluştur
            imageUrls.add(_getValidImageUrl(urlString));
            print("Geçerli URL oluşturuldu: ${_getValidImageUrl(urlString)}");
          }
        }
      }

      print("Kullanıcı $userId için ${imageUrls.length} resim bulundu");

      // Eğer hiç resim bulunamadıysa varsayılan Cloudinary URL'sini ekle
      if (imageUrls.isEmpty) {
        imageUrls.add(
          'https://res.cloudinary.com/dkkp7qiwb/image/upload/v1746467909/ucanble_tinder_images/osxku0wkujc3hwiqgj7z.jpg',
        );
      }

      return imageUrls;
    } catch (e) {
      print("Kullanıcı resimleri getirilirken hata: $e");
      return [
        'https://res.cloudinary.com/dkkp7qiwb/image/upload/v1746467909/ucanble_tinder_images/osxku0wkujc3hwiqgj7z.jpg',
      ];
    }
  }

  // Geçerli bir image URL oluşturmak için yardımcı metod
  String _getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      // Boş URL durumunda varsayılan bir Cloudinary URL göster
      return 'https://res.cloudinary.com/dkkp7qiwb/image/upload/v1746467909/ucanble_tinder_images/osxku0wkujc3hwiqgj7z.jpg';
    }

    // Cloudinary URL'si zaten tam olarak kullanılabilir
    if (url.contains('cloudinary.com')) {
      return url;
    }

    // Eğer URL zaten http:// veya https:// ile başlıyorsa, kullan
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Diğer tüm durumlarda varsayılan Cloudinary URL'si kullan
    return 'https://res.cloudinary.com/dkkp7qiwb/image/upload/v1746467909/ucanble_tinder_images/osxku0wkujc3hwiqgj7z.jpg';
  }

  // SQL sorgusu çalıştırıp sonuçları gösteren yardımcı metot
  Future<void> executeQuery(String query) async {
    try {
      final results = await connection.query(query);
      print("Sorgu sonucu: $results");
    } catch (e) {
      print("Sorgu çalıştırılırken hata: $e");
    }
  }

  // Bağlantıyı kapat
  Future<void> closeConnection() async {
    await connection.close();
    print("PostgreSQL bağlantısı kapatıldı!");
  }

  // Image tablosunun yapısını kontrol et
  Future<void> checkImageTable() async {
    try {
      // Tablo yapısını kontrol et
      print("Image tablosunun yapısını kontrol ediyorum...");
      final tableInfo = await connection.query('''
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'image'
      ''');

      for (var row in tableInfo) {
        print("Kolon: ${row[0]}, Tip: ${row[1]}");
      }

      // Örnek veri göster
      print("Image tablosundan örnek veri alınıyor...");
      final sampleData = await connection.query('''
        SELECT id, user_id, image_url, LEFT(image_url, 100) as sample_url
        FROM image
        LIMIT 5
      ''');

      for (var row in sampleData) {
        print("ID: ${row[0]}, User ID: ${row[1]}, URL Örneği: ${row[3]}");
      }
    } catch (e) {
      print("Tablo kontrolü sırasında hata: $e");
    }
  }
}
