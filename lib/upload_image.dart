import 'dart:io';
import 'dart:typed_data'; // byte işlemleri için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:postgres/postgres.dart';  // PostgreSQL import

class UploadImagePage extends StatefulWidget {
  @override
  _UploadImagePageState createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  // Resim seçme fonksiyonu
  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
    });
  }

  // Veritabanına resmi kaydetme fonksiyonu
  Future<void> _saveImageToDatabase() async {
    if (_image == null) return;

    String imagePath = _image!.path;  // Resmin yolu
    await _saveImagePathToDatabase(imagePath);
  }

  // PostgreSQL veritabanına resim yolunu kaydetme fonksiyonu
  Future<void> _saveImagePathToDatabase(String imagePath) async {
    final connection = PostgreSQLConnection(
      '10.0.2.2',  // Veritabanı sunucusu adresi
      5432,  // Port
      'postgres',  // Veritabanı adı
      username: 'postgres',  // Kullanıcı adı
      password: 'hktokat0660',  // Parola
    );

    await connection.open();

    // Resmi byte formatına çevirme
    File imageFile = File(imagePath);
    Uint8List imageBytes = await imageFile.readAsBytes();

    // Veritabanına resim ve adı kaydetme
    await connection.query(
      'INSERT INTO public.images (name, image_data) VALUES (@name, @imageData)',
      substitutionValues: {
        'name': imagePath.split('/').last,  // Resmin adı
        'imageData': imageBytes,  // Binary (byte) verisi
      },
    );

    await connection.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Resim Yükle")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Image.file(
                File(_image!.path),
                width: 200,
                height: 200,
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Resim Seç'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveImageToDatabase,
              child: Text('Resmi Yükle'),
            ),
          ],
        ),
      ),
    );
  }
}
