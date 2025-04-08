import 'package:flutter/material.dart';

import '../ikon_icons.dart';
import '../profile_detail.dart';
import 'home_page.dart';
import 'match_page.dart';
import 'message_page.dart';

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  State<SelectionPage> createState() => _selectionPageState();
}

class _selectionPageState extends State<SelectionPage> {
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
              // Tüm filtreleri resetle
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
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  ..._filterOptions
                      .map((filter) => buildFilterSection(filter))
                      .toList(),
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: MaterialButton(
        onPressed: () {
          Navigator.pop(context);
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
