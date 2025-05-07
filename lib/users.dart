class User {
  final String? name;
  final int? age;
  final String? workplace;
  final String? imagePath;
  final List<String> additionalImages;
  final String?
  userId; // Kullanıcının benzersiz kimliği (Firebase UID veya PostgreSQL ID)

  User({
    this.name,
    this.age,
    this.workplace,
    this.imagePath,
    this.additionalImages = const [],
    this.userId,
  });

  // Veritabanından kullanıcı verisi oluşturmak için factory method
  factory User.fromDatabase({
    required String name,
    required int age,
    String? workplace,
    required String imagePath,
    List<String> additionalImages = const [],
    String? userId,
  }) {
    return User(
      name: name,
      age: age,
      workplace: workplace,
      imagePath: imagePath,
      additionalImages: additionalImages,
      userId: userId,
    );
  }
}

// Örnek kullanıcılar listesi. Bu liste artık veritabanından çekilecek.
final List<User> users = [];
