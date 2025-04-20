import 'package:flutter/material.dart';
import 'ikon_icons.dart';
import 'pages/home_page.dart';
import 'pages/match_page.dart';
import 'pages/message_page.dart';
import 'users.dart';

class ProfileDetail extends StatefulWidget {
  final int userIndex;

  const ProfileDetail({super.key, this.userIndex = 0});

  @override
  State<ProfileDetail> createState() => _ProfileDetailState();
}

class _ProfileDetailState extends State<ProfileDetail> {
  late User currentUser;

  @override
  void initState() {
    super.initState();
    // Eğer özel bir kullanıcı indeksi belirtilmişse kullan, aksi halde "Hakkı" adlı kullanıcıyı bul
    if (widget.userIndex != 0) {
      int safeIndex = widget.userIndex;
      if (safeIndex < 0 || safeIndex >= users.length) {
        safeIndex = 0;
      }
      currentUser = users[safeIndex];
    } else {
      // "Hakkı" adlı kullanıcıyı bul
      int hakkiIndex = users.indexWhere((user) => user.name == "Hakkı");
      // Eğer "Hakkı" bulunamazsa ilk kullanıcıyı göster
      currentUser = hakkiIndex != -1 ? users[hakkiIndex] : users[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildUserInfo(),
                    SizedBox(height: 24),
                    buildAboutSection(),
                    SizedBox(height: 24),
                    buildInterestsSection(),
                    SizedBox(height: 24),
                    buildPhotosSection(),
                    SizedBox(height: 24),
                    buildSettingsSection(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  Widget buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner görüntüsü (kullanıcı resmini banner olarak kullanıyoruz)
            Image.asset(
              currentUser.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red.shade300, Colors.redAccent.shade700],
                    ),
                  ),
                );
              },
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                  stops: [0.7, 1.0],
                ),
              ),
            ),
            // Profil fotoğrafı
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  image: DecorationImage(
                    image: AssetImage(currentUser.imagePath),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      print("Profil resmi yüklenemedi");
                    },
                  ),
                ),
              ),
            ),
            // Düzenleme butonu
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: Colors.black87, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${currentUser.name}, ${currentUser.age}",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        "İstanbul",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Profili Düzenle",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildAboutSection() {
    return buildSectionCard(
      title: "Hakkımda",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            "Merhaba! Ben bir yazılım geliştiricisiyim ve bilgisayara bayılırım. Yeni insanlarla tanışmayı ve farklı kültürleri keşfetmeyi seviyorum.",
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget buildInterestsSection() {
    return buildSectionCard(
      title: "İlgi Alanlarım",
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          buildInterestChip("Müzik"),
          buildInterestChip("Spor"),
          buildInterestChip("Seyahat"),
          buildInterestChip("Fotoğrafçılık"),
          buildInterestChip("Arkadaşlarla Sosyalleşmek"),
          buildInterestChip("Doğa Yürüyüşü"),
          buildInterestChip("Sinema"),
          buildInterestChip("Yoga"),
        ],
      ),
    );
  }

  Widget buildInterestChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.red.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget buildPhotosSection() {
    return buildSectionCard(
      title: "Fotoğraflarım",
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              "assets/image${index + 1}.jpg",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildSettingsSection() {
    return buildSectionCard(
      title: "Ayarlar",
      child: Column(
        children: [
          buildSettingItem(
            icon: Icons.notifications,
            title: "Bildirimler",
            subtitle: "Bildirimleri yönetin",
            onTap: () {},
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.privacy_tip,
            title: "Gizlilik",
            subtitle: "Gizlilik ayarlarını düzenleyin",
            onTap: () {},
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.security,
            title: "Güvenlik",
            subtitle: "Hesap güvenliği ayarları",
            onTap: () {},
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.help,
            title: "Yardım ve Destek",
            subtitle: "SSS ve iletişim",
            onTap: () {},
          ),
          Divider(),
          buildSettingItem(
            icon: Icons.logout,
            title: "Çıkış Yap",
            subtitle: "Hesabınızdan güvenli çıkış yapın",
            onTap: () {},
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isDestructive
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDestructive ? Colors.red : Colors.grey[800],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            child,
          ],
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
            isActive: true,
            onTap: () {
              // zaten profil sayfasındayız
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
