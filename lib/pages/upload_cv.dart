import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ucanble_tinder/pages/home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ucanble_tinder/services/firebase_service.dart';

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
  String? _fileName; // Dosya adı
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Flask API'si üzerinden CV'den isim çıkartma
  Future<String?> extractNameFromCV(File cvFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://10.0.2.2:5000/extract_name',
        ), // Android emulator için localhost
      );

      request.files.add(await http.MultipartFile.fromPath('cv', cvFile.path));

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
        _fileName = result.files.single.name;
        _isContinueEnabled = true; // CV seçildiğinde butonu aktif et
      });
    }
  }

  // Firebase'e CV yolunu kaydetme fonksiyonu
  Future<void> _saveCvToFirebase(String userId, String cvPath) async {
    try {
      print("CV kaydediliyor: $cvPath");

      // Firebase Firestore'da kullanıcının CV URL'sini güncelle
      await _firebaseService.updateUserCv(userId: userId, cvUrl: cvPath);

      print("CV başarıyla Firebase'e kaydedildi!");
    } catch (e) {
      print("CV kaydedilirken hata: $e");
      throw e;
    }
  }

  // Devam Et butonuna basıldığında yapılacak işlem
  Future<void> _onContinuePressed() async {
    if (_isContinueEnabled && selectedCv != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Gerçek CV yolunu elde et
        String cvPath = selectedCv!.path;
        print("Seçilen CV yolu: $cvPath");

        // Firebase'e CV yolunu kaydet
        await _saveCvToFirebase(widget.userId, cvPath);
        print("CV Firebase'e kaydedildi");

        // Firestore'da kullanıcı ilerleme durumunu güncelle
        await _firestore.collection('userProgress').doc(widget.userId).set({
          'cvUploaded': true,
          'profileCompleted': true,
        }, SetOptions(merge: true));
        print("Kullanıcı ilerleme durumu güncellendi");

        // Kullanıcı profilini tamamlandı olarak işaretle
        await _firestore.collection('users').doc(widget.userId).update({
          'profileCompleted': true,
        });
        print("Kullanıcı profili tamamlandı olarak işaretlendi");

        // Flask API'den isim çıkar
        try {
          final extractedName = await extractNameFromCV(selectedCv!);
          print("Flask'tan alınan isim: $extractedName");

          if (extractedName != null) {
            // İsim başarıyla çıkarıldıysa kullanıcı adını güncelle
            await _firestore.collection('users').doc(widget.userId).update({
              'name': extractedName,
              'ad': extractedName,
            });
            print("Kullanıcı adı CV'den çıkarılan isimle güncellendi");
          }
        } catch (e) {
          print("İsim çıkarma sırasında hata, ancak işleme devam edilecek: $e");
        }

        setState(() {
          _isLoading = false;
        });

        // İşlem tamamlandığında anasayfaya yönlendir
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("CV yüklenirken bir hata oluştu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Ana sayfaya git fonksiyonu
  void _skipToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("CV Yükleme"),
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
                    Text("CV yükleniyor..."),
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
                        SizedBox(height: 30),
                        // Başlık
                        Text(
                          "CV Yükle",
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
                            "Özgeçmişinizi yükleyerek profilinizi tamamlayın.",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // CV yükleme alanı
                        Expanded(
                          child: Center(
                            child: GestureDetector(
                              onTap: _pickCv,
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.secondary.withOpacity(
                                        0.2,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                  border:
                                      selectedCv != null
                                          ? Border.all(
                                            color: colorScheme.primary,
                                            width: 2,
                                          )
                                          : Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      selectedCv != null
                                          ? Icons.check_circle
                                          : Icons.upload_file,
                                      color:
                                          selectedCv != null
                                              ? colorScheme.primary
                                              : Colors.grey.shade400,
                                      size: 70,
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      selectedCv != null
                                          ? "CV Yüklendi"
                                          : "CV Yüklemek İçin Tıklayın",
                                      style: TextStyle(
                                        color:
                                            selectedCv != null
                                                ? colorScheme.primary
                                                : Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (_fileName != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 10,
                                          left: 20,
                                          right: 20,
                                        ),
                                        child: Text(
                                          _fileName!,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Bilgi notu
                        if (selectedCv != null)
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade100),
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
                              "Profili Tamamla",
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
