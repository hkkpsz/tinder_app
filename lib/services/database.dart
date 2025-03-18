import 'package:postgres/postgres.dart';

class DatabaseService {
  late PostgreSQLConnection connection;

  Future<void> connect() async {
    connection = PostgreSQLConnection(
      "10.0.2.2",
      5432,
      "postgres",
      username: "postgres",
      password: "hktokat0660",
    );

    await connection.open();
    print("PostgreSQL bağlantısı başarılı!");
  }

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
}
