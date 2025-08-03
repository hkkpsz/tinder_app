import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ucanble_tinder/pages/home_page.dart';
import 'package:ucanble_tinder/pages/upload_cv.dart';
import 'package:ucanble_tinder/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ucanble_tinder/services/firebase_service.dart';

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
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  // Kullanıcı profilini kontrol et
  Future<void> _checkUserProfile() async {
    try {
      final userExists = await _firebaseService.checkUserExists(widget.userId);
      if (!userExists) {
        // Kullanıcı Firestore'da yoksa, varsayılan bir profil oluştur
        await _firebaseService.saveUserData(
          userId: widget.userId,
          email: 'kullanici@example.com', // Geçici email
          name: 'Yeni Kullanıcı',
          age: 25,
          workplace: 'Belirtilmemiş',
        );
        print("Yeni kullanıcı profili oluşturuldu: ${widget.userId}");
      } else {
        print("Kullanıcı profili zaten var: ${widget.userId}");
      }
    } catch (e) {
      print("Kullanıcı profili kontrol edilirken hata: $e");
    }
  }

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
            selectedImages.where((image) => image != null).length >= 1;
      });
    }
  }

  // Resimleri Cloudinary'ye yükle ve Firebase'e kaydet
  Future<List<String>> _uploadImagesToDatabase() async {
    List<String> imageUrls = [];
    try {
      print("Resimler yükleniyor...");

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

      print("Cloudinary'ye ${imageUrls.length} resim yüklendi");

      // Firebase Firestore'da kullanıcının resim URL'lerini güncelle
      await _firebaseService.updateUserImages(
        userId: widget.userId,
        imageUrls: imageUrls,
      );

      print("Firebase'de kullanıcı resimleri güncellendi");

      // Firestore'da imageUploaded durumunu güncelle
      await _firestore.collection('userProgress').doc(widget.userId).set({
        'imageUploaded': true,
      }, SetOptions(merge: true));

      print("Kullanıcı ilerleme durumu güncellendi");

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
        // Resimleri yükle ve Firebase'e kaydet
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

  // Ana sayfaya gitme
  void _skipToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
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
      appBar: AppBar(
        title: Text("Profil Fotoğrafları"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _skipToHome,
            child: Text("Atla", style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
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
                            "Devam etmek için minimum 1 fotoğraf eklemelisiniz.",
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
