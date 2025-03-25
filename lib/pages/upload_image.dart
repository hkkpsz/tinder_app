import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:postgres/postgres.dart';
import 'package:ucanble_tinder/pages/home_page.dart';
import 'package:ucanble_tinder/pages/upload_cv.dart';

class UploadImagePage extends StatefulWidget {
  final String userId; // Kullanıcı ID'sini almak için

  UploadImagePage({required this.userId});

  @override
  _UploadImagePageState createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  final ImagePicker _picker = ImagePicker();
  List<File?> selectedImages = List.filled(6, null); // 6 buton için liste
  bool _hasError = false; // Hata durumu kontrolü
  bool _isContinueEnabled = false; // Devam Et butonunun aktifliği

  // Resim seçme fonksiyonu
  Future<void> _pickImage(int index) async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        selectedImages[index] = File(pickedImage.path);
        _hasError = false; // Hata durumunu sıfırla

        // Yüklenen resim sayısına göre butonun aktif olup olmayacağını kontrol et
        _isContinueEnabled =
            selectedImages.where((image) => image != null).length >= 2;
      });
    }
  }

  // Veritabanına kaydetme fonksiyonu (isteğe bağlı olarak kullanılabilir)
  Future<void> _saveImageToDatabase(String userId, String imageUrl) async {
    final connection = PostgreSQLConnection(
      '10.0.2.2',
      5432,
      'postgres',
      username: 'postgres',
      password: 'hktokat0660',
    );

    await connection.open();
    await connection.query(
      'INSERT INTO image (user_id, image_url) '
      'SELECT id, @imageUrl FROM users WHERE firebase_uid = @firebaseUid',
      substitutionValues: {'imageUrl': imageUrl, 'firebaseUid': userId},
    );

    await connection.close();
  }

  // Devam Et butonuna basıldığında yapılacak işlem
  void _onContinuePressed() {
    if (_isContinueEnabled) {
      for (var i = 0; i < selectedImages.length; i++) {
        if (selectedImages[i] != null) {
          _saveImageToDatabase(widget.userId, selectedImages[i]!.path);
        }
      }
      // İşlem tamamlandığında yönlendirme veya başka bir işlem yapılabilir
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UploadCv(userId: widget.userId,)),
      );
    }
  }

  // Bottom Sheet açma fonksiyonu
  void _showImagePicker(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierDismissible: true, // Dialog dışına tıklayarak kapatma
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Resim Seç",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context); // Önce dialog'u kapat
                  await _pickImage(index); // Sonra resmi seç
                },
                icon: Icon(Icons.image),
                label: Text("Galeriden Seç"),
              ),
            ],
          ),
        );
      },
    );
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
                  "Fotoğraf Ekle",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Devam etmek için minimum 2 fotoğraf eklemelisiniz!",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
            Column(
              children: [
                // İlk satır (3 buton)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    3,
                    (index) => _buildImageContainer(index),
                  ),
                ),
                SizedBox(height: 30),
                // İkinci satır (3 buton)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    3,
                    (index) => _buildImageContainer(index + 3),
                  ),
                ),
                SizedBox(height: 90),
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
                          color:
                              _isContinueEnabled
                                  ? colorScheme.onPrimary
                                  : Colors.grey,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow:
                              _isContinueEnabled
                                  ? [
                                    BoxShadow(
                                      color: Colors.indigo.withOpacity(
                                        0.3,
                                      ), // Gölge rengi
                                      spreadRadius: 10, // Yayılma
                                      blurRadius: 10, // Bulanıklık
                                      offset: Offset(
                                        1,
                                        5,
                                      ), // X ve Y ekseninde kayma
                                    ),
                                  ]
                                  : [], // Pasifken shadow olmasın
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
          ],
        ),
      ),
    );
  }

  // Resim Container bileşeni
  Widget _buildImageContainer(int index) {
    return GestureDetector(
      onTap: () => _showImagePicker(context, index),
      child: Container(
        height: 160,
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[300],
          image:
              selectedImages[index] != null
                  ? DecorationImage(
                    image: FileImage(selectedImages[index]!),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child:
            selectedImages[index] == null
                ? FloatingActionButton(
                  heroTag: "Resim $index",
                  onPressed: () => _showImagePicker(context, index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(height: 15),
                      Text(
                        "Resim Ekle",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                )
                : null,
      ),
    );
  }
}
