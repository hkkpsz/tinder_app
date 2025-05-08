import 'package:flutter/material.dart';
import '../users.dart';
import '../ikon_icons.dart';
import '../profile_detail.dart';
import 'home_page.dart';
import 'match_page.dart';
import 'message_page.dart';
import '../repositories/user_repository.dart';

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  State<SelectionPage> createState() => _selectionPageState();
}

class _selectionPageState extends State<SelectionPage> {
  List<User> filteredUsers = [];
  bool isLoading = true;
  String errorMessage = '';
  final UserRepository _userRepository = UserRepository();

  final List<Map<String, dynamic>> _filterOptions = [
    {
      "title": "Yaş",
      "selected": "18-30",
      "options": ["18-24", "18-30", "24-35", "30-45", "45+"],
    },
    {
      "title": "Mesafe",
      "selected": "10 km",
      "options": ["5 km", "10 km", "25 km", "50 km", "100+ km"],
    },
    {
      "title": "Cinsiyet",
      "selected": "Kadın",
      "options": ["Hepsi", "Kadın", "Erkek"],
    },
    {
      "title": "İlgi Alanları",
      "selected": "Tümü",
      "options": [
        "Tümü",
        "Spor",
        "Müzik",
        "Sanat",
        "Seyahat",
        "Yemek",
        "Kitap",
      ],
    },
  ];

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

  // Resim widget'ı oluşturan yardımcı metod
  Widget _buildUserImage(String? imageUrl) {
    final url = _getValidImageUrl(imageUrl);

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
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
        print("Resim yüklenirken hata: $error");
        return Container(
          color: Colors.grey.shade300,
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final users = await _userRepository.getAllUsers();
      setState(() {
        filteredUsers = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Kullanıcılar yüklenirken hata oluştu: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  // Seçilen filtrelere göre kullanıcıları filtrele
  void _applyFilters() {
    // Şimdilik basit bir filtreleme - yaş aralığına göre
    final ageFilter = _filterOptions[0]["selected"] as String;
    int minAge = 18;
    int maxAge = 100;

    switch (ageFilter) {
      case "18-24":
        minAge = 18;
        maxAge = 24;
        break;
      case "18-30":
        minAge = 18;
        maxAge = 30;
        break;
      case "24-35":
        minAge = 24;
        maxAge = 35;
        break;
      case "30-45":
        minAge = 30;
        maxAge = 45;
        break;
      case "45+":
        minAge = 45;
        maxAge = 100;
        break;
    }

    // Yaş filtresini uygula
    _loadUsers().then((_) {
      setState(() {
        filteredUsers =
            filteredUsers
                .where(
                  (user) =>
                      user.age != null &&
                      user.age! >= minAge &&
                      user.age! <= maxAge,
                )
                .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Filtreler"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Tüm filtreleri resetle ve kullanıcıları yeniden yükle
              setState(() {
                _filterOptions[0]["selected"] = "18-30";
                _filterOptions[1]["selected"] = "10 km";
                _filterOptions[2]["selected"] = "Kadın";
                _filterOptions[3]["selected"] = "Tümü";
              });
              _loadUsers();
            },
            child: Text("Sıfırla", style: TextStyle(color: Colors.red)),
          ),
        ],
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
          children: [
            Expanded(
              child:
                  isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      )
                      : errorMessage.isNotEmpty
                      ? Center(
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
                      )
                      : ListView(
                        padding: EdgeInsets.all(16),
                        children: [
                          ..._filterOptions
                              .map((filter) => buildFilterSection(filter))
                              .toList(),
                          SizedBox(height: 16),
                          buildFilteredUsersSection(),
                          SizedBox(height: 16),
                          buildPremiumCard(),
                        ],
                      ),
            ),
            buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget buildFilterSection(Map<String, dynamic> filter) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  filter["title"],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  filter["selected"],
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...(filter["options"] as List<String>).map((option) {
                  bool isSelected = option == filter["selected"];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        filter["selected"] = option;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFilteredUsersSection() {
    if (filteredUsers.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.person_off, color: Colors.grey, size: 50),
              SizedBox(height: 16),
              Text(
                "Bu kriterlere uygun kullanıcı bulunamadı",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Bulunan Kullanıcılar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "${filteredUsers.length} kişi",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileDetail(userIndex: index),
                      ),
                    );
                  },
                  child: Container(
                    width: 100,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                            child: _buildUserImage(user.imagePath),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                user.name ?? 'İsimsiz',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.age != null ? '${user.age} yaş' : '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPremiumCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.redAccent.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Ikon.star_half_alt, color: Colors.white, size: 26),
              ),
              SizedBox(width: 12),
              Text(
                "Tinder Premium",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "Premium üyeler daha fazla filtre seçeneğine erişebilir ve sınırsız beğeni yapabilir.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          MaterialButton(
            onPressed: () {},
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(vertical: 12),
            minWidth: double.infinity,
            child: Text(
              "YÜKSELT",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: MaterialButton(
        onPressed: () {
          _applyFilters();
        },
        color: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: EdgeInsets.symmetric(vertical: 14),
        minWidth: double.infinity,
        child: Text(
          "FİLTRELERİ UYGULA",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
