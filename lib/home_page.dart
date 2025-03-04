import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:scrumlab_flutter_tindercard/scrumlab_flutter_tindercard.dart';
import 'package:ucanble_tinder/match_page.dart';
import 'package:ucanble_tinder/message_page.dart';
import 'package:ucanble_tinder/profile_detail.dart';
import 'package:ucanble_tinder/selection_page.dart';
import 'users.dart';
import 'package:ucanble_tinder/ikon_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SwiperController _swiperController = SwiperController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Ikon.think_peaks, color: Colors.red, size: 35),
            Text("Tinder", style: TextStyle(fontSize: 30)),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectionPage(),
                  ),
                );
              },
              icon: Icon(Ikon.list),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Center(
            child: SizedBox(
              height: 600,
              width: 350,
              child: TinderSwapCard(
                swipeUp: true,
                swipeDown: true,
                orientation: AmassOrientation.bottom,
                totalNum: users.length,
                stackNum: 2,
                swipeEdge: 4.0,
                maxHeight:
                MediaQuery.of(context).size.height *
                    0.8, // Ekran boyutuna göre dinamik
                maxWidth:
                MediaQuery.of(context).size.width *
                    0.8, // Ekran boyutuna göre dinamik
                minWidth:
                MediaQuery.of(context).size.width *
                    0.7, // Ekran boyutuna göre dinamik
                minHeight:
                MediaQuery.of(context).size.height *
                    0.7, // Ekran boyutuna göre dinamik
                cardBuilder:
                    (context, index) => Card(
                  child: Image.asset(
                    users[index].imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
                swipeUpdateCallback: (
                    DragUpdateDetails details,
                    Alignment align,
                    ) {
                  if (align.x < 0) {
                    print("Kart sola kaydırılıyor ❌");
                  } else if (align.x > 0) {
                    print("Kart sağa kaydırılıyor ❤️");
                  }
                },
                swipeCompleteCallback: (
                    CardSwipeOrientation orientation,
                    int index,
                    ) {
                  if (orientation == CardSwipeOrientation.right) {
                    print("Kart sağa kaydırıldı ❤️");
                  } else if (orientation == CardSwipeOrientation.left) {
                    print("Kart sola kaydırıldı ❌");
                  }
                },
              ),
            ),
          ),
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(width: 3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {
                    // Kartı sola kaydırma işlemi
                    _swiperController.previous(); // Kartı sola kaydır
                    print("Kart sola kaydırıldı ❌");
                  },
                  icon: Icon(Icons.close, size: 50, color: Colors.red),
                ),
                IconButton(
                  onPressed: () {
                    // Kartı sağa kaydırma işlemi
                    _swiperController.next(); // Kartı sağa kaydır
                    print("Kart sağa kaydırıldı ❤️");
                  },
                  icon: Icon(Ikon.heart, size: 50, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(top: BorderSide(color: Colors.orangeAccent, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.orangeAccent
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    },
                    icon: Icon(Ikon.star_half_alt, size: 40, color: Colors.black),
                  ),
                ),
                Text("Keşfet")
              ],
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MatchPage()),
                    );
                  },
                  icon: Icon(Icons.people_rounded, size: 40, color: Colors.black),
                ),
                Text("Eşleş")
              ],
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessagePage(),
                      ),
                    );
                  },
                  icon: Icon(Icons.message, size: 40, color: Colors.black),
                ),
                Text("Sohbet")
              ],
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileDetail(),
                      ),
                    );
                  },
                  icon: Icon(Icons.person, size: 40, color: Colors.black),
                ),
                Text("Profil")
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildName(User user) => Row(
    children: [
      Text(
        user.name ?? 'Bilgi Yok', // Eğer name null ise 'Bilgi Yok' yazsın
        style: TextStyle(
          fontSize: 32,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(width: 16),
      // 'user.age' null olursa 0 gösterilsin
      Text(
        user.age != null ? '${user.age}' : '0', // null kontrolü ekleniyor
        style: TextStyle(fontSize: 32, color: Colors.white),
      ),
    ],
  );

  Widget buildStatus() => Row(
    children: [
      Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green),
        width: 12,
        height: 12,
      ),
      SizedBox(width: 12),
      Text("Çevrimiçi", style: TextStyle(fontSize: 20, color: Colors.white)),
    ],
  );
}
