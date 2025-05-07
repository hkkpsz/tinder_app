// services/api_service.dart

import 'package:postgres/postgres.dart';
import 'package:ucanble_tinder/users.dart'; // user.dart içeri aktar
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<List<User>> fetchUsers() async {
    final connection = PostgreSQLConnection(
      '10.0.2.2',
      5432,
      'postgres',
      username: 'postgres',
      password: 'hktokat0660',
    );

    await connection.open();

    final results = await connection.query(
      'SELECT name, age, image_path FROM users',
    );

    await connection.close();

    return results.map((row) {
      return User(name: row[0], age: row[1], imagePath: row[2]);
    }).toList();
  }

  // Cloudinary için gerekli bilgiler
  static const String cloudName =
      'dkkp7qiwb'; // Buraya kendi cloud name'inizi yazın
  static const String uploadPreset =
      'tinder_upload'; // Buraya kendi upload preset'inizi yazın

  // Resmi Cloudinary'ye yükleyen metod - HTTP kullanarak
  static Future<String> uploadImageToCloudinary(
    File imageFile,
    String userId,
  ) async {
    try {
      // Cloudinary API endpoint URL'si
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      // İstek için multipart form oluştur
      final request =
          http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = uploadPreset
            ..fields['folder'] = 'ucanble_tinder_images'
            ..fields['tags'] = 'user_$userId,tinder_app'
            ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path),
            );

      // İsteği gönder
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Yanıtı işle
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final secureUrl = responseData['secure_url'];
        print('Resim Cloudinary\'ye başarıyla yüklendi: $secureUrl');
        return secureUrl;
      } else {
        // Hata detayını yazdır
        print('Cloudinary API hata kodu: ${response.statusCode}');
        print('Cloudinary API hata mesajı: ${response.body}');
        throw Exception(
          'Resim yüklenemedi: HTTP ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Cloudinary\'ye resim yükleme hatası: $e');
      throw Exception('Resim yüklenemedi: $e');
    }
  }

  // Birden fazla resmi Cloudinary'ye yükleyen metod
  static Future<List<String>> uploadMultipleImagesToCloudinary(
    List<File> imageFiles,
    String userId,
  ) async {
    List<String> uploadedUrls = [];

    for (var imageFile in imageFiles) {
      try {
        String url = await uploadImageToCloudinary(imageFile, userId);
        uploadedUrls.add(url);
      } catch (e) {
        print('Resim yükleme hatası: $e');
        // Hata durumunda işleme devam et
        continue;
      }
    }

    return uploadedUrls;
  }
}
