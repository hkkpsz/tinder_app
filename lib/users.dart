import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String name;
  final int age;
  final DateTime createdAt;

  User({
    required this.name,
    required this.age,
    required this.createdAt,
  });

  // Firestore'dan çekilen veriyi User nesnesine dönüştüren metod
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? 'Bilinmeyen',
      age: int.tryParse(json['age'].toString()) ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000, 1, 1),
    );
  }
}

// Kullanıcıları Firestore'dan çeken fonksiyon
Future<List<User>> fetchUsers() async {
  QuerySnapshot snapshot =
  await FirebaseFirestore.instance.collection('users').get();

  return snapshot.docs.map((doc) => User.fromJson(doc.data() as Map<String, dynamic>)).toList();
}
