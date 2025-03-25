import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:postgres/postgres.dart';
import 'package:ucanble_tinder/pages/home_page.dart';

class UploadCv extends StatefulWidget {
  final String userId; // Kullanıcı ID'sini almak için

  const UploadCv({required this.userId, super.key});

  @override
  State<UploadCv> createState() => _UploadCvState();
}

class _UploadCvState extends State<UploadCv> {
  File? selectedCv; // Seçilen CV dosyası
  bool _isContinueEnabled = false; // Devam Et butonunun aktifliği

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
      '10.0.2.2',
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
  void _onContinuePressed() {
    if (_isContinueEnabled && selectedCv != null) {
      _saveCvToDatabase(widget.userId, selectedCv!.path);

      // İşlem tamamlandığında yönlendirme veya başka bir işlem yapılabilir
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()), // Anasayfaya yönlendir
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  "CV'ni Bizimle Paylaş",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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
                    Icon(Icons.file_upload, color: Colors.black, size: 50),
                    SizedBox(height: 10),
                    Text("CV Yükle", style: TextStyle(color: Colors.black)),
                  ],
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.green, size: 50),
                    SizedBox(height: 10),
                    Text(
                      "CV Yüklendi",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
                      color: _isContinueEnabled ? colorScheme.onPrimary : Colors.grey,
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
                        Icon(Icons.arrow_circle_right, color: Colors.white),
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
