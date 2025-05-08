import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:ucanble_tinder/profile_detail.dart';
import '../services/firebase_service.dart';

class ChatDetailPage extends StatefulWidget {
  final String matchId;
  final String userId;
  final String userName;
  final String? userImage;

  const ChatDetailPage({
    Key? key,
    required this.matchId,
    required this.userId,
    required this.userName,
    this.userImage,
  }) : super(key: key);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Mesajları yükle
  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Mesajları Firestore'dan çek
      final snapshot =
          await _firestore
              .collection('matches')
              .doc(widget.matchId)
              .collection('messages')
              .orderBy('timestamp', descending: false)
              .get();

      final messages =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'senderId': data['senderId'],
              'text': data['text'],
              'timestamp': data['timestamp'],
              'read': data['read'] ?? false,
            };
          }).toList();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Mesajlar yüklendiğinde otomatik olarak en alta kaydır
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Karşı tarafın mesajlarını okundu olarak işaretle
      _markMessagesAsRead();
    } catch (e) {
      print('Mesajlar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Karşı tarafın mesajlarını okundu olarak işaretle
  Future<void> _markMessagesAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Karşı tarafın gönderdiği ve okunmamış mesajları bul
      final batch = _firestore.batch();
      bool hasUnreadMessages = false;

      for (var message in _messages) {
        if (message['senderId'] != currentUser.uid &&
            message['read'] == false) {
          hasUnreadMessages = true;
          // Mesajı okundu olarak işaretle
          final docRef = _firestore
              .collection('matches')
              .doc(widget.matchId)
              .collection('messages')
              .doc(message['id']);

          batch.update(docRef, {'read': true});
        }
      }

      if (hasUnreadMessages) {
        // Toplu güncelleme yap
        await batch.commit();
      }
    } catch (e) {
      print('Mesajlar okundu olarak işaretlenirken hata: $e');
    }
  }

  // Mesaj gönder
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Mesajı temizle
      _messageController.clear();

      // Mesajı Firestore'a ekle
      final message = {
        'senderId': currentUser.uid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Mesajlar koleksiyonuna ekle
      await _firestore
          .collection('matches')
          .doc(widget.matchId)
          .collection('messages')
          .add(message);

      // Eşleşme belgesini güncelle
      await _firestore.collection('matches').doc(widget.matchId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'hasUnreadMessages': true,
      });

      // Mesajları tekrar yükle
      _loadMessages();
    } catch (e) {
      print('Mesaj gönderilirken hata: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mesaj gönderilemedi')));
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

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            // Kullanıcı profiline git
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileDetail(userId: widget.userId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(
                  _getValidImageUrl(widget.userImage),
                ),
                radius: 20,
              ),
              SizedBox(width: 10),
              Text(widget.userName),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              // Profil detaylarını göster
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileDetail(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mesaj listesi
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Henüz mesaj yok',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'İlk mesajı sen gönder!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = currentUser?.uid == message['senderId'];
                        final timestamp = message['timestamp'] as Timestamp?;
                        final time =
                            timestamp != null
                                ? '${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                : '';

                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: 16,
                              left: isMe ? 64 : 0,
                              right: isMe ? 0 : 64,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isMe
                                      ? Colors.red.shade500
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['text'],
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color:
                                            isMe
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      SizedBox(width: 4),
                                      Icon(
                                        message['read']
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 12,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Mesaj yazma alanı
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
