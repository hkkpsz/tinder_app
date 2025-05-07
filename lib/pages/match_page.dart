import 'package:flutter/material.dart';
import 'package:ucanble_tinder/profile_detail.dart';
import '../ikon_icons.dart';
import '../users.dart';
import 'home_page.dart';
import 'message_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage>
    with SingleTickerProviderStateMixin {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  String errorMessage = '';

  // Tablar için gerekli controller
  late TabController _tabController;

  // Aksiyon türlerine göre kullanıcıları tutacak listeler
  List<Map<String, dynamic>> likedUsers = [];
  List<Map<String, dynamic>> superLikedUsers = [];
  List<Map<String, dynamic>> dislikedUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserActions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Kullanıcı aksiyonlarını Firestore'dan yükle
  Future<void> _loadUserActions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          errorMessage = 'Giriş yapmış kullanıcı bulunamadı';
          isLoading = false;
        });
        return;
      }

      // Bütün aksiyonları tek seferde al ve sonra filtrele
      final actionSnapshot =
          await _firestore
              .collection('userActions')
              .where('userId', isEqualTo: currentUser.uid)
              .get();

      // Client tarafında filtrele
      final allActions = actionSnapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        // Aksiyon türüne göre client tarafında filtrele
        likedUsers =
            allActions
                .where((action) => action['actionType'] == 'like')
                .toList();
        superLikedUsers =
            allActions
                .where((action) => action['actionType'] == 'superlike')
                .toList();
        dislikedUsers =
            allActions
                .where((action) => action['actionType'] == 'dislike')
                .toList();

        // Tarihe göre sıralama (eğer createdAt varsa)
        likedUsers.sort((a, b) {
          if (a['createdAt'] == null || b['createdAt'] == null) return 0;
          return (b['createdAt'] as Timestamp).compareTo(
            a['createdAt'] as Timestamp,
          );
        });

        superLikedUsers.sort((a, b) {
          if (a['createdAt'] == null || b['createdAt'] == null) return 0;
          return (b['createdAt'] as Timestamp).compareTo(
            a['createdAt'] as Timestamp,
          );
        });

        dislikedUsers.sort((a, b) {
          if (a['createdAt'] == null || b['createdAt'] == null) return 0;
          return (b['createdAt'] as Timestamp).compareTo(
            a['createdAt'] as Timestamp,
          );
        });

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcı aksiyonları yüklenirken hata oluştu: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  // Geçerli bir image URL oluşturmak için yardımcı metod
  String _getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      // Boş URL durumunda varsayılan bir Cloudinary URL göster
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

    // Diğer tüm durumlarda varsayılan avatar URL'si kullan
    return 'https://ui-avatars.com/api/?name=User&background=random';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.red.shade300, Colors.redAccent.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Ikon.think_peaks, color: Colors.white, size: 24),
            ),
            Text(
              "Eşleşmelerim",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                icon: Icon(Ikon.list, color: Colors.grey[800], size: 20),
                padding: EdgeInsets.all(8),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red,
          tabs: [
            Tab(icon: Icon(Icons.favorite), text: "Beğendiklerim"),
            Tab(icon: Icon(Icons.star), text: "Super Like"),
            Tab(icon: Icon(Icons.close), text: "Beğenmediklerim"),
          ],
        ),
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.red))
              : errorMessage.isNotEmpty
              ? Center(
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
                      onPressed: _loadUserActions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text("Tekrar Dene"),
                    ),
                  ],
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Beğendiklerim Tab
                    buildUserList(likedUsers, 'like'),

                    // Super Like Tab
                    buildUserList(superLikedUsers, 'superlike'),

                    // Beğenmediklerim Tab
                    buildUserList(dislikedUsers, 'dislike'),
                  ],
                ),
              ),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  // Kullanıcı listesini oluşturan widget
  Widget buildUserList(List<Map<String, dynamic>> users, String actionType) {
    if (users.isEmpty) {
      return buildEmptyState(actionType);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return buildUserCard(user, actionType);
        },
      ),
    );
  }

  // Boş durum mesajı gösteren widget
  Widget buildEmptyState(String actionType) {
    String message = '';
    IconData icon = Icons.info_outline;

    switch (actionType) {
      case 'like':
        message = 'Henüz beğendiğiniz kullanıcı yok';
        icon = Icons.favorite_border;
        break;
      case 'superlike':
        message = 'Henüz super like attığınız kullanıcı yok';
        icon = Icons.star_border;
        break;
      case 'dislike':
        message = 'Henüz beğenmediğiniz kullanıcı yok';
        icon = Icons.thumb_down_alt_outlined;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.search),
            label: Text('Kullanıcıları Keşfet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Kullanıcı kartını oluşturan widget
  Widget buildUserCard(Map<String, dynamic> userData, String actionType) {
    Color badgeColor;
    IconData badgeIcon;

    switch (actionType) {
      case 'like':
        badgeColor = Colors.red;
        badgeIcon = Icons.favorite;
        break;
      case 'superlike':
        badgeColor = Colors.blue;
        badgeIcon = Icons.star;
        break;
      case 'dislike':
        badgeColor = Colors.grey;
        badgeIcon = Icons.close;
        break;
      default:
        badgeColor = Colors.red;
        badgeIcon = Icons.favorite;
    }

    final userId = userData['targetUserId'];

    return InkWell(
      onTap: () {
        print("Kullanıcı kartına tıklandı: $userId");

        if (userId != null) {
          try {
            print("Profil sayfasına yönlendiriliyor: $userId");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileDetail(userId: userId),
              ),
            ).then((_) {
              print("Profil sayfasından geri dönüldü");
            });
          } catch (e) {
            print("Profil yönlendirmede hata: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profil açılırken bir hata oluştu: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print("Geçersiz userId: null");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bu kullanıcı için detay bilgileri bulunamadı.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _buildUserImage(userData['targetUserImage']),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${userData['targetUserName'] ?? 'İsimsiz'}, ${userData['targetUserAge'] ?? '?'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        if (userData['targetUserWorkplace'] != null)
                          Text(
                            "${userData['targetUserWorkplace']}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Aksiyon türü rozeti
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(badgeIcon, color: Colors.white, size: 16),
              ),
            ),

            // Profil görüntüleme göstergesi
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.white, size: 12),
                    SizedBox(width: 2),
                    Text(
                      "Profili Gör",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Resim widget'ı oluşturan yardımcı metod
  Widget _buildUserImage(String? imageUrl) {
    final url = _getValidImageUrl(imageUrl);

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
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
        print("Resim yüklenirken hata: $error");
        return Container(
          color: Colors.grey.shade300,
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        );
      },
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
            isActive: true,
            onTap: () {
              // Zaten eşleşme sayfasındayız
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
            isActive: false,
            onTap: () {
              // Profil sayfasına git (mevcut kullanıcı için)
              final currentUser = _auth.currentUser;
              if (currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProfileDetail(userId: currentUser.uid),
                  ),
                );
              }
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isActive ? Colors.red.withOpacity(0.1) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: isActive ? Colors.red : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
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
