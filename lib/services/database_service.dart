import 'package:postgres/postgres.dart';

class DatabaseService {
  final String host = '10.0.2.2';  // Emülatör için IP adresi
  final int port = 5432;
  final String databaseName = 'postgres';
  final String username = 'postgres';
  final String password = 'hktokat0660';

  // Veritabanına bağlanma fonksiyonu
  Future<PostgreSQLConnection> _connect() async {
    try {
      final connection = PostgreSQLConnection(
        host,
        port,
        databaseName,
        username: username,
        password: password,
      );
      await connection.open();
      print("Veritabanına başarıyla bağlanıldı.");
      return connection;
    } catch (e) {
      print('Bağlantı hatası: $e');
      rethrow;
    }
  }

  // Resim yolunu veritabanına kaydetme fonksiyonu
  Future<void> saveImagePathToDatabase(String imagePath) async {
    final connection = await _connect();

    try {
      await connection.query(
        'INSERT INTO your_table_name (image_path) VALUES (@path)',
        substitutionValues: {'path': imagePath},
      );
      print("Veri başarıyla eklendi.");
    } catch (e) {
      print('Veritabanına veri eklerken hata oluştu: $e');
    } finally {
      await connection.close();
    }
  }

  // Veritabanından resim yolunu çekme fonksiyonu
  Future<String?> getImagePathFromDatabase() async {
    final connection = await _connect();

    try {
      var result = await connection.query('SELECT image_path FROM your_table_name LIMIT 1');
      if (result.isNotEmpty) {
        return result.first[0]; // İlk satırdaki `image_path` değerini alıyoruz
      } else {
        return null;
      }
    } catch (e) {
      print('Veritabanından resim çekerken hata oluştu: $e');
      return null;
    } finally {
      await connection.close();
    }
  }
}
