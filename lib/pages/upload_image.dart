import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:postgres/postgres.dart';
import 'package:ucanble_tinder/pages/home_page.dart';
import 'package:ucanble_tinder/pages/upload_cv.dart';
import 'package:ucanble_tinder/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _isLoading = false; // Yükleme durumu

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

  // Veritabanına kaydetme fonksiyonu
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

  // Resimleri Cloudinary'ye yükle ve PostgreSQL'e kaydet
  Future<List<String>> _uploadImagesToDatabase() async {
    List<String> imageUrls = [];
    try {
      // Seçilen resimleri listeye ekle
      List<File> filesToUpload = [];
      for (var image in selectedImages) {
        if (image != null) {
          filesToUpload.add(image);
        }
      }

      // ApiService kullanarak tüm resimleri Cloudinary'ye yükle
      imageUrls = await ApiService.uploadMultipleImagesToCloudinary(
        filesToUpload,
        widget.userId,
      );

      // Yüklenen her resmi veritabanına kaydet
      for (String imageUrl in imageUrls) {
        await _saveImageToDatabase(widget.userId, imageUrl);
      }

      // Firestore'da imageUploaded durumunu güncelle
      await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(widget.userId)
          .update({'imageUploaded': true});

      return imageUrls;
    } catch (e) {
      print('Resim yükleme hatası: $e');
      setState(() {
        _hasError = true;
      });
      return [];
    }
  }

  // Devam Et butonuna basıldığında yapılacak işlem
  Future<void> _onContinuePressed() async {
    if (_isContinueEnabled) {
      setState(() {
        _isLoading = true;
      });

      try {
        // PostgreSQL'e resimleri yükle
        await _uploadImagesToDatabase();

        setState(() {
          _isLoading = false;
        });

        // İşlem tamamlandığında CV yükleme sayfasına yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UploadCVPage(userId: widget.userId),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Resim yüklenirken bir hata oluştu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  // Resim container widget'ı
  Widget _buildImageContainer(int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showImagePicker(context, index),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: colorScheme.secondary.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 3),
            ),
          ],
          border:
              selectedImages[index] != null
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
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
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      color: colorScheme.primary,
                      size: 40,
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Ekle",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    SizedBox(height: 20),
                    Text("Resimler yükleniyor..."),
                  ],
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.red.shade50],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 20),
                        // Başlık
                        Text(
                          "Profil Fotoğrafları",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        // Alt başlık
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.secondary.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            "Devam etmek için minimum 2 fotoğraf eklemelisiniz.",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Resim seçme alanı
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 40),
                                  // İlk satır (3 buton)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(
                                      3,
                                      (index) => _buildImageContainer(index),
                                    ),
                                  ),
                                  SizedBox(height: 25),
                                  // İkinci satır (3 buton)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(
                                      3,
                                      (index) =>
                                          _buildImageContainer(index + 3),
                                    ),
                                  ),
                                  if (_hasError)
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text(
                                        "Resim yüklenirken bir hata oluştu. Lütfen tekrar deneyin.",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Seçilen resim sayısı göstergesi
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                _isContinueEnabled
                                    ? colorScheme.primary.withOpacity(0.1)
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Seçilen: ${selectedImages.where((image) => image != null).length} / 6 Fotoğraf",
                            style: TextStyle(
                              color:
                                  _isContinueEnabled
                                      ? colorScheme.primary
                                      : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Devam et butonu
                        Padding(
                          padding: EdgeInsets.only(bottom: 30, top: 10),
                          child: ElevatedButton(
                            onPressed:
                                _isContinueEnabled ? _onContinuePressed : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              "Devam Et",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
