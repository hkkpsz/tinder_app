import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'ikon_icons.dart';
import 'pages/home_page.dart';
import 'pages/match_page.dart';
import 'pages/message_page.dart';
import 'users.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/upload_image.dart';

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

  // Geçerli bir image URL oluşturmak için yardımcı metod
  String _getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      // Boş URL durumunda varsayılan bir URL göster
      return 'https://ui-avatars.com/api/?name=User&background=random';
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
    return 'https://ui-avatars.com/api/?name=User&background=random';
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Eğer doğrudan bir kullanıcı nesnesi verilmişse, onu kullan
      if (widget.user != null) {
        setState(() {
          currentUser = widget.user;
          isLoading = false;
        });
        return;
      }

      // Firebase'den mevcut oturum açmış kullanıcıyı al
      final currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser != null) {
        await _loadUserFromFirebase(currentFirebaseUser.uid);
      } else if (widget.userId != null) {
        // Eğer userId verilmişse o kullanıcıyı yükle
        await _loadUserFromFirebase(widget.userId!);
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
      // Firebase'den kullanıcı bilgilerini al
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        setState(() {
          errorMessage = 'Kullanıcı profili bulunamadı';
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // PostgreSQL'den kullanıcının resmini al
      final userImages = await _fetchUserImagesFromPostgres(userId);

      // User nesnesini oluştur
      User user = User.fromDatabase(
        name: userData['ad'] ?? 'İsimsiz',
        age: userData['yas'] ?? 0,
        workplace: userData['workplace'] ?? '',
        imagePath:
            userImages.isNotEmpty
                ? userImages.first
                : 'https://ui-avatars.com/api/?name=User&background=random',
        additionalImages: userImages.length > 1 ? userImages.sublist(1) : [],
      );

      setState(() {
        currentUser = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcı profili yüklenirken hata oluştu: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  Future<List<String>> _fetchUserImagesFromPostgres(String firebaseUid) async {
    final connection = PostgreSQLConnection(
      '10.0.2.2', // host bilgisi
      5432, // port
      'postgres', // veritabanı adı
      username: 'postgres',
      password: 'hktokat0660',
    );

    try {
      await connection.open();

      // Önce Firebase UID'ye göre PostgreSQL user_id'yi bul
      final userIdResults = await connection.query(
        'SELECT id FROM users WHERE firebase_uid = @firebaseUid',
        substitutionValues: {'firebaseUid': firebaseUid},
      );

      if (userIdResults.isEmpty) {
        return ['https://ui-avatars.com/api/?name=User&background=random'];
      }

      final userId = userIdResults.first[0];

      // Kullanıcıya ait tüm resimleri çek
      final imageResults = await connection.query(
        'SELECT image_url FROM image WHERE user_id = @userId ORDER BY createdat DESC',
        substitutionValues: {'userId': userId},
      );

      List<String> imagePaths = [];

      for (final row in imageResults) {
        String imageUrl = row[0]; // image_url
        if (imageUrl != null && imageUrl.isNotEmpty) {
          imagePaths.add(_getValidImageUrl(imageUrl));
        }
      }

      // Eğer hiç resim bulunamadıysa varsayılan URL'yi ekle
      if (imagePaths.isEmpty) {
        imagePaths.add(
          'https://ui-avatars.com/api/?name=User&background=random',
        );
      }

      return imagePaths;
    } catch (e) {
      print("Kullanıcı resimleri çekilirken hata: $e");
      return ['https://ui-avatars.com/api/?name=User&background=random'];
    } finally {
      await connection.close();
    }
  }

  Future<List<User>> fetchUsersWithImages() async {
    final connection = PostgreSQLConnection(
      '10.0.2.2', // host bilgisi
      5432, // port
      'postgres', // veritabanı adı
      username: 'postgres',
      password: 'hktokat0660',
    );

    try {
      await connection.open();
      print("Veritabanı bağlantısı başarılı");

      // Kullanıcıları çek
      final userResults = await connection.query('SELECT * FROM users');

      List<User> fetchedUsers = [];

      // Her kullanıcı için resimleri çek
      for (final userRow in userResults) {
        final userId = userRow[0]; // user_id
        final userName = userRow[2]; // name
        final userAge = userRow[3]; // age
        final userWorkplace = userRow[5]; // workplace

        // Kullanıcıya ait resim bilgilerini çek
        final imageResults = await connection.query(
          'SELECT image_url FROM image WHERE user_id = @userId ORDER BY createdat DESC LIMIT 1',
          substitutionValues: {'userId': userId},
        );

        // Varsayılan avatar URL'si
        String imagePath =
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=random';

        if (imageResults.isNotEmpty) {
          // Resim URL'sini al
          String imageUrl = imageResults.first[0]; // image_url
          if (imageUrl != null && imageUrl.isNotEmpty) {
            imagePath = _getValidImageUrl(imageUrl);
          }
        }

        fetchedUsers.add(
          User.fromDatabase(
            name: userName,
            age: userAge,
            workplace: userWorkplace,
            imagePath: imagePath,
          ),
        );
      }

      return fetchedUsers;
    } catch (e) {
      print("Veritabanı hatası: $e");
      throw Exception('Veritabanından kullanıcılar çekilemedi: $e');
    } finally {
      await connection.close();
    }
  }

  // Kullanıcının tüm resimlerini çek
  Future<List<String>> fetchUserImages(int userId) async {
    final connection = PostgreSQLConnection(
      '10.0.2.2', // host bilgisi
      5432, // port
      'postgres', // veritabanı adı
      username: 'postgres',
      password: 'hktokat0660',
    );

    try {
      await connection.open();

      // Kullanıcıya ait tüm resimleri çek
      final imageResults = await connection.query(
        'SELECT image_url FROM image WHERE user_id = @userId ORDER BY createdat DESC',
        substitutionValues: {'userId': userId},
      );

      List<String> imagePaths = [];

      for (final row in imageResults) {
        String imageUrl = row[0]; // image_url
        if (imageUrl != null && imageUrl.isNotEmpty) {
          imagePaths.add(_getValidImageUrl(imageUrl));
        }
      }

      // Eğer hiç resim bulunamadıysa varsayılan URL'yi ekle
      if (imagePaths.isEmpty) {
        imagePaths.add(
          'https://ui-avatars.com/api/?name=User&background=random',
        );
      }

      return imagePaths;
    } catch (e) {
      print("Kullanıcı resimleri çekilirken hata: $e");
      return ['https://ui-avatars.com/api/?name=User&background=random'];
    } finally {
      await connection.close();
    }
  }

  // Image widget oluşturan yardımcı metod
  Widget _buildUserImage(String? imageUrl) {
    final url = _getValidImageUrl(imageUrl);

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
        // Sessizce hata loglamak yerine fallback avatar göster
        return Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.person, color: Colors.grey, size: 50),
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
            // Düzenleme butonu
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
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Profili Düzenle",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildAboutSection() {
    return buildSectionCard(
      title: "Hakkımda",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            "Merhaba! Ben bir yazılım geliştiricisiyim ve bilgisayara bayılırım. Yeni insanlarla tanışmayı ve farklı kültürleri keşfetmeyi seviyorum.",
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget buildInterestsSection() {
    return buildSectionCard(
      title: "İlgi Alanlarım",
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
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
    return FutureBuilder<List<String>>(
      future: fetchUserImages(widget.userIndex),
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = Center(child: CircularProgressIndicator(color: Colors.red));
        } else if (snapshot.hasError) {
          content = Center(
            child: Text(
              "Fotoğraflar yüklenirken hata oluştu",
              style: TextStyle(color: Colors.red),
            ),
          );
        } else {
          List<String> images = snapshot.data ?? [];
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
        return Stack(
          children: [
            buildSectionCard(title: "Fotoğraflarım", child: content),
            Positioned(top: 12, right: 18, child: _buildEditPhotosButton()),
          ],
        );
      },
    );
  }

  Widget _buildEditPhotosButton() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return SizedBox.shrink();
    return IconButton(
      icon: Icon(Icons.edit, color: Colors.red, size: 22),
      tooltip: "Fotoğrafları Düzenle",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UploadImagePage(userId: firebaseUser.uid),
          ),
        );
      },
    );
  }

  Widget buildSettingsSection() {
    return buildSectionCard(
      title: "Ayarlar",
      child: Column(
        children: [
          buildSettingItem(
            icon: Icons.notifications,
            title: "Bildirimler",
            subtitle: "Bildirimleri yönetin",
            onTap: () {},
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.privacy_tip,
            title: "Gizlilik",
            subtitle: "Gizlilik ayarlarını düzenleyin",
            onTap: () {},
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.security,
            title: "Güvenlik",
            subtitle: "Hesap güvenliği ayarları",
            onTap: () {},
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.help,
            title: "Yardım ve Destek",
            subtitle: "SSS ve iletişim",
            onTap: () {},
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.logout,
            title: "Çıkış Yap",
            subtitle: "Hesabınızdan güvenli çıkış yapın",
            onTap: () {},
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

  Widget buildSectionCard({required String title, required Widget child}) {
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
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
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
}
