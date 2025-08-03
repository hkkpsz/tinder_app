import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:scrumlab_flutter_tindercard/scrumlab_flutter_tindercard.dart';
import 'package:ucanble_tinder/pages/match_page.dart';
import 'package:ucanble_tinder/pages/message_page.dart';
import 'package:ucanble_tinder/pages/chat_detail_page.dart';
import 'package:ucanble_tinder/profile_detail.dart';
import 'package:ucanble_tinder/pages/selection_page.dart';
import 'package:ucanble_tinder/pages/upload_image.dart'; // Profil resmi yükleme sayfası
import '../users.dart';
import 'package:ucanble_tinder/ikon_icons.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ucanble_tinder/repositories/user_repository.dart';
import 'package:ucanble_tinder/services/firebase_service.dart'; // Firebase servisi

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<User> userList = [];
  bool isLoading = true;
  String errorMessage = '';
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository = UserRepository();
  final FirebaseService _firebaseService = FirebaseService();

  // Okunmamış mesaj sayısı
  int _unreadMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  // Kullanıcı oturumu kontrolü
  Future<void> _checkCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          errorMessage = 'Oturum açmış kullanıcı bulunamadı!';
          isLoading = false;
        });
        return;
      }

      print("Kullanıcı oturumu açık: ${currentUser.uid}");

      // Kullanıcının Firestore'da profili var mı kontrol et
      bool userExists = await _firebaseService.checkUserExists(currentUser.uid);

      if (!userExists) {
        print(
          "Kullanıcı Firestore'da bulunamadı, profil tamamlama yönlendirilecek",
        );
        // Kullanıcı profili oluşturulmamış, resim yükleme sayfasına yönlendir
        _showCompleteProfileDialog();
        return;
      }

      // Okunmamış mesaj sayısını kontrol et
      _loadUnreadMessagesCount();

      // Kullanıcı profili varsa, kullanıcıları yükle
      _loadUsers();
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcı oturumu kontrol edilirken hata: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  // Profil tamamlama dialog'u
  void _showCompleteProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text("Profil Oluştur"),
            content: Text(
              "Uygulamayı kullanmak için profilinizi tamamlamanız gerekiyor.",
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Profil resmini yükleme sayfasına yönlendir
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              UploadImagePage(userId: _auth.currentUser!.uid),
                    ),
                  ).then((_) {
                    // Sayfadan dönünce kullanıcıları yükle
                    _loadUsers();
                  });
                },
                child: Text("Profil Oluştur"),
              ),
            ],
          ),
    );
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Mevcut kullanıcıyı al
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          errorMessage = 'Oturum açmış kullanıcı bulunamadı';
          isLoading = false;
        });
        return;
      }

      // Önce kullanıcının daha önce etkileşimde bulunduğu kullanıcı IDlerini al
      final actionSnapshot =
          await _firestore
              .collection('userActions')
              .where('userId', isEqualTo: currentUser.uid)
              .get();

      // Etkileşimde bulunulan kullanıcı IDlerini bir kümeye ekle
      Set<String> interactedUserIds = {};
      for (var doc in actionSnapshot.docs) {
        String? targetUserId = doc.data()['targetUserId'] as String?;
        if (targetUserId != null) {
          interactedUserIds.add(targetUserId);
        }
      }

      print(
        "Daha önce etkileşimde bulunulan kullanıcı sayısı: ${interactedUserIds.length}",
      );

      // Tüm kullanıcıları getir
      final users = await _userRepository.getAllUsers();

      // Mevcut kullanıcıyı ve daha önce etkileşimde bulunulan kullanıcıları filtrele
      List<User> filteredUsers =
          users.where((user) {
            // Kendi profilini gösterme
            if (user.userId == currentUser.uid) return false;

            // Daha önce etkileşimde bulunulan kullanıcıları gösterme
            if (interactedUserIds.contains(user.userId)) return false;

            return true;
          }).toList();

      setState(() {
        userList = filteredUsers;
        isLoading = false;
      });

      print(
        "Toplam kullanıcı sayısı: ${users.length}, Filtrelenmiş kullanıcı sayısı: ${filteredUsers.length}",
      );

      // Kullanıcı listesi boşsa kullanıcıya bilgi ver
      if (filteredUsers.isEmpty) {
        print("Gösterilebilecek yeni kullanıcı bulunamadı.");
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcılar yüklenirken hata oluştu: $e';
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

      setState(() {
        _unreadMessagesCount = count;
      });

      print("Okunmamış mesaj sayısı: $_unreadMessagesCount");
    } catch (e) {
      print("Okunmamış mesaj sayısı yüklenirken hata: $e");
    }
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

      // Eğer aksiyon bir like veya superlike ise, eşleşme kontrolü yap
      if (actionType == 'like' || actionType == 'superlike') {
        await _checkForMatch(targetUser.userId!);
      }
    } catch (e) {
      print('Kullanıcı aksiyonu kaydedilirken hata oluştu: $e');
    }
  }

  // Eşleşme kontrolü
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
        final matchId = await _createMatch(currentUser.uid, targetUserId);

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
                            onPressed: () async {
                              Navigator.of(context).pop();

                              // Eşleşen kullanıcının bilgilerini al
                              Map<String, dynamic>? userData =
                                  await _firebaseService.getUserData(
                                    targetUserId,
                                  );

                              if (userData != null) {
                                // Mesajlaşma sayfasına git
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChatDetailPage(
                                          matchId: matchId,
                                          userId: targetUserId,
                                          userName:
                                              "${userData['name'] ?? 'İsimsiz'}, ${userData['age'] ?? '?'}",
                                          userImage:
                                              userData['images'] != null &&
                                                      userData['images']
                                                          .isNotEmpty
                                                  ? userData['images'][0]
                                                  : null,
                                        ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessagePage(),
                                  ),
                                );
                              }
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
  Future<String> _createMatch(String userId1, String userId2) async {
    try {
      // Match koleksiyonuna yeni bir eşleşme ekle
      final docRef = await _firestore.collection('matches').add({
        'user1Id': userId1,
        'user2Id': userId2,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });

      print('Yeni eşleşme oluşturuldu: $userId1 - $userId2');
      return docRef.id;
    } catch (e) {
      print('Eşleşme oluşturulurken hata: $e');
      return '';
    }
  }

  // Geçerli bir image URL oluşturmak için yardımcı metod
  String _getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      // Boş URL durumunda varsayılan bir Cloudinary URL göster
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

    // Diğer tüm durumlarda varsayılan Cloudinary URL'si kullan
    return 'https://res.cloudinary.com/dkkp7qiwb/image/upload/v1746467909/ucanble_tinder_images/osxku0wkujc3hwiqgj7z.jpg';
  }

  final CardController _cardController = CardController();

  // Kart kaydırma durumunu takip etmek için değişken
  Alignment _currentAlignment = Alignment.center;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Container(
            //   padding: EdgeInsets.all(8),
            //   decoration: BoxDecoration(
            //     shape: BoxShape.circle,
            //     gradient: LinearGradient(
            //       colors: [Colors.red.shade300, Colors.redAccent.shade700],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //   ),
            //   child: Icon(Ikon.think_peaks, color: Colors.white, size: 24),
            // ),
            Text(
              "SnycMe",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectionPage(),
                    ),
                  );
                },
                icon: Icon(Ikon.list, color: Colors.grey[800], size: 22),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: 10),
              isLoading
                  ? Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
                  )
                  : errorMessage.isNotEmpty
                  ? Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadUsers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text("Tekrar Dene"),
                          ),
                        ],
                      ),
                    ),
                  )
                  : userList.isEmpty
                  ? Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            color: Colors.grey,
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Gösterilecek yeni kullanıcı kalmadı",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tüm kullanıcılarla etkileşimde bulundunuz.",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showClearHistoryDialog(),
                            icon: Icon(Icons.refresh),
                            label: Text("Geçmişi Temizle"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : Expanded(
                    child: TinderSwapCard(
                      swipeUp: true,
                      swipeDown: true,
                      orientation: AmassOrientation.bottom,
                      totalNum: userList.length,
                      stackNum: 3,
                      swipeEdge: 4.0,
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      minWidth: MediaQuery.of(context).size.width * 0.8,
                      minHeight: MediaQuery.of(context).size.height * 0.65,
                      cardController: _cardController,
                      cardBuilder:
                          (context, index) => buildCard(context, index),
                      swipeUpdateCallback: (
                        DragUpdateDetails details,
                        Alignment align,
                      ) {
                        setState(() {
                          _currentAlignment = align;
                        });
                        if (align.x < 0) {
                          print("Kart sola kaydırılıyor ❌");
                        } else if (align.x > 0) {
                          print("Kart sağa kaydırılıyor ❤️");
                        } else if (align.y < 0) {
                          print("Kart yukarı kaydırılıyor ⭐");
                        }
                      },
                      swipeCompleteCallback: (
                        CardSwipeOrientation orientation,
                        int index,
                      ) {
                        setState(() {
                          _currentAlignment = Alignment.center;
                        });
                        if (orientation == CardSwipeOrientation.right) {
                          print("Kart sağa kaydırıldı ❤️");
                          _saveUserAction(userList[index], 'like');
                        } else if (orientation == CardSwipeOrientation.left) {
                          print("Kart sola kaydırıldı ❌");
                          _saveUserAction(userList[index], 'dislike');
                        } else if (orientation == CardSwipeOrientation.up) {
                          print("Kart yukarı kaydırıldı ⭐ Super Like!");
                          _saveUserAction(userList[index], 'superlike');
                          _showSuperLikeDialog(index);
                        }
                      },
                    ),
                  ),
              SizedBox(height: 20),
              if (!isLoading && errorMessage.isEmpty && userList.isNotEmpty)
                buildActionButtons(),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  Widget buildCard(BuildContext context, int index) {
    final user = userList[index];
    print(
      "Kart oluşturuluyor - index: $index, kullanıcı: ${user.name}, imagePath: ${user.imagePath}",
    );

    // Super Like göstergesinin görünürlüğü
    final showSuperLike = _currentAlignment.y < -0.5;

    // Super like'a göre kartın transformu/hareketi
    final transform = Matrix4.identity();
    if (_currentAlignment.y < 0) {
      // Yukarı kaydırma - giderek daha küçük göster ve yukarı kaydır
      final scale = 1.0 - (_currentAlignment.y.abs() * 0.15); // Küçülme oranı
      final yTranslate = _currentAlignment.y * 200; // Yukarı hareket miktarı
      transform.translate(0.0, yTranslate);
      transform.scale(scale);
    }

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Ana resim
              Positioned.fill(
                child:
                    user.imagePath != null && user.imagePath!.isNotEmpty
                        ? _buildUserImage(user.imagePath!)
                        : Container(
                          color: Colors.grey.shade300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey.shade500,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Fotoğraf Bulunamadı",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: [0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Super Like İşareti (Yukarı kaydırma durumunda gösterilir)
              if (showSuperLike)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: 40),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "SUPER LIKE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Profil bilgileri
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildName(user),
                      SizedBox(height: 8),
                      buildStatus(),
                      SizedBox(height: 8),
                      if (user.workplace != null && user.workplace!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.work, color: Colors.white70, size: 16),
                            SizedBox(width: 4),
                            Text(
                              user.workplace!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "5 km uzaklıkta",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Resim widget'ı oluşturan yardımcı metod
  Widget _buildUserImage(String imageUrl) {
    final url = _getValidImageUrl(imageUrl);
    print("Resim yükleniyor: $url");

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.red,
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print("Resim yüklenirken hata: $error");
        return Container(
          color: Colors.grey.shade300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 60, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  "Resim Yüklenemedi",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          onTap: () {
            if (userList.isNotEmpty) {
              _saveUserAction(userList[0], 'dislike');
              _cardController.triggerLeft();
              print("Kart sola kaydırıldı ❌");
            }
          },
          color: Colors.white,
          icon: Icons.close,
          iconColor: Colors.red,
          size: 60,
        ),
        SizedBox(width: 20),
        _buildActionButton(
          onTap: () {
            if (userList.isNotEmpty) {
              _saveUserAction(userList[0], 'superlike');
              _cardController.triggerUp();
              print("Kart yukarı kaydırıldı ⭐");
            }
          },
          color: Colors.blue,
          icon: Icons.star,
          iconColor: Colors.white,
          size: 50,
        ),
        SizedBox(width: 20),
        _buildActionButton(
          onTap: () {
            if (userList.isNotEmpty) {
              _saveUserAction(userList[0], 'like');
              _cardController.triggerRight();
              print("Kart sağa kaydırıldı ❤️");
            }
          },
          color: Colors.red,
          icon: Ikon.heart,
          iconColor: Colors.white,
          size: 70,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required Function() onTap,
    required Color color,
    required IconData icon,
    required Color iconColor,
    required double size,
  }) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: size * 0.5),
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
            isActive: true,
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
              } else {
                // Eğer giriş yapmış kullanıcı yoksa, varsayılan profil göster
                int hakkiIndex = userList.indexWhere(
                  (user) => user.name == "Hakkı",
                );
                // Hakkı bulunamazsa rastgele bir profil göster
                final userIndex =
                    hakkiIndex != -1
                        ? hakkiIndex
                        : (userList.isEmpty
                            ? 0
                            : DateTime.now().millisecond % userList.length);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileDetail(userIndex: userIndex),
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? Colors.red.withOpacity(0.1)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 26,
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

  Widget buildName(User user) => Row(
    children: [
      Text(
        user.name ?? 'Bilgi Yok',
        style: TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(width: 8),
      Text(
        user.age != null ? '${user.age}' : '0',
        style: TextStyle(fontSize: 26, color: Colors.white),
      ),
    ],
  );

  Widget buildStatus() => Row(
    children: [
      Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green),
        width: 10,
        height: 10,
      ),
      SizedBox(width: 8),
      Text(
        "Çevrimiçi",
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  // Super Like durumunda gösterilecek diyalog
  void _showSuperLikeDialog(int index) {
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
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade300, Colors.blue.shade700],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 60),
                  SizedBox(height: 16),
                  Text(
                    "Super Like!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "${userList[index].name} kullanıcısına Super Like gönderdiniz!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                    ),
                    child: Text("Tamam"),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Geçmişi Temizle"),
            content: Text(
              "Tüm eşleşme geçmişiniz (beğeniler, beğenmemeler ve super like'lar) silinecek. Böylece tüm kullanıcıları tekrar görüntüleyebilirsiniz. Bu işlem geri alınamaz.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("İptal"),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearHistory();
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

  Future<void> _clearHistory() async {
    try {
      setState(() {
        isLoading = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          errorMessage = 'Oturum açmış kullanıcı bulunamadı';
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

      // Bir batch işlemi başlat
      final batch = _firestore.batch();

      // Her bir dökümanı sil
      for (var doc in actionSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Batch işlemini gerçekleştir
      await batch.commit();

      print(
        'Kullanıcının tüm aksiyonları başarıyla silindi: ${actionSnapshot.docs.length} aksiyon',
      );

      // Kullanıcıları tekrar yükle
      await _loadUsers();

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
      setState(() {
        errorMessage = 'Geçmiş temizlenirken bir hata oluştu: $e';
        isLoading = false;
      });

      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geçmiş temizlenirken bir hata oluştu'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      print(errorMessage);
    }
  }
}
