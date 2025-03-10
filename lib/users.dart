import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String name;
  final int age;
  final String imagePath;

  User({
    required this.name,
    required this.imagePath,
    required this.age,
  });

  // Firestore'dan çekilen veriyi User nesnesine dönüştüren metod
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? 'Bilinmeyen',
      age: json['age'] ?? 0,
      imagePath: json['imagePath'] ?? '',
    );
  }
}

// Kullanıcıları Firestore'dan çeken fonksiyon
Future<List<User>> fetchUsers() async {
  QuerySnapshot snapshot =
  await FirebaseFirestore.instance.collection('users').get();

  return snapshot.docs.map((doc) => User.fromJson(doc.data() as Map<String, dynamic>)).toList();
}
