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
  ) async {
    await connection.query(
      "INSERT INTO users (email, password, name, age, workplace) VALUES (@email, @password, @name, @age, @workplace)",
      substitutionValues: {
        "email": email,
        "password": password.hashCode, // Şifreyi hashlemeyi unutma!
        "name": name,
        "age": age,
        "workplace": workplace,
      },
    );
    print("Kullanıcı başarıyla kaydedildi!");
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

  // Bir kullanıcının tüm resimlerini getiren metod - Dosya yolları yerine resimlerin kendisini getireceğiz
  Future<List<String>> getUserImages(int userId) async {
    try {
      // Sadece resim URL'lerini değil direk resim datalarını çekmeye çalışıyoruz
      final results = await connection.query(
        'SELECT image_url FROM image WHERE user_id = @userId ORDER BY id',
        substitutionValues: {'userId': userId},
      );

      List<String> imageUrls = [];
      for (var row in results) {
        if (row[0] != null) {
          final urlString = row[0] as String;
          imageUrls.add(urlString);
          print(
            "Resim URL'si alındı: ${urlString.substring(0, urlString.length > 20 ? 20 : urlString.length)}...",
          ); // URL'nin ilk kısmını göster
        }
      }

      print("Kullanıcı $userId için ${imageUrls.length} resim bulundu");
      return imageUrls;
    } catch (e) {
      print("Kullanıcı resimleri getirilirken hata: $e");
      return [];
    }
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
