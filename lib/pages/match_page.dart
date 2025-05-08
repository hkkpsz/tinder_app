import 'package:flutter/material.dart';
import 'package:ucanble_tinder/profile_detail.dart';
import '../ikon_icons.dart';
import '../users.dart';
import 'home_page.dart';
import 'message_page.dart';
import 'chat_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ucanble_tinder/repositories/user_repository.dart';
import 'package:ucanble_tinder/services/firebase_service.dart';
import 'dart:math'; // Hesaplama için math kütüphanesi

// Yeni Eşleşme Algoritması sınıfı
class MatchAlgorithm {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();
  final FirebaseService _firebaseService = FirebaseService();

  // İnterest alanları için puan değerleri
  static const Map<String, double> interestWeights = {
    'spor': 0.3,
    'müzik': 0.2,
    'film': 0.2,
    'seyahat': 0.4,
    'yemek': 0.2,
    'teknoloji': 0.3,
    'sanat': 0.3,
    'kitap': 0.2,
    'dans': 0.3,
    'fotoğrafçılık': 0.2,
  };

  // Kullanıcının ilgi alanlarını getir
  Future<List<String>> _getUserInterests(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> interests = data['interests'] ?? [];
        return interests.cast<String>();
      }
      return [];
    } catch (e) {
      print("Kullanıcı ilgi alanları getirilirken hata: $e");
      return [];
    }
  }

  // Kullanıcının konumunu getir
  Future<GeoPoint?> _getUserLocation(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['location'] as GeoPoint?;
      }
      return null;
    } catch (e) {
      print("Kullanıcı konumu getirilirken hata: $e");
      return null;
    }
  }

  // İki konum arasındaki mesafeyi hesapla (km)
  double _calculateDistance(GeoPoint? location1, GeoPoint? location2) {
    if (location1 == null || location2 == null) return double.infinity;

    var lat1 = location1.latitude;
    var lon1 = location1.longitude;
    var lat2 = location2.latitude;
    var lon2 = location2.longitude;

    var p = 0.017453292519943295; // Pi/180
    var a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;

    return 12742 * asin(sqrt(a)); // 2*R*asin... (R = 6371 km, dünya yarıçapı)
  }

  // İki kullanıcı arasındaki yaş benzerliğini hesapla (0-1 arasında, 1 en iyi)
  double _calculateAgeSimilarity(int age1, int age2) {
    int ageDiff = (age1 - age2).abs();

    if (ageDiff == 0) return 1.0;
    if (ageDiff <= 3) return 0.9;
    if (ageDiff <= 5) return 0.7;
    if (ageDiff <= 10) return 0.5;
    return 0.3;
  }

  // İki kullanıcı arasındaki ilgi alanları benzerliğini hesapla (0-1 arasında, 1 en iyi)
  double _calculateInterestSimilarity(
    List<String> interests1,
    List<String> interests2,
  ) {
    if (interests1.isEmpty || interests2.isEmpty) return 0.0;

    // Ortak ilgi alanlarını bul
    Set<String> set1 = Set<String>.from(interests1);
    Set<String> set2 = Set<String>.from(interests2);
    Set<String> commonInterests = set1.intersection(set2);

    // Ortak ilgi alanları yoksa 0 döner
    if (commonInterests.isEmpty) return 0.0;

    // Ortak ilgi alanlarının ağırlıklı puanını hesapla
    double totalWeight = 0.0;
    for (String interest in commonInterests) {
      totalWeight += interestWeights[interest] ?? 0.2; // Varsayılan ağırlık 0.2
    }

    // Maksimum 5 ilgi alanı için normalize et
    return min(totalWeight, 1.0);
  }

  // İki kullanıcı arasındaki eşleşme puanını hesapla
  Future<double> calculateMatchScore(String userId1, String userId2) async {
    try {
      // Kullanıcı 1'in bilgilerini al
      Map<String, dynamic>? user1Data = await _firebaseService.getUserData(
        userId1,
      );
      // Kullanıcı 2'nin bilgilerini al
      Map<String, dynamic>? user2Data = await _firebaseService.getUserData(
        userId2,
      );

      if (user1Data == null || user2Data == null) return 0.0;

      // İlgi alanları
      List<String> interests1 = await _getUserInterests(userId1);
      List<String> interests2 = await _getUserInterests(userId2);

      // Konum bilgileri
      GeoPoint? location1 = await _getUserLocation(userId1);
      GeoPoint? location2 = await _getUserLocation(userId2);

      // Yaş bilgileri
      int age1 = user1Data['age'] ?? 25;
      int age2 = user2Data['age'] ?? 25;

      // Benzerlik skorları (0-1 arasında)
      double interestSimilarity = _calculateInterestSimilarity(
        interests1,
        interests2,
      );

      // Yaş benzerliği (0-1 arasında)
      double ageSimilarity = _calculateAgeSimilarity(age1, age2);

      // Mesafe puanı (uzaklık arttıkça puan düşer)
      double distanceScore = 1.0;
      if (location1 != null && location2 != null) {
        double distance = _calculateDistance(location1, location2);
        // 0-10km: 1.0
        // 10-30km: 0.8
        // 30-50km: 0.6
        // 50-100km: 0.4
        // 100+km: 0.2
        if (distance <= 10)
          distanceScore = 1.0;
        else if (distance <= 30)
          distanceScore = 0.8;
        else if (distance <= 50)
          distanceScore = 0.6;
        else if (distance <= 100)
          distanceScore = 0.4;
        else
          distanceScore = 0.2;
      }

      // Farklı faktörlerin ağırlıklı ortalaması
      // İlgi alanları: %40, Yaş: %30, Mesafe: %30
      double matchScore =
          (interestSimilarity * 0.4) +
          (ageSimilarity * 0.3) +
          (distanceScore * 0.3);

      // Super Like aksiyonu varsa ekstra puan ekle
      bool hasSuperLike = await _checkSuperLike(userId1, userId2);
      if (hasSuperLike) {
        matchScore += 0.2; // Super Like varsa +20% puan ekleniyor
        matchScore = min(
          matchScore,
          1.0,
        ); // Maksimum 1.0 olacak şekilde sınırla
      }

      return matchScore;
    } catch (e) {
      print("Eşleşme puanı hesaplanırken hata: $e");
      return 0.0;
    }
  }

  // Super Like kontrolü
  Future<bool> _checkSuperLike(String userId1, String userId2) async {
    try {
      final snapshot =
          await _firestore
              .collection('userActions')
              .where('userId', isEqualTo: userId1)
              .where('targetUserId', isEqualTo: userId2)
              .where('actionType', isEqualTo: 'superlike')
              .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Super Like kontrolü yapılırken hata: $e");
      return false;
    }
  }

  // Kullanıcı için en iyi eşleşmeleri getir
  Future<List<Map<String, dynamic>>> getBestMatches(
    String userId, {
    int limit = 10,
  }) async {
    try {
      // Tüm kullanıcıları getir
      final users = await _firebaseService.getAllUsers();

      // Puan hesaplamaları için liste oluştur
      List<Map<String, dynamic>> scoredUsers = [];

      // Her kullanıcı için eşleşme puanını hesapla
      for (var user in users) {
        String targetUserId = user['id'];
        double score = await calculateMatchScore(userId, targetUserId);

        scoredUsers.add({'user': user, 'score': score});
      }

      // Puanlara göre azalan sırada sırala
      scoredUsers.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );

      // İstenilen sayıda en iyi eşleşmeyi döndür
      List<Map<String, dynamic>> bestMatches =
          scoredUsers.take(limit).map((item) {
            Map<String, dynamic> user = item['user'];
            user['matchScore'] = item['score'];
            return user;
          }).toList();

      return bestMatches;
    } catch (e) {
      print("En iyi eşleşmeler getirilirken hata: $e");
      return [];
    }
  }

  // Kullanıcı için günlük eşleşme önerileri
  Future<List<Map<String, dynamic>>> getDailyRecommendations(
    String userId, {
    int count = 5,
  }) async {
    try {
      // En iyi 20 eşleşmeyi getir
      List<Map<String, dynamic>> bestMatches = await getBestMatches(
        userId,
        limit: 20,
      );

      // Rasgele seçim için
      final random = Random();

      // Eğer yeterli eşleşme varsa, önce en yüksek puanlı 10 kullanıcıyı al
      // sonra bunlar arasından rasgele 5 tanesini seç
      List<Map<String, dynamic>> recommendations = [];

      if (bestMatches.length <= count) {
        // Eğer eşleşme sayısı istenilen sayıdan az veya eşitse, tümünü döndür
        return bestMatches;
      } else {
        // Top 10 eşleşmeden rasgele seç
        List<Map<String, dynamic>> topMatches = bestMatches.take(10).toList();

        // Rasgele seçim için liste karıştır
        topMatches.shuffle(random);

        // İstenilen sayıda öneri döndür
        recommendations = topMatches.take(count).toList();
        return recommendations;
      }
    } catch (e) {
      print("Günlük öneriler getirilirken hata: $e");
      return [];
    }
  }
}

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage>
    with SingleTickerProviderStateMixin {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MatchAlgorithm _matchAlgorithm = MatchAlgorithm();
  final FirebaseService _firebaseService = FirebaseService();

  bool isLoading = true;
  String errorMessage = '';

  // Okunmamış mesaj sayısı
  int _unreadMessagesCount = 0;

  // Tablar için gerekli controller
  late TabController _tabController;

  // Aksiyon türlerine göre kullanıcıları tutacak listeler
  List<Map<String, dynamic>> likedUsers = [];
  List<Map<String, dynamic>> superLikedUsers = [];
  List<Map<String, dynamic>> dislikedUsers = [];

  // Yeni eklenen önerilen eşleşmeler listesi
  List<Map<String, dynamic>> recommendedMatches = [];

  // Eşleşmelerim listesi
  List<Map<String, dynamic>> myMatches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
    ); // 5 taba çıkardık (eşleşmelerim için)
    _loadUserActions();
    _loadRecommendedMatches();
    _loadMyMatches();
    _loadUnreadMessagesCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Önerilen eşleşmeleri yükle
  Future<void> _loadRecommendedMatches() async {
    try {
      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
      setState(() {
        isLoading = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
        setState(() {
          errorMessage = 'Giriş yapmış kullanıcı bulunamadı';
          isLoading = false;
        });
        return;
      }

      // Günlük önerileri al
      final recommendations = await _matchAlgorithm.getDailyRecommendations(
        currentUser.uid,
      );

      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
      setState(() {
        recommendedMatches = recommendations;
        isLoading = false;
      });

      print("${recommendations.length} önerilen eşleşme yüklendi");
    } catch (e) {
      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
      setState(() {
        errorMessage = 'Önerilen eşleşmeler yüklenirken hata oluştu: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  // Eşleşmelerimi yükle
  Future<void> _loadMyMatches() async {
    try {
      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
      setState(() {
        isLoading = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Giriş yapmış kullanıcı bulunamadı';
          isLoading = false;
        });
        return;
      }

      // Kullanıcının eşleşmelerini bul (hem user1Id hem de user2Id olarak)
      final matchesQuery1 =
          await _firestore
              .collection('matches')
              .where('user1Id', isEqualTo: currentUser.uid)
              .get();

      final matchesQuery2 =
          await _firestore
              .collection('matches')
              .where('user2Id', isEqualTo: currentUser.uid)
              .get();

      // Eşleşmeleri birleştir
      final matchDocs = [...matchesQuery1.docs, ...matchesQuery2.docs];

      // Eşleşen kullanıcıların bilgilerini topla
      List<Map<String, dynamic>> matches = [];

      for (var doc in matchDocs) {
        final matchData = doc.data();
        final matchId = doc.id;

        // Eşleşen diğer kullanıcının ID'sini belirle
        String otherUserId =
            matchData['user1Id'] == currentUser.uid
                ? matchData['user2Id']
                : matchData['user1Id'];

        // Diğer kullanıcının bilgilerini al
        Map<String, dynamic>? userData = await _firebaseService.getUserData(
          otherUserId,
        );

        if (userData != null) {
          matches.add({
            'matchId': matchId,
            'userId': otherUserId,
            'name': userData['name'],
            'age': userData['age'],
            'workplace': userData['workplace'],
            'image':
                userData['images'] != null && userData['images'].isNotEmpty
                    ? userData['images'][0]
                    : null,
            'lastMessage': matchData['lastMessage'] ?? '',
            'lastMessageTime': matchData['lastMessageTime'],
            'createdAt': matchData['createdAt'],
          });
        }
      }

      // Tarihe göre sırala (en yeni eşleşme en üstte)
      matches.sort((a, b) {
        if (a['createdAt'] == null || b['createdAt'] == null) return 0;
        return (b['createdAt'] as Timestamp).compareTo(
          a['createdAt'] as Timestamp,
        );
      });

      if (!mounted) return;
      setState(() {
        myMatches = matches;
        isLoading = false;
      });

      print("${matches.length} eşleşme yüklendi");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Eşleşmeleriniz yüklenirken hata oluştu: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  // Kullanıcı aksiyonlarını Firestore'dan yükle
  Future<void> _loadUserActions() async {
    try {
      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
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

      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
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
      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
      setState(() {
        errorMessage = 'Kullanıcı aksiyonları yüklenirken hata oluştu: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  // Okunmamış mesaj sayısını yükle
  Future<void> _loadUnreadMessagesCount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      int count = await _firebaseService.getUnreadMessagesCount(
        currentUser.uid,
      );

      if (!mounted) return;
      setState(() {
        _unreadMessagesCount = count;
      });

      print("Okunmamış mesaj sayısı: $_unreadMessagesCount");
    } catch (e) {
      print("Okunmamış mesaj sayısı yüklenirken hata: $e");
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
          isScrollable: true, // Sekmelerin yatay kaydırılabilir olması için
          tabs: [
            Tab(icon: Icon(Icons.recommend), text: "Önerilen"),
            Tab(icon: Icon(Icons.favorite_border), text: "Eşleşmelerim"),
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
                      onPressed: () {
                        _loadUserActions();
                        _loadRecommendedMatches();
                        _loadMyMatches();
                      },
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
                    // Önerilen Eşleşmeler Tab
                    buildRecommendedMatches(),

                    // Eşleşmelerim Tab
                    buildMyMatches(),

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

    return Column(
      children: [
        // Temizleme düğmesi ekle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${users.length} kişi listeleniyor",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showClearConfirmationDialog(actionType),
                icon: Icon(Icons.delete_sweep, color: Colors.red, size: 18),
                label: Text("Temizle", style: TextStyle(color: Colors.red)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Kullanıcı listesi
        Expanded(
          child: Padding(
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
          ),
        ),
      ],
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
            hasNotification: _unreadMessagesCount > 0,
            notificationCount: _unreadMessagesCount,
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
    bool hasNotification = false,
    int notificationCount = 0,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? Colors.red.withOpacity(0.1)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: isActive ? Colors.red : Colors.grey,
                ),
              ),
              if (hasNotification)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: EdgeInsets.all(notificationCount > 9 ? 3 : 5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape:
                          notificationCount > 9
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                      borderRadius:
                          notificationCount > 9
                              ? BorderRadius.circular(10)
                              : null,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: BoxConstraints(
                      minWidth: notificationCount > 9 ? 18 : 15,
                      minHeight: 15,
                    ),
                    child:
                        notificationCount > 0
                            ? Center(
                              child: Text(
                                notificationCount > 99
                                    ? '99+'
                                    : '$notificationCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: notificationCount > 9 ? 8 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            : Container(),
                  ),
                ),
            ],
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

  // Önerilen eşleşmeleri gösteren widget
  Widget buildRecommendedMatches() {
    if (recommendedMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, color: Colors.grey, size: 80),
            SizedBox(height: 20),
            Text(
              "Henüz önerilen eşleşme bulunamadı!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Daha fazla kişiyi beğendiğinizde burada öneriler göreceksiniz.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadRecommendedMatches,
                  icon: Icon(Icons.refresh),
                  label: Text("Yenile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showClearAllConfirmationDialog(),
                  icon: Icon(Icons.cleaning_services),
                  label: Text("Tüm Geçmişi Temizle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Temizleme düğmesi ekle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${recommendedMatches.length} önerilen eşleşme",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showClearAllConfirmationDialog(),
                icon: Icon(Icons.delete_sweep, color: Colors.red, size: 18),
                label: Text(
                  "Tüm Geçmişi Temizle",
                  style: TextStyle(color: Colors.red),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: recommendedMatches.length,
            itemBuilder: (context, index) {
              final user = recommendedMatches[index];
              final matchScore = (user['matchScore'] as double?) ?? 0.0;
              final matchPercentage = (matchScore * 100).toInt();

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(
                          _getValidImageUrl(
                            user['images'] != null && user['images'].isNotEmpty
                                ? user['images'][0]
                                : null,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            user['name'] ?? 'İsimsiz',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "${user['age'] ?? '?'} yaş",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            user['workplace'] ?? 'İş bilgisi yok',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Uyum: %$matchPercentage",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                        onPressed: () {
                          // Kullanıcı profiline git
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      ProfileDetail(userId: user['id']),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.close,
                            color: Colors.grey,
                            label: "Geç",
                            onPressed: () async {
                              // Beğenmeme aksiyonu kaydet
                              await _saveUserAction(
                                User(
                                  userId: user['id'],
                                  name: user['name'],
                                  age: user['age'],
                                  workplace: user['workplace'],
                                  imagePath:
                                      user['images'] != null &&
                                              user['images'].isNotEmpty
                                          ? user['images'][0]
                                          : null,
                                ),
                                'dislike',
                              );

                              // Listeyi güncelle
                              setState(() {
                                recommendedMatches.removeAt(index);
                              });
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.favorite,
                            color: Colors.red,
                            label: "Beğen",
                            onPressed: () async {
                              // Beğenme aksiyonu kaydet
                              await _saveUserAction(
                                User(
                                  userId: user['id'],
                                  name: user['name'],
                                  age: user['age'],
                                  workplace: user['workplace'],
                                  imagePath:
                                      user['images'] != null &&
                                              user['images'].isNotEmpty
                                          ? user['images'][0]
                                          : null,
                                ),
                                'like',
                              );

                              // Listeyi güncelle
                              setState(() {
                                recommendedMatches.removeAt(index);
                              });

                              // Beğenme animasyonu göster
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder:
                                    (context) => AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                            size: 80,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            "Beğenildi!",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              );

                              Future.delayed(Duration(seconds: 1), () {
                                Navigator.of(context).pop();
                              });
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.star,
                            color: Colors.amber,
                            label: "Super Like",
                            onPressed: () async {
                              // Super Like aksiyonu kaydet
                              await _saveUserAction(
                                User(
                                  userId: user['id'],
                                  name: user['name'],
                                  age: user['age'],
                                  workplace: user['workplace'],
                                  imagePath:
                                      user['images'] != null &&
                                              user['images'].isNotEmpty
                                          ? user['images'][0]
                                          : null,
                                ),
                                'superlike',
                              );

                              // Listeyi güncelle
                              setState(() {
                                recommendedMatches.removeAt(index);
                              });

                              // Super Like animasyonu göster
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder:
                                    (context) => AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 80,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            "Super Like!",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              );

                              Future.delayed(Duration(seconds: 1), () {
                                Navigator.of(context).pop();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Aksiyon butonları için yardımcı metod
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: color,
            elevation: 2,
            shape: CircleBorder(),
            padding: EdgeInsets.all(12),
          ),
          child: Icon(icon, size: 28),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      ],
    );
  }

  // Kullanıcı aksiyonlarını Firestore'a kaydet
  Future<void> _saveUserAction(User targetUser, String actionType) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Oturum açmış kullanıcı bulunamadı');
        return;
      }

      // Aksiyon koleksiyonuna veri ekle
      await _firestore.collection('userActions').add({
        'userId': currentUser.uid,
        'targetUserId': targetUser.userId,
        'targetUserName': targetUser.name,
        'targetUserAge': targetUser.age,
        'targetUserImage': targetUser.imagePath,
        'targetUserWorkplace': targetUser.workplace,
        'actionType': actionType, // 'like', 'dislike', 'superlike'
        'createdAt': FieldValue.serverTimestamp(),
      });

      print(
        'Kullanıcı aksiyonu başarıyla kaydedildi: $actionType - ${targetUser.name}',
      );

      // Eğer aksiyon bir like ise, diğer kullanıcının da bu kullanıcıyı like'lamış olup olmadığını kontrol et
      if (actionType == 'like' || actionType == 'superlike') {
        await _checkForMatch(targetUser.userId!);
      }
    } catch (e) {
      print('Kullanıcı aksiyonu kaydedilirken hata oluştu: $e');
    }
  }

  // Eşleşme kontrolü yapmak için yeni metod
  Future<void> _checkForMatch(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Hedef kullanıcının da mevcut kullanıcıyı beğenip beğenmediğini kontrol et
      final query =
          await _firestore
              .collection('userActions')
              .where('userId', isEqualTo: targetUserId)
              .where('targetUserId', isEqualTo: currentUser.uid)
              .where('actionType', whereIn: ['like', 'superlike'])
              .get();

      if (query.docs.isNotEmpty) {
        // Eşleşme oluştu!
        await _createMatch(currentUser.uid, targetUserId);

        if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır

        // Eşleşme bildirimini göster
        showDialog(
          context: context,
          builder:
              (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade300, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 80),
                      SizedBox(height: 20),
                      Text(
                        "Yeni bir eşleşme buldun!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Şimdi mesajlaşmaya başlayabilirsin.",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            child: Text("Kapat"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MessagePage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            child: Text("Mesaj Gönder"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        );
      }
    } catch (e) {
      print('Eşleşme kontrolü yapılırken hata oluştu: $e');
    }
  }

  // Eşleşmeleri Firestore'a kaydet
  Future<void> _createMatch(String userId1, String userId2) async {
    try {
      // Match koleksiyonuna yeni bir eşleşme ekle
      await _firestore.collection('matches').add({
        'user1Id': userId1,
        'user2Id': userId2,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });

      print('Yeni eşleşme oluşturuldu: $userId1 - $userId2');
    } catch (e) {
      print('Eşleşme oluşturulurken hata: $e');
    }
  }

  // Temizleme onay diyaloğunu göster
  void _showClearConfirmationDialog(String actionType) {
    String title = "";
    String message = "";

    switch (actionType) {
      case 'like':
        title = "Beğenilenleri Temizle";
        message =
            "Beğendiğiniz tüm kullanıcılar listeden kaldırılacak. Bu işlem geri alınamaz.";
        break;
      case 'superlike':
        title = "Super Like'ları Temizle";
        message =
            "Super Like attığınız tüm kullanıcılar listeden kaldırılacak. Bu işlem geri alınamaz.";
        break;
      case 'dislike':
        title = "Beğenilmeyenleri Temizle";
        message =
            "Beğenmediğiniz tüm kullanıcılar listeden kaldırılacak. Bu işlem geri alınamaz.";
        break;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("İptal"),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearUserActions(actionType);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text("Temizle"),
              ),
            ],
          ),
    );
  }

  // Kullanıcı aksiyonlarını temizle
  Future<void> _clearUserActions(String actionType) async {
    try {
      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
      setState(() {
        isLoading = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
        setState(() {
          errorMessage = 'Giriş yapmış kullanıcı bulunamadı';
          isLoading = false;
        });
        return;
      }

      // Kullanıcının seçilen tipte tüm aksiyonlarını bul
      final actionSnapshot =
          await _firestore
              .collection('userActions')
              .where('userId', isEqualTo: currentUser.uid)
              .where('actionType', isEqualTo: actionType)
              .get();

      // Her bir dökümanı sil
      final batch = _firestore.batch();
      for (var doc in actionSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Batch işlemini gerçekleştir
      await batch.commit();

      // Verileri yeniden yükle
      await _loadUserActions();

      // Widget ağaçta değilse işlemleri sonlandır
      if (!mounted) return;

      // Başarı mesajı göster
      String message = "";
      switch (actionType) {
        case 'like':
          message = "Beğendiğiniz kullanıcılar temizlendi";
          break;
        case 'superlike':
          message = "Super Like attığınız kullanıcılar temizlendi";
          break;
        case 'dislike':
          message = "Beğenmediğiniz kullanıcılar temizlendi";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
      setState(() {
        errorMessage = 'Temizleme işlemi sırasında hata oluştu: $e';
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Temizleme işlemi sırasında hata oluştu'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      print(errorMessage);
    }
  }

  // Tüm eşleşme geçmişini temizleme diyaloğu
  void _showClearAllConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Tüm Eşleşme Geçmişini Temizle"),
            content: Text(
              "Tüm eşleşme geçmişiniz (beğeniler, beğenmeyenler ve super like'lar) silinecek. Bu işlem geri alınamaz.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("İptal"),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearAllUserActions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text("Tümünü Temizle"),
              ),
            ],
          ),
    );
  }

  // Tüm kullanıcı aksiyonlarını temizle
  Future<void> _clearAllUserActions() async {
    try {
      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
      setState(() {
        isLoading = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
        setState(() {
          errorMessage = 'Giriş yapmış kullanıcı bulunamadı';
          isLoading = false;
        });
        return;
      }

      // Kullanıcının tüm aksiyonlarını bul
      final actionSnapshot =
          await _firestore
              .collection('userActions')
              .where('userId', isEqualTo: currentUser.uid)
              .get();

      // Her bir dökümanı sil
      final batch = _firestore.batch();
      for (var doc in actionSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Batch işlemini gerçekleştir
      await batch.commit();

      // Verileri yeniden yükle
      await _loadUserActions();
      await _loadRecommendedMatches();

      // Widget ağaçta değilse işlemleri sonlandır
      if (!mounted) return;

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tüm eşleşme geçmişiniz temizlendi"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlemi sonlandır
      setState(() {
        errorMessage = 'Temizleme işlemi sırasında hata oluştu: $e';
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Temizleme işlemi sırasında hata oluştu'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      print(errorMessage);
    }
  }

  // Eşleşmelerim için widget
  Widget buildMyMatches() {
    if (myMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_outlined, color: Colors.grey, size: 80),
            SizedBox(height: 20),
            Text(
              "Henüz eşleşme bulunamadı!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Daha fazla kişiyi beğendiğinizde ve onlar da sizi beğendiğinde eşleşmeler burada görünecek.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadMyMatches,
              icon: Icon(Icons.refresh),
              label: Text("Yenile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${myMatches.length} eşleşme",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: _loadMyMatches,
                icon: Icon(Icons.refresh, color: Colors.red, size: 18),
                label: Text("Yenile", style: TextStyle(color: Colors.red)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: myMatches.length,
            itemBuilder: (context, index) {
              final match = myMatches[index];
              final lastMessageDate =
                  match['lastMessageTime'] != null
                      ? (match['lastMessageTime'] as Timestamp).toDate()
                      : null;
              final formattedDate =
                  lastMessageDate != null
                      ? "${lastMessageDate.day}/${lastMessageDate.month}/${lastMessageDate.year}"
                      : "Yeni eşleşme";

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    // Mesaj sayfasına git (gelecekte mesajlaşma için buraya fonksiyon eklenecek)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ChatDetailPage(
                              matchId: match['matchId'],
                              userId: match['userId'],
                              userName:
                                  "${match['name'] ?? 'İsimsiz'}, ${match['age'] ?? '?'}",
                              userImage: match['image'],
                            ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Profil resmi
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              match['image'] != null
                                  ? NetworkImage(
                                    _getValidImageUrl(match['image']),
                                  )
                                  : null,
                          child:
                              match['image'] == null
                                  ? Icon(Icons.person, color: Colors.grey)
                                  : null,
                        ),
                        SizedBox(width: 12),
                        // Kullanıcı bilgileri
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${match['name'] ?? 'İsimsiz'}, ${match['age'] ?? '?'}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              if (match['workplace'] != null)
                                Text(
                                  match['workplace'],
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              SizedBox(height: 6),
                              Text(
                                match['lastMessage'] != null &&
                                        match['lastMessage'].isNotEmpty
                                    ? match['lastMessage']
                                    : "Henüz mesaj yok",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                  fontStyle:
                                      match['lastMessage'] != null &&
                                              match['lastMessage'].isNotEmpty
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        // Mesaja git ikonu
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
