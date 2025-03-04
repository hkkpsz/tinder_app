import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:ucanble_tinder/profile_detail.dart';
import 'package:ucanble_tinder/search_page.dart';
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
            IconButton(onPressed: () { Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SelectionPage()));}, icon: Icon(Ikon.list)),
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
              child: Swiper(
                controller: _swiperController,
                itemCount: users.length,  // Kullanıcıların listesi
                layout: SwiperLayout.TINDER,  // TINDER düzeniyle daha doğal bir kaydırma animasyonu
                itemWidth: 350,  // Kartın genişliği
                itemHeight: 600,  // Kartın yüksekliği
                scale: 0.9,  // Kartların biraz daha küçük olmasını sağlıyoruz
                fade: 0.3,  // Kartların yavaşça solmasını sağlıyoruz
                onIndexChanged: (index) {
                  print("Şu an gösterilen kart: $index");
                },
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(users[index].imagePath),  // Kullanıcı fotoğrafı
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(40),  // Yumuşak köşeler
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          spreadRadius: 1,  // Hafif gölge
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black],  // Alt kısmı daha karanlık yapıyoruz
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.7, 1],  // Alt kısımda solma efekti
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Spacer(),
                          buildName(users[index]),  // Kullanıcı adı ve yaşını gösteren widget
                          const SizedBox(height: 8),
                          buildStatus(),  // Çevrimiçi durumunu gösteren widget
                        ],
                      ),
                    ),
                  );
                },
              )

            ),
          ),
          Container(
            width:   300,
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
                    _swiperController.next(); // Sola kaydır
                    print("Kart sola kaydırıldı ❌");
                  },
                  icon: Icon(Icons.close, size: 50, color: Colors.red),
                ),
                IconButton(
                  onPressed: () {
                    // Kartı sağa kaydırma işlemi
                    _swiperController.previous(); // Sağa kaydır
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
          border: Border(top: BorderSide(color: Colors.black, width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.home, size: 40, color: Colors.black),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SearchPage()));
              },
              icon: Icon(Icons.search, size: 40, color: Colors.black),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const ProfileDetail()));
              },
              icon: Icon(Icons.person, size: 40, color: Colors.black),
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
