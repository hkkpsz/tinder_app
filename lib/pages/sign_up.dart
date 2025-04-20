import 'package:flutter/material.dart';
import 'package:ucanble_tinder/pages/home_page.dart';
import 'package:ucanble_tinder/services/database.dart';
import 'package:ucanble_tinder/pages/upload_image.dart';
import 'login_page.dart';
import 'package:ucanble_tinder/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _yasController = TextEditingController();
  final TextEditingController _workplaceController = TextEditingController();
  String? _passwordError;
  bool _isLoading = false;

  @override
  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    _validatePasswords();
    if (_passwordError != null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    AuthService authService = AuthService();
    var user = await authService.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _adController.text.trim(),
      int.parse(_yasController.text.trim()),
      _workplaceController.text.trim(),
    );

    if (user != null) {
      String userId = user.uid;
      // PostgreSQL'e kaydet
      DatabaseService dbService = DatabaseService();
      await dbService.connect();
      await dbService.insertUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _adController.text.trim(),
        int.parse(_yasController.text.trim()),
        _workplaceController.text.trim(),
      );

      // Firestore'a profil durumunu ekle
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profileCompleted': false,
      });

      // Kullanıcı ilerleme durumunu başlat
      await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(userId)
          .set({
            'imageUploaded': false,
            'cvUploaded': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kayıt işlemi başarısız!")));
    }
  }

  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adController.dispose();
    _yasController.dispose();
    _workplaceController.dispose();
    super.dispose();
  }

  void _validatePasswords() {
    setState(() {
      _passwordError =
          _passwordController.text != _confirmPasswordController.text
              ? "Şifreler eşleşmiyor"
              : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.onSecondary,
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.secondary,
                                spreadRadius: 5,
                                blurRadius: 15,
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _adController,
                              hintText: "Ad",
                              icon: Icons.person,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildTextField(
                              controller: _yasController,
                              hintText: "Yaş",
                              icon: Icons.perm_contact_calendar,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _buildTextField(
                        controller: _workplaceController,
                        hintText: "Yer ve Pozisyon",
                        icon: Icons.work,
                      ),
                      const SizedBox(height: 25),
                      _buildTextField(
                        controller: _emailController,
                        hintText: "E-posta",
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 25),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: "Şifre",
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 25),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: "Şifre Tekrar",
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      if (_passwordError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            _passwordError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          shadowColor: colorScheme.secondary,
                        ),
                        onPressed: _signUp,
                        child: const Text(
                          "Kayıt Ol",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Hesabınız Var mı?\nGiriş Yapmak İçin Tıklayınız.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary,
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: colorScheme.secondary,
            blurRadius: 50,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
