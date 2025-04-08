import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:scrumlab_flutter_tindercard/scrumlab_flutter_tindercard.dart';
import 'package:ucanble_tinder/pages/match_page.dart';
import 'package:ucanble_tinder/pages/message_page.dart';
import 'package:ucanble_tinder/profile_detail.dart';
import 'package:ucanble_tinder/pages/selection_page.dart';
import '../users.dart';
import 'package:ucanble_tinder/ikon_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
              "Tinder",
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
              Expanded(
                child: TinderSwapCard(
                  swipeUp: true,
                  swipeDown: true,
                  orientation: AmassOrientation.bottom,
                  totalNum: users.length,
                  stackNum: 3,
                  swipeEdge: 4.0,
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  minWidth: MediaQuery.of(context).size.width * 0.8,
                  minHeight: MediaQuery.of(context).size.height * 0.65,
                  cardController: _cardController,
                  cardBuilder: (context, index) => buildCard(context, index),
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
                    } else if (orientation == CardSwipeOrientation.left) {
                      print("Kart sola kaydırıldı ❌");
                    } else if (orientation == CardSwipeOrientation.up) {
                      print("Kart yukarı kaydırıldı ⭐ Super Like!");
                      _showSuperLikeDialog(index);
                    }
                  },
                ),
              ),
              SizedBox(height: 20),
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
    // Super Like göstergesinin görünürlüğü
    final showSuperLike = _currentAlignment.y < -0.5;

    // Parmakla hareket etmesi için transform değerleri hesapla
    final yTranslate = _currentAlignment.y * 50.0; // Yukarı-aşağı hareket
    final yRotate = _currentAlignment.x * 0.2; // X ekseninde dönüş
    final xRotate = _currentAlignment.y * 0.2; // Y ekseninde dönüş
    final scale =
        0.9 + (0.1 * (1 - _currentAlignment.y.abs())); // Ölçeklendirme

    return Transform(
      transform:
          Matrix4.identity()
            ..translate(0.0, yTranslate)
            ..rotateX(xRotate)
            ..rotateY(yRotate)
            ..scale(scale),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          // Karta tıklandığında profil detayına gitsin
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileDetail(user: users[index]),
            ),
          );
        },
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Ana resim
                Positioned.fill(
                  child: Image.asset(
                    users[index].imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print("Resim yüklenirken hata: $error");
                      return Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 100,
                          color: Colors.grey,
                        ),
                      );
                    },
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
                    child: Transform.rotate(
                      angle: yRotate, // Karla birlikte hafif dönme efekti
                      child: Container(
                        margin: EdgeInsets.only(top: 40),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          "SUPER LIKE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
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
                        buildName(users[index]),
                        SizedBox(height: 8),
                        buildStatus(),
                        SizedBox(height: 12),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
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
      ),
    );
  }

  Widget buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          onTap: () {
            _cardController.triggerLeft();
            print("Kart sola kaydırıldı ❌");
          },
          color: Colors.white,
          icon: Icons.close,
          iconColor: Colors.red,
          size: 60,
        ),
        SizedBox(width: 20),
        _buildActionButton(
          onTap: () {
            _cardController.triggerUp();
            print("Kart yukarı kaydırıldı ⭐");
          },
          color: Colors.blue,
          icon: Icons.star,
          iconColor: Colors.white,
          size: 50,
        ),
        SizedBox(width: 20),
        _buildActionButton(
          onTap: () {
            _cardController.triggerRight();
            print("Kart sağa kaydırıldı ❤️");
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
                    "${users[index].name} kullanıcısına Super Like gönderdiniz!",
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
}
