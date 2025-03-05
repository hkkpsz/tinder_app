import 'package:flutter/material.dart';
import 'package:ucanble_tinder/home_page.dart';
import 'package:ucanble_tinder/sign_up.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode(); // FocusNode for email field
  final FocusNode _passwordFocusNode =
  FocusNode(); // FocusNode for password field

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose(); // Dispose of the FocusNode
    _passwordFocusNode.dispose(); // Dispose of the FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.onSecondary,
      // appBar: AppBar(
      //   backgroundColor: colorScheme.primary,
      //   title: const Text(
      //     "AIchatter",
      //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      //   ),
      //   centerTitle: true,
      //   elevation: 5,
      //   shadowColor: colorScheme.secondary,
      // ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.secondary, // Gölge rengini ayarlayabilirsiniz
                      spreadRadius: 5, // Gölgenin yayılma miktarı
                      blurRadius: 15, // Gölgenin bulanıklık miktarı
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/ucanble.png',
                  width: 300,
                  height: 100,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    blurStyle: BlurStyle.normal,
                    color: colorScheme.secondary,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    blurStyle: BlurStyle.normal,
                    color: colorScheme.secondary,
                    blurRadius: 50,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: TextField(
                focusNode: _emailFocusNode, // Attach FocusNode
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "E-posta",
                  prefixIcon: Icon(Icons.email, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),

            const SizedBox(height: 25),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    blurStyle: BlurStyle.normal,
                    color: colorScheme.secondary,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    blurStyle: BlurStyle.normal,
                    color: colorScheme.secondary,
                    blurRadius: 50,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: TextField(
                focusNode: _passwordFocusNode, // FocusNode eklendi
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Şifre",
                  prefixIcon: Icon(Icons.lock, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 35),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                shadowColor: colorScheme.secondary,
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const HomePage()));
              },
              child: const Text(
                "Giriş Yap",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 15,),
            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SignUp()));
              },
              child: Container(
                child: Text(
                  "Hesabınız Yok mu?\nKayıt Olmak İçin Tıklayınız.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
