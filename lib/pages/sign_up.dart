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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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

      // Kullanıcıyı doğrudan resim yükleme sayfasına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UploadImagePage(userId: userId),
        ),
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

  // Input alanları için widget
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText:
            isPassword
                ? _obscurePassword
                : (isConfirmPassword ? _obscureConfirmPassword : obscureText),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          suffixIcon:
              isPassword || isConfirmPassword
                  ? IconButton(
                    icon: Icon(
                      isPassword
                          ? (_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility)
                          : (_obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isPassword) {
                          _obscurePassword = !_obscurePassword;
                        } else if (isConfirmPassword) {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        }
                      });
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF0F0), Color(0xFFFFD9D9)],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Başlık
                            Text(
                              "Yeni Hesap Oluştur",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 20),

                            // İkon
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.primary.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withOpacity(0.5),
                                          spreadRadius: 5,
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.person_add,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 14),

                            Text(
                              "Hemen kayıt ol ve eşleşmeye başla!",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 20),

                            // Form alanları
                            // Ad ve Yaş satırı
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    controller: _adController,
                                    hintText: "Ad",
                                    icon: Icons.person,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    controller: _yasController,
                                    hintText: "Yaş",
                                    icon: Icons.calendar_today,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),

                            // Yer ve Pozisyon
                            _buildInputField(
                              controller: _workplaceController,
                              hintText: "Yer ve Pozisyon",
                              icon: Icons.work,
                            ),

                            SizedBox(height: 12),

                            // E-posta
                            _buildInputField(
                              controller: _emailController,
                              hintText: "E-posta",
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            SizedBox(height: 12),

                            // Şifre
                            _buildInputField(
                              controller: _passwordController,
                              hintText: "Şifre",
                              icon: Icons.lock,
                              obscureText: true,
                              isPassword: true,
                            ),

                            SizedBox(height: 12),

                            // Şifre Tekrar
                            _buildInputField(
                              controller: _confirmPasswordController,
                              hintText: "Şifre Tekrar",
                              icon: Icons.lock,
                              obscureText: true,
                              isConfirmPassword: true,
                            ),

                            if (_passwordError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _passwordError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            SizedBox(height: 20),

                            // Kayıt ol butonu
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              onPressed: _signUp,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Kayıt Ol",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),

                            SizedBox(height: 14),

                            // Giriş yap bağlantısı
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Zaten hesabınız var mı? ",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                    minimumSize: Size(10, 30),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    "Giriş Yap",
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 10),

                            // Gizlilik politikası bilgisi
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                  children: [
                                    TextSpan(text: "Kayıt olarak, "),
                                    TextSpan(
                                      text: "Kullanım Koşullarını ",
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: "ve "),
                                    TextSpan(
                                      text: "Gizlilik Politikasını ",
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: "kabul etmiş olursunuz."),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
