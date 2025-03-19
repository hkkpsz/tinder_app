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
      String email, String password, String name, int age, String workplace) async {
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
        'firebaseUid': firebaseUid,  // Firebase ID
        'email': email,  // Kullanıcı email
      },
    );
    print("Firebase UID başarıyla güncellendi!");
  }

  // Bağlantıyı kapat
  Future<void> closeConnection() async {
    await connection.close();
    print("PostgreSQL bağlantısı kapatıldı!");
  }
}
