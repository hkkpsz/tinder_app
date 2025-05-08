import 'package:flutter/material.dart';
import 'package:ucanble_tinder/profile_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../ikon_icons.dart';
import '../users.dart';
import 'home_page.dart';
import 'match_page.dart';
import 'chat_detail_page.dart';
import '../services/firebase_service.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  late List<ChatPreview> _chatPreviews = [];
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _matches = [];

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

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  // Tüm eşleşmelerdeki okunmamış mesajları okundu olarak işaretle
  Future<void> _markAllMessagesAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Okunmamış mesajları olan eşleşmeleri bul
      final matchesQuery1 =
          await _firestore
              .collection('matches')
              .where('user1Id', isEqualTo: currentUser.uid)
              .where('hasUnreadMessages', isEqualTo: true)
              .where('lastMessageSenderId', isNotEqualTo: currentUser.uid)
              .get();

      final matchesQuery2 =
          await _firestore
              .collection('matches')
              .where('user2Id', isEqualTo: currentUser.uid)
              .where('hasUnreadMessages', isEqualTo: true)
              .where('lastMessageSenderId', isNotEqualTo: currentUser.uid)
              .get();

      // Eşleşmeleri birleştir
      final matchDocs = [...matchesQuery1.docs, ...matchesQuery2.docs];

      // Her bir eşleşme için okunmamış mesajları işaretle
      for (var doc in matchDocs) {
        final matchId = doc.id;
        final batch = _firestore.batch();
        bool hasUpdates = false;

        // Okunmamış mesajları bul
        final messagesSnapshot =
            await _firestore
                .collection('matches')
                .doc(matchId)
                .collection('messages')
                .where('senderId', isNotEqualTo: currentUser.uid)
                .where('read', isEqualTo: false)
                .get();

        // Her bir mesajı okundu olarak işaretle
        for (var messageDoc in messagesSnapshot.docs) {
          batch.update(messageDoc.reference, {'read': true});
          hasUpdates = true;
        }

        // Eşleşmeyi güncelle
        if (hasUpdates) {
          batch.update(_firestore.collection('matches').doc(matchId), {
            'hasUnreadMessages': false,
          });

          // Toplu güncelleme
          await batch.commit();
        }
      }

      print("Tüm mesajlar okundu olarak işaretlendi");
    } catch (e) {
      print("Mesajlar okundu olarak işaretlenirken hata: $e");
    }
  }

  // Eşleşmeleri yükle
  Future<void> _loadMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Giriş yapmış kullanıcı bulunamadı';
          _isLoading = false;
        });
        return;
      }

      // Tüm mesajları okundu olarak işaretle
      await _markAllMessagesAsRead();

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

        // Okunmamış mesaj kontrolü
        bool hasUnreadMessages = false;
        int unreadCount = 0;

        // Son mesajı gönderen karşı tarafsa ve okunmamış mesajlar varsa
        if (matchData['lastMessageSenderId'] != null &&
            matchData['lastMessageSenderId'] != currentUser.uid &&
            matchData['hasUnreadMessages'] == true) {
          hasUnreadMessages = true;

          // Okunmamış mesaj sayısını bul
          final messagesSnapshot =
              await _firestore
                  .collection('matches')
                  .doc(matchId)
                  .collection('messages')
                  .where('senderId', isEqualTo: otherUserId)
                  .where('read', isEqualTo: false)
                  .get();

          unreadCount = messagesSnapshot.docs.length;
        }

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
            'hasUnreadMessages': hasUnreadMessages,
            'unreadCount': unreadCount,
          });
        }
      }

      // Tarihe göre sırala (en son mesaj gönderilen en üstte)
      matches.sort((a, b) {
        if (a['lastMessageTime'] == null && b['lastMessageTime'] == null) {
          // İki eşleşmede de mesaj yoksa, oluşturulma tarihine göre sırala
          if (a['createdAt'] == null || b['createdAt'] == null) return 0;
          return (b['createdAt'] as Timestamp).compareTo(
            a['createdAt'] as Timestamp,
          );
        } else if (a['lastMessageTime'] == null) {
          return 1; // a'da mesaj yoksa b önce gelsin
        } else if (b['lastMessageTime'] == null) {
          return -1; // b'de mesaj yoksa a önce gelsin
        }
        // İki eşleşmede de mesaj varsa, son mesaj tarihine göre sırala
        return (b['lastMessageTime'] as Timestamp).compareTo(
          a['lastMessageTime'] as Timestamp,
        );
      });

      setState(() {
        _matches = matches;
        _isLoading = false;
      });

      print("${matches.length} eşleşme yüklendi");

      // Yeni eşleşmeler için ChatPreview oluştur
      _createChatPreviews();
    } catch (e) {
      setState(() {
        _errorMessage = 'Eşleşmeleriniz yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
      print(_errorMessage);
    }
  }

  // Eşleşmelerden ChatPreview nesneleri oluştur
  void _createChatPreviews() {
    List<ChatPreview> previews = [];

    for (var match in _matches) {
      final lastMessageTime = match['lastMessageTime'] as Timestamp?;
      String timeString = "Yeni";

      if (lastMessageTime != null) {
        final now = DateTime.now();
        final messageTime = lastMessageTime.toDate();
        final difference = now.difference(messageTime);

        if (difference.inMinutes < 60) {
          timeString = "${difference.inMinutes}d";
        } else if (difference.inHours < 24) {
          timeString = "${difference.inHours}s";
        } else if (difference.inDays < 7) {
          final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
          timeString = days[messageTime.weekday - 1];
        } else {
          timeString = "${messageTime.day}/${messageTime.month}";
        }
      }

      previews.add(
        ChatPreview(
          matchId: match['matchId'],
          userId: match['userId'],
          name: "${match['name'] ?? 'İsimsiz'}, ${match['age'] ?? '?'}",
          lastMessage: match['lastMessage'] ?? 'Henüz mesaj yok',
          time: timeString,
          imageUrl: _getValidImageUrl(match['image']),
          unreadCount: match['unreadCount'] ?? 0,
        ),
      );
    }

    setState(() {
      _chatPreviews = previews;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
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
              "Mesajlarım",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                letterSpacing: 0.5,
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadMatches,
              color: Colors.grey[800],
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.red))
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700], fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadMatches,
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
                child:
                    _matches.isEmpty
                        ? _buildEmptyState()
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                "Eşleşmelerim",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _chatPreviews.length,
                                itemBuilder: (context, index) {
                                  return buildChatPreviewItem(
                                    _chatPreviews[index],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
              ),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 80),
          SizedBox(height: 20),
          Text(
            "Henüz mesajlaşabileceğin bir eşleşmen yok!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Daha fazla kişiyi beğendiğinde ve onlar da seni beğendiğinde burada eşleşmelerini göreceksin.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            icon: Icon(Icons.favorite),
            label: Text("Keşfetmeye Başla"),
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

  Widget buildChatPreviewItem(ChatPreview chat) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(child: _buildUserImage(chat.imageUrl)),
            ),
            if (chat.unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(
              chat.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Spacer(),
            Text(chat.time, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        chat.unreadCount > 0
                            ? Colors.black87
                            : Colors.grey[600],
                    fontWeight:
                        chat.unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                    fontStyle:
                        chat.lastMessage == 'Henüz mesaj yok'
                            ? FontStyle.italic
                            : FontStyle.normal,
                  ),
                ),
              ),
              if (chat.unreadCount > 0)
                Container(
                  margin: EdgeInsets.only(left: 8),
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat.unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        onTap: () {
          // Chat detayına git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatDetailPage(
                    matchId: chat.matchId,
                    userId: chat.userId,
                    userName: chat.name,
                    userImage: chat.imageUrl,
                  ),
            ),
          ).then((_) {
            // Geri döndüğünde mesajları yenile
            _loadMatches();
          });
        },
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
            isActive: true,
            onTap: () {
              Navigator.pushReplacement(
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

  // Widget to build user image from URL
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
        return Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.person, color: Colors.grey, size: 30),
        );
      },
    );
  }
}

class ChatPreview {
  final String matchId;
  final String userId;
  final String name;
  final String lastMessage;
  final String time;
  final String imageUrl;
  final int unreadCount;

  ChatPreview({
    required this.matchId,
    required this.userId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
    required this.unreadCount,
  });
}
