import 'package:flutter/material.dart';
import 'package:ucanble_tinder/profile_detail.dart';
import '../ikon_icons.dart';
import '../users.dart';
import 'home_page.dart';
import 'match_page.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  late List<ChatPreview> _chatPreviews;

  @override
  void initState() {
    super.initState();
    _initChatPreviews();
  }

  void _initChatPreviews() {
    // Users listesinden ChatPreview oluşturuyoruz
    _chatPreviews = [];

    final messages = [
      "Merhaba, nasılsın?",
      "Bugün buluşalım mı?",
      "Harika bir gündü, teşekkürler!",
      "Peki yarın nasıl?",
      "Fotoğraflar için teşekkürler!",
      "Selam, tanışabilir miyiz?",
      "İyi akşamlar!",
      "Film önerilerini bekliyorum!",
      "Konser harika olacak!",
    ];

    final times = [
      "12:30",
      "Dün",
      "Dün",
      "Sal",
      "Pzt",
      "Çrş",
      "Per",
      "Cum",
      "Paz",
    ];

    final random = DateTime.now().microsecond % 10;

    // Kullanıcı sayısı kadar sohbet oluşturuyoruz (maksimum 9 kullanıcı olacak şekilde)
    for (int i = 0; i < users.length && i < 9; i++) {
      _chatPreviews.add(
        ChatPreview(
          name: users[i].name,
          lastMessage: messages[i % messages.length],
          time: times[i % times.length],
          imageUrl: users[i].imagePath,
          unreadCount: (i == 0 || i == random % users.length) ? (i % 3) + 1 : 0,
        ),
      );
    }
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
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
              ),
              child: Icon(Icons.search, color: Colors.grey[800], size: 22),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "Yeni Eşleşmeler",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              height: 100,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: users.length > 6 ? 6 : users.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                            image: DecorationImage(
                              image: AssetImage(users[index].imagePath),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                print("Resim yüklenemedi");
                                return;
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(users[index].name, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "Mesajlar",
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
                  return buildChatPreviewItem(_chatPreviews[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
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
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage(chat.imageUrl),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) => print("Resim yüklenemedi"),
            ),
          ),
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
          // Chat detayına gidecek
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileDetail(user: null),
                ),
              );
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

class ChatPreview {
  final String name;
  final String lastMessage;
  final String time;
  final String imageUrl;
  final int unreadCount;

  ChatPreview({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
    required this.unreadCount,
  });
}
