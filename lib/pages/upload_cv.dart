import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:postgres/postgres.dart';
import 'package:ucanble_tinder/pages/home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadCVPage extends StatefulWidget {
  final String userId; // Kullanıcı ID'sini almak için

  const UploadCVPage({required this.userId, super.key});

  @override
  State<UploadCVPage> createState() => _UploadCVPageState();
}

class _UploadCVPageState extends State<UploadCVPage> {
  File? selectedCv; // Seçilen CV dosyası
  bool _isContinueEnabled = false; // Devam Et butonunun aktifliği
  bool _isLoading = false; // Yükleme durumu

  // Flask API'si üzerinden CV'den isim çıkartma
  Future<String?> extractNameFromCV(File cvFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/extract_name'), // Android emulator için localhost
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'cv',
          cvFile.path,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        print("API yanıtı: $responseBody");
        var jsonData = jsonDecode(responseBody);
        return jsonData['name'];
      } else {
        print('API Hatası: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('İsim çıkarma hatası: $e');
      return null;
    }
  }

  // CV seçme fonksiyonu
  Future<void> _pickCv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        selectedCv = File(result.files.single.path!);
        _isContinueEnabled = true; // CV seçildiğinde butonu aktif et
      });
    }
  }

  // Veritabanına CV yolunu kaydetme fonksiyonu
  Future<void> _saveCvToDatabase(String userId, String cvPath) async {
    final connection = PostgreSQLConnection(
      '10.0.2.2', // PostgreSQL sunucu adresi
      5432,
      'postgres',
      username: 'postgres',
      password: 'hktokat0660',
    );

    await connection.open();
    await connection.query(
      'INSERT INTO cvs (user_id, cv_url) '
          'SELECT id, @cvUrl FROM users WHERE firebase_uid = @firebaseUid',
      substitutionValues: {'cvUrl': cvPath, 'firebaseUid': userId},
    );

    await connection.close();
  }

  // Devam Et butonuna basıldığında yapılacak işlem
  Future<void> _onContinuePressed() async {
    if (_isContinueEnabled && selectedCv != null) {
      setState(() {
        _isLoading = true;
      });

      // Gerçek CV yolunu elde et
      String cvPath = selectedCv!.path;

      // Veritabanına CV yolunu kaydet
      await _saveCvToDatabase(widget.userId, cvPath);

      // Flask API'den isim çıkar
      final extractedName = await extractNameFromCV(selectedCv!);
      print("Flask'tan alınan isim: $extractedName");

      setState(() {
        _isLoading = false;
      });

      // İşlem tamamlandığında anasayfaya yönlendir
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("CV yükleniyor..."),
          ],
        ),
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  "CV'ni Bizimle Paylaş",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Devam etmek için CV'nizi yüklemeniz gerekmektedir!",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
            GestureDetector(
              onTap: _pickCv,
              child: Container(
                height: 160,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                ),
                child: selectedCv == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_upload,
                      color: Colors.black,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "CV Yükle",
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      color: Colors.green,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "CV Yüklendi",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: _isContinueEnabled ? _onContinuePressed : null,
                  child: Container(
                    height: 50,
                    width: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      color: _isContinueEnabled
                          ? colorScheme.onPrimary
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: _isContinueEnabled
                          ? [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          spreadRadius: 10,
                          blurRadius: 10,
                          offset: Offset(1, 5),
                        ),
                      ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          "Devam Et",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.arrow_circle_right,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
