import 'package:flutter/material.dart';
import 'package:ucanble_tinder/profile_detail.dart';
import 'ikon_icons.dart';
import 'home_page.dart';
import 'match_page.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Message Page"
        ),
      ),
      body: Center(),
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
                IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    },
                    icon: Icon(Ikon.star_half_alt, size: 40, color: Colors.black),
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(100)
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MessagePage(),
                        ),
                      );
                    },
                    icon: Icon(Icons.message, size: 40, color: Colors.black),
                  ),
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
}
