class User {
  final String? name;
  final int? age;
  final String? workplace;
  final String? imagePath;
  final List<String>? additionalImages;

  User({
    this.name,
    this.age,
    this.workplace,
    this.imagePath,
    this.additionalImages,
  });

  // Veritabanından kullanıcı verisi oluşturmak için factory method
  factory User.fromDatabase({
    required String name,
    required int age,
    required String workplace,
    required String imagePath,
    List<String>? additionalImages,
  }) {
    return User(
      name: name,
      age: age,
      workplace: workplace,
      imagePath: imagePath,
      additionalImages: additionalImages,
    );
  }
}

// Örnek kullanıcılar listesi. Bu liste artık veritabanından çekilecek.
final List<User> users = [];
