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
            Icon(Icons.hotel_class, color: Colors.red, size: 35),
            Text("Tinder", style: TextStyle(fontSize: 30)),
            IconButton(onPressed: () {}, icon: Icon(Ikon.list))
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
                itemCount: users.length, // users listesine göre item count
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(users[index].imagePath), fit: BoxFit.cover),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26, blurRadius: 4, spreadRadius: 5)
                      ],
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
            width: 350,
            decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(width: 3)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {
                    _swiperController.next(); // SAĞA (BEĞEN) KAYDIRMA
                    print("Kart reddedildi ❌");
                  },
                  icon: Icon(Icons.close, size: 50, color: Colors.red),
                ),
                IconButton(
                  onPressed: () {
                    _swiperController.next(); // SOLA (REDDET) KAYDIRMA
                    print("Kart beğenildi ❤️");
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
}
