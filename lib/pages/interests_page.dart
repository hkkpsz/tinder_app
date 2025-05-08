import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:ucanble_tinder/pages/home_page.dart';

class InterestsPage extends StatefulWidget {
  final String userId;
  final List<String> initialInterests;
  final bool
  isSignUp; // Kayıt sırasında mı yoksa profil düzenlemede mi kullanılacak

  const InterestsPage({
    Key? key,
    required this.userId,
    this.initialInterests = const [],
    this.isSignUp = false,
  }) : super(key: key);

  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _availableInterests = [
    'spor',
    'müzik',
    'film',
    'seyahat',
    'yemek',
    'teknoloji',
    'sanat',
    'kitap',
    'dans',
    'fotoğrafçılık',
    'doğa',
    'hayvanlar',
    'fitness',
    'yoga',
    'oyun',
    'kodlama',
    'moda',
    'gönüllülük',
    'kariyer',
    'alışveriş',
  ];

  late List<String> _selectedInterests;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Başlangıçta seçili ilgi alanlarını belirle
    _selectedInterests = List.from(widget.initialInterests);

    // Eğer boşsa, Firebase'den çek
    if (_selectedInterests.isEmpty) {
      _loadUserInterests();
    }
  }

  Future<void> _loadUserInterests() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Kullanıcı bilgilerini getir
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey('interests')) {
          setState(() {
            _selectedInterests = List<String>.from(userData['interests']);
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('İlgi alanları yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'İlgi alanları yüklenirken bir hata oluştu';
      });
    }
  }

  Future<void> _saveInterests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Kullanıcının ilgi alanlarını kaydet
      await _firestore.collection('users').doc(widget.userId).update({
        'interests': _selectedInterests,
      });

      setState(() {
        _isLoading = false;
      });

      // Kayıt sırasında ise ana sayfaya, düzenleme sırasında ise geri dön
      if (widget.isSignUp) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        Navigator.pop(context, _selectedInterests);
      }
    } catch (e) {
      print('İlgi alanları kaydedilirken hata: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'İlgi alanları kaydedilirken bir hata oluştu';
      });
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        // En fazla 10 ilgi alanı seçilebilir
        if (_selectedInterests.length < 10) {
          _selectedInterests.add(interest);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('En fazla 10 ilgi alanı seçebilirsiniz!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('İlgi Alanları'), elevation: 0),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İlgi alanlarınızı seçin',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'En fazla 10 ilgi alanı seçebilirsiniz. Bunlar size daha iyi eşleşmeler bulmamıza yardımcı olacak.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Seçili: ${_selectedInterests.length}/10',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 2.5,
                              ),
                          itemCount: _availableInterests.length,
                          itemBuilder: (context, index) {
                            final interest = _availableInterests[index];
                            final isSelected = _selectedInterests.contains(
                              interest,
                            );

                            return InkWell(
                              onTap: () => _toggleInterest(interest),
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.red.shade500
                                          : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: Colors.red.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 5,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Center(
                                  child: Text(
                                    interest,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveInterests,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
