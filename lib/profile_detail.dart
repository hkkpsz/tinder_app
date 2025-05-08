import 'package:flutter/material.dart';
import 'ikon_icons.dart';
import 'pages/home_page.dart';
import 'pages/match_page.dart';
import 'pages/message_page.dart';
import 'users.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/upload_image.dart';
import 'pages/login_page.dart';
import 'repositories/user_repository.dart';

class ProfileDetail extends StatefulWidget {
  final int userIndex;
  final User? user;
  final String? userId; // Firebase User ID

  const ProfileDetail({super.key, this.userIndex = 0, this.user, this.userId});

  @override
  State<ProfileDetail> createState() => _ProfileDetailState();
}

class _ProfileDetailState extends State<ProfileDetail> {
  User? currentUser;
  bool isLoading = true;
  String errorMessage = '';
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository = UserRepository();

  // Kullanıcı bilgileri
  String? aboutMe;
  List<String> interests = [];
  bool isCurrentUserProfile = false;

  // Geçerli bir image URL oluşturmak için yardımcı metod
  String _getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      // Boş URL durumunda varsayılan bir URL göster
      return 'https://res.cloudinary.com/dkkp7qiwb/image/upload/v1746467909/ucanble_tinder_images/osxku0wkujc3hwiqgj7z.jpg';
    }

    // Cloudinary URL'si zaten tam olarak kullanılabilir
    if (url.contains('cloudinary.com')) {
      return url;
    }

    // Eğer URL zaten http:// veya https:// ile başlıyorsa, kullan
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Diğer tüm durumlarda varsayılan URL'yi kullan
    return 'https://res.cloudinary.com/dkkp7qiwb/image/upload/v1746467909/ucanble_tinder_images/osxku0wkujc3hwiqgj7z.jpg';
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      print(
        "_loadCurrentUser çağrıldı: userIndex=${widget.userIndex}, userId=${widget.userId}",
      );

      // Eğer doğrudan bir kullanıcı nesnesi verilmişse, onu kullan
      if (widget.user != null) {
        print("Widget user kullanılıyor");
        setState(() {
          currentUser = widget.user;
          isLoading = false;
        });
        return;
      }

      // Eğer userId verilmişse öncelikle o kullanıcıyı yükle
      if (widget.userId != null) {
        print("userId verilmiş, bu kullanıcı yüklenecek: ${widget.userId}");
        await _loadUserFromFirebase(widget.userId!);
        return;
      }

      // Eğer giriş yapmış kullanıcı varsa ve userId verilmemişse, giriş yapmış kullanıcıyı göster
      final currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser != null) {
        print("Current Firebase User yükleniyor: ${currentFirebaseUser.uid}");
        await _loadUserFromFirebase(currentFirebaseUser.uid);
      } else {
        // Eğer oturum açmış kullanıcı yoksa ve userId de verilmemişse hata mesajı göster
        setState(() {
          errorMessage = 'Giriş yapmış kullanıcı bulunamadı';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcı yüklenirken hata oluştu: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  Future<void> _loadUserFromFirebase(String userId) async {
    try {
      print("Firebase'den kullanıcı yükleniyor: $userId");

      // Mevcut kullanıcı kendi profilini mi görüntülüyor?
      isCurrentUserProfile = _auth.currentUser?.uid == userId;
      print("Mevcut kullanıcı profili mi: $isCurrentUserProfile");

      // UserRepository kullanarak kullanıcı bilgilerini al
      final user = await _userRepository.getUserDetails(userId);
      if (user == null) {
        setState(() {
          errorMessage = 'Kullanıcı profili bulunamadı';
          isLoading = false;
        });
        return;
      }

      // Firestore'dan kullanıcı hakkında ek bilgileri al
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData != null) {
        // Kullanıcı hakkında ve ilgi alanları bilgilerini al
        aboutMe = userData['aboutMe'];

        // Interests listesini çek (Firestore'da array olarak saklanıyor)
        if (userData['interests'] != null) {
          interests = List<String>.from(userData['interests']);
          print("İlgi alanları: $interests");
        }
      }

      setState(() {
        currentUser = user;
        isLoading = false;
      });
    } catch (e) {
      print("Kullanıcı profili yüklenirken hata: $e");
      setState(() {
        errorMessage = 'Kullanıcı profili yüklenirken hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  // Image widget oluşturan yardımcı metod
  Widget _buildUserImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      print("Profil resmi boş, varsayılan resim gösteriliyor");
      return Container(
        color: Colors.grey.shade200,
        child: Center(child: Icon(Icons.person, color: Colors.grey, size: 60)),
      );
    }

    final url = _getValidImageUrl(imageUrl);
    print("Profil resmi yükleniyor: $url");

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            color: Colors.red,
            value:
                loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print("Profil resmi yüklenirken hata: $error (URL: $url)");
        // Hata durumunda varsayılan avatar göster
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey, size: 50),
                SizedBox(height: 8),
                Text(
                  "Resim Yüklenemedi",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Profil Detayı"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Profil Detayı"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700], fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadCurrentUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text("Tekrar Dene"),
              ),
            ],
          ),
        ),
      );
    }

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Profil Detayı"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, color: Colors.grey, size: 60),
              SizedBox(height: 16),
              Text(
                "Kullanıcı bulunamadı",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildUserInfo(),
                    SizedBox(height: 24),
                    buildAboutSection(),
                    SizedBox(height: 24),
                    buildInterestsSection(),
                    SizedBox(height: 24),
                    buildPhotosSection(),
                    SizedBox(height: 24),
                    buildSettingsSection(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  Widget buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner görüntüsü (kullanıcı resmini banner olarak kullanıyoruz)
            _buildUserImage(currentUser?.imagePath),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                  stops: [0.7, 1.0],
                ),
              ),
            ),
            // Profil fotoğrafı
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(child: _buildUserImage(currentUser?.imagePath)),
              ),
            ),
            // Düzenleme butonu - sadece kendi profilimizde göster
            if (isCurrentUserProfile)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit, color: Colors.black87, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${currentUser?.name ?? 'İsimsiz'}, ${currentUser?.age ?? '?'}",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  if (currentUser?.workplace != null)
                    Row(
                      children: [
                        Icon(Icons.work, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          currentUser!.workplace!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        "İstanbul",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildAboutSection() {
    return buildSectionCard(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Hakkımda"),
          // Düzenleme butonu - sadece kendi profilimizde göster
          if (isCurrentUserProfile)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.red, size: 20),
              onPressed: _showEditAboutMeDialog,
              tooltip: "Hakkımda bilgisini düzenle",
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            aboutMe ??
                "Merhaba! Ben bir yazılım geliştiricisiyim ve bilgisayara bayılırım. Yeni insanlarla tanışmayı ve farklı kültürleri keşfetmeyi seviyorum.",
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget buildInterestsSection() {
    return buildSectionCard(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("İlgi Alanlarım"),
          // Düzenleme butonu - sadece kendi profilimizde göster
          if (isCurrentUserProfile)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.red, size: 20),
              onPressed: _showEditInterestsDialog,
              tooltip: "İlgi alanlarını düzenle",
            ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children:
            interests.isNotEmpty
                ? interests
                    .map((interest) => buildInterestChip(interest))
                    .toList()
                : [
                  buildInterestChip("Müzik"),
                  buildInterestChip("Spor"),
                  buildInterestChip("Seyahat"),
                  buildInterestChip("Fotoğrafçılık"),
                  buildInterestChip("Arkadaşlarla Sosyalleşmek"),
                  buildInterestChip("Doğa Yürüyüşü"),
                  buildInterestChip("Sinema"),
                  buildInterestChip("Yoga"),
                ],
      ),
    );
  }

  Widget buildInterestChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.red.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget buildPhotosSection() {
    // Kullanıcının kendi profili ise ve aktif bir Firebase kullanıcısı varsa
    final firebaseUser = _auth.currentUser;
    final String userId = widget.userId ?? firebaseUser?.uid ?? '';

    print(
      "buildPhotosSection çağrıldı: userId=$userId, isCurrentUserProfile=$isCurrentUserProfile",
    );

    // Önce currentUser resimleri varsa onları göster
    if (currentUser != null && currentUser!.imagePath != null) {
      List<String> images = [];

      // Profil fotoğrafı ve ek fotoğrafları birleştir
      if (currentUser!.imagePath != null) {
        images.add(currentUser!.imagePath!);
      }

      images.addAll(currentUser!.additionalImages);

      print("Mevcut kullanıcı nesnesinden ${images.length} resim bulundu");

      // Resimler varsa grid view ile göster
      if (images.isNotEmpty) {
        return Stack(
          children: [
            buildSectionCard(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Fotoğraflarım",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (isCurrentUserProfile)
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.red, size: 22),
                      tooltip: "Fotoğrafları Düzenle",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    UploadImagePage(userId: firebaseUser!.uid),
                          ),
                        ).then((_) {
                          // Sayfadan dönünce sayfayı yenile
                          setState(() {});
                        });
                      },
                    ),
                ],
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildUserImage(images[index]),
                  );
                },
              ),
            ),
          ],
        );
      }
    }

    // CurrentUser resimleri yoksa, Firebase'den resimleri çek
    return FutureBuilder<List<String>>(
      future:
          userId.isNotEmpty
              ? _userRepository.getUserImages(userId)
              : Future.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildSectionCard(
            title: "Fotoğraflarım",
            child: Center(child: CircularProgressIndicator(color: Colors.red)),
          );
        }

        if (snapshot.hasError) {
          print("Resim yükleme hatası: ${snapshot.error}");
          return buildSectionCard(
            title: "Fotoğraflarım",
            child: Center(
              child: Text(
                "Fotoğraflar yüklenirken hata oluştu",
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        List<String> images = snapshot.data ?? [];
        print("Firebase'den ${images.length} resim yüklendi");

        Widget content;
        if (images.isEmpty) {
          // Hiç resim yoksa özel bir içerik göster
          content = Center(
            child:
                isCurrentUserProfile
                    ? GestureDetector(
                      onTap: () {
                        // Fotoğraf ekleme sayfasına git
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    UploadImagePage(userId: firebaseUser!.uid),
                          ),
                        ).then((_) {
                          // Sayfadan dönünce sayfayı yenile
                          setState(() {});
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 30,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.grey,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Henüz fotoğrafınız yok.\nFotoğraf eklemek için tıklayın",
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                    : Text(
                      "Kullanıcının henüz fotoğrafı bulunmuyor",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
          );
        } else {
          // Resimler varsa grid view ile göster
          content = GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildUserImage(images[index]),
              );
            },
          );
        }

        return buildSectionCard(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Fotoğraflarım",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (isCurrentUserProfile)
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.red, size: 22),
                  tooltip: "Fotoğrafları Düzenle",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                UploadImagePage(userId: firebaseUser!.uid),
                      ),
                    ).then((_) {
                      // Sayfadan dönünce sayfayı yenile
                      setState(() {});
                    });
                  },
                ),
            ],
          ),
          child: content,
        );
      },
    );
  }

  Widget buildSettingsSection() {
    // Sadece kullanıcının kendi profilinde ayarlar bölümünü göster
    if (!isCurrentUserProfile) {
      return SizedBox.shrink(); // Başkasının profilinde ayarlar bölümünü gizle
    }

    return buildSectionCard(
      title: "Ayarlar",
      child: Column(
        children: [
          buildSettingItem(
            icon: Icons.notifications,
            title: "Bildirimler",
            subtitle: "Bildirimleri yönetin",
            onTap: _showNotificationSettings,
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.privacy_tip,
            title: "Gizlilik",
            subtitle: "Gizlilik ayarlarını düzenleyin",
            onTap: _showPrivacySettings,
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.security,
            title: "Güvenlik",
            subtitle: "Hesap güvenliği ayarları",
            onTap: _showSecuritySettings,
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.help,
            title: "Yardım ve Destek",
            subtitle: "SSS ve iletişim",
            onTap: _showHelpAndSupport,
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.logout,
            title: "Çıkış Yap",
            subtitle: "Hesabınızdan güvenli çıkış yapın",
            onTap: _showLogoutConfirmation,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isDestructive
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDestructive ? Colors.red : Colors.grey[800],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget buildSectionCard({required dynamic title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title is String
                ? Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                )
                : title,
            SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildNavItem(
            icon: Ikon.star_half_alt,
            label: "Keşfet",
            isActive: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          buildNavItem(
            icon: Icons.people_rounded,
            label: "Eşleş",
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MatchPage()),
              );
            },
          ),
          buildNavItem(
            icon: Icons.message,
            label: "Sohbet",
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MessagePage()),
              );
            },
          ),
          buildNavItem(
            icon: Icons.person,
            label: "Profil",
            isActive: true,
            onTap: () {
              // zaten profil sayfasındayız
            },
          ),
        ],
      ),
    );
  }

  Widget buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isActive ? Colors.red.withOpacity(0.1) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26,
              color: isActive ? Colors.red : Colors.grey,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Hakkımda bilgisini güncelle
  Future<void> _updateAboutMe(String newAboutMe) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'aboutMe': newAboutMe,
      });

      setState(() {
        aboutMe = newAboutMe;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hakkımda bilgisi güncellendi")));
    } catch (e) {
      print("Hakkımda güncellenirken hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme sırasında bir hata oluştu")),
      );
    }
  }

  // İlgi alanlarını güncelle
  Future<void> _updateInterests(List<String> newInterests) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'interests': newInterests,
      });

      setState(() {
        interests = newInterests;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("İlgi alanları güncellendi")));
    } catch (e) {
      print("İlgi alanları güncellenirken hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme sırasında bir hata oluştu")),
      );
    }
  }

  // Hakkımda düzenleme diyaloğu
  void _showEditAboutMeDialog() {
    final textController = TextEditingController(text: aboutMe);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Hakkımda"),
            content: TextField(
              controller: textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Kendinizi tanıtın...",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateAboutMe(textController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text("Kaydet"),
              ),
            ],
          ),
    );
  }

  // İlgi alanları düzenleme diyaloğu
  void _showEditInterestsDialog() {
    // Varsayılan ilgi alanları seçenekleri
    final allInterests = [
      "Müzik",
      "Spor",
      "Seyahat",
      "Fotoğrafçılık",
      "Arkadaşlarla Sosyalleşmek",
      "Doğa Yürüyüşü",
      "Sinema",
      "Yoga",
      "Teknoloji",
      "Kitap Okuma",
      "Yemek Pişirme",
      "Oyun",
      "Dans",
      "Sanat",
      "Köpekler",
      "Kediler",
    ];

    // Kullanıcının seçtiği ilgi alanları
    List<String> selectedInterests = List.from(interests);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text("İlgi Alanlarım"),
                  content: Container(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "İlgi alanlarınızı seçin (en fazla 8)",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              allInterests.map((interest) {
                                final isSelected = selectedInterests.contains(
                                  interest,
                                );
                                return FilterChip(
                                  label: Text(interest),
                                  selected: isSelected,
                                  onSelected: (value) {
                                    setDialogState(() {
                                      if (value) {
                                        if (selectedInterests.length < 8) {
                                          selectedInterests.add(interest);
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "En fazla 8 ilgi alanı seçebilirsiniz",
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        selectedInterests.remove(interest);
                                      }
                                    });
                                  },
                                  selectedColor: Colors.red.withOpacity(0.2),
                                  checkmarkColor: Colors.red,
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("İptal"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateInterests(selectedInterests);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text("Kaydet"),
                    ),
                  ],
                ),
          ),
    );
  }

  // Firebase oturumunu kapatacak fonksiyon
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // Tüm sayfaları kapatıp Login sayfasına yönlendir
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      print("Çıkış yapılırken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Çıkış yapılırken bir sorun oluştu")),
      );
    }
  }

  // Çıkış onay diyaloğunu göster
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Çıkış Yap"),
            content: Text(
              "Hesabınızdan çıkış yapmak istediğinize emin misiniz?",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Diyaloğu kapat
                },
                child: Text("İptal", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Diyaloğu kapat
                  _signOut(); // Çıkış yap
                },
                child: Text("Çıkış Yap"),
              ),
            ],
          ),
    );
  }

  // Settings öğeleri için action fonksiyonları
  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Bildirim ayarları yakında aktif olacak")),
    );
  }

  void _showPrivacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Gizlilik ayarları yakında aktif olacak")),
    );
  }

  void _showSecuritySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Güvenlik ayarları yakında aktif olacak")),
    );
  }

  void _showHelpAndSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Yardım ve destek yakında aktif olacak")),
    );
  }
}
