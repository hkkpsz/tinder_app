import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:postgres/postgres.dart';
import 'package:ucanble_tinder/ikon_icons.dart';
import 'package:ucanble_tinder/main.dart';

class UploadImagePage extends StatefulWidget {
  final String userId; // Kullanıcı ID'sini almak için

  UploadImagePage({required this.userId}); // Kullanıcı ID'si gerekli

  @override
  _UploadImagePageState createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  // Resim seçme fonksiyonu
  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }

  // Veritabanına resmi kaydetme fonksiyonu
  Future<void> _saveImageToDatabase() async {
    if (_image == null) return;

    String imagePath = _image!.path; // Seçilen resmin dosya yolu
    await _saveImagePathToDatabase(widget.userId, imagePath);

    print("Gönderilen userId: ${widget.userId}");
  }

  // PostgreSQL veritabanına resim yolunu kaydetme fonksiyonu
  Future<void> _saveImagePathToDatabase(String userId, String image_url) async {
    final connection = PostgreSQLConnection(
      '10.0.2.2',
      5432,
      'postgres',
      username: 'postgres',
      password: 'hktokat0660',
    );

    await connection.open();

    // Firebase uid ile userId'yi eşleştiriyoruz
    await connection.query(
      'INSERT INTO image (user_id, image_url) '
      'SELECT id, @imageUrl FROM users WHERE firebase_uid = @firebaseUid',
      substitutionValues: {
        'imageUrl': image_url,
        'firebaseUid': userId, // userId aslında firebase_uid
      },
    );

    await connection.close();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      // appBar: AppBar(title: Text("Resim Yükle")),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      child: FloatingActionButton(
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(height: 15),
                            Text(
                              "Resim Ekle",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      height: 160,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      child: FloatingActionButton(
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(height: 15),
                            Text(
                              "Resim Ekle",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      height: 160,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      child: FloatingActionButton(
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(height: 15),
                            Text(
                              "Resim Ekle",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      height: 160,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      child: FloatingActionButton(
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(height: 15),
                            Text(
                              "Resim Ekle",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      height: 160,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      child: FloatingActionButton(
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(height: 15),
                            Text(
                              "Resim Ekle",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      height: 160,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      child: FloatingActionButton(
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(height: 15),
                            Text(
                              "Resim Ekle",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      height: 160,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 90),
                Align(
                  alignment: Alignment.centerRight, // Sağ tarafa yasla
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0), // Sağdan biraz boşluk bırak
                    child: Container(
                      height: 50,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1),
                        color: colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            "Devam Et",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, ),
                          ),
                          Icon(Icons.arrow_circle_right, color: Colors.white,),
                        ],
                      ),
                    ),
                  ),
                )

              ],
            ),
          ],
        ),
        // child: Column(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     if (_image != null)
        //       Image.file(
        //         File(_image!.path),
        //         width: 200,
        //         height: 200,
        //       ),
        //     SizedBox(height: 20),
        //     ElevatedButton(
        //       onPressed: _pickImage,
        //       child: Text('Resim Seç'),
        //     ),
        //     SizedBox(height: 20),
        //     ElevatedButton(
        //       onPressed: _saveImageToDatabase,
        //       child: Text('Resmi Yükle'),
        //     ),
        //   ],
        // ),
      ),
    );
  }
}
