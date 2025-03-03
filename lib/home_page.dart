import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
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
            IconButton(onPressed: () {}, icon: Icon(Ikon.list)),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Center(
            child: SizedBox(
              child: Swiper(
                controller: _swiperController,
                itemCount: users.length, // users.list direkt kullanıyoruz
                layout: SwiperLayout.TINDER,
                itemWidth: 350,
                itemHeight: 600,
                scale: 0.9,
                fade: 0.3,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(users[index].imagePath),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(40), // Yumuşak köşeler
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          spreadRadius: 1, // Hafif gölge
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black], // Opaklığı azalt
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.7, 1], // Alt kısımda solma
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Spacer(),
                          buildName(users[index]),
                          const SizedBox(height: 8),
                          buildStatus(),
                        ],
                      ),
                    ),
                  );
                },
                onIndexChanged: (index) {
                  print("Şu an gösterilen kart: $index");
                },
                onTap: (index) {
                  print("Kart $index tıklandı.");
                },
              ),
            ),
          ),
          Container(
            width:   50,
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
                    _swiperController.previous(); // Sola kaydır
                    print("Kart sola kaydırıldı ❌");
                  },
                  icon: Icon(Icons.close, size: 50, color: Colors.red),
                ),
                IconButton(
                  onPressed: () {
                    // Kartı sağa kaydırma işlemi
                    _swiperController.next(); // Sağa kaydır
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
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.black, width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.home, size: 35, color: Colors.white),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.search, size: 35, color: Colors.white),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.person, size: 35, color: Colors.white),
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
