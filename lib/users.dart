class User {
  final String? name;
  final int? age;
  final String? workplace;
  final String? imagePath;
  final List<String> additionalImages;
  final String? userId;
  final String? cvUrl; // CV URL için yeni alan eklendi
  final List<String> interests; // İlgi alanları
  final Map<String, dynamic>? location; // Konum bilgisi (lat, lng)

  User({
    this.name,
    this.age,
    this.workplace,
    this.imagePath,
    this.additionalImages = const [],
    this.userId,
    this.cvUrl,
    this.interests = const [],
    this.location,
  });

  // Firestore'dan gelen verilerden User nesnesi oluşturma
  factory User.fromFirestore(
    Map<String, dynamic> data,
    String id,
    List<String> images,
  ) {
    // İlgi alanlarını al
    List<String> interestList = [];
    if (data['interests'] != null) {
      interestList = List<String>.from(data['interests']);
    }

    return User(
      name: data['name'],
      age: data['age'],
      workplace: data['workplace'],
      imagePath: images.isNotEmpty ? images[0] : null,
      additionalImages: images.length > 1 ? images.sublist(1) : [],
      userId: id,
      cvUrl: data['cvUrl'],
      interests: interestList,
      location: data['location'],
    );
  }

  // User nesnesini Firestore'a kaydetmek için Map'e dönüştürme
  Map<String, dynamic> toFirestore() {
    // imagePath ve additionalImages birleştirilerek images dizisi olarak kaydedilecek
    List<String> allImages = [];
    if (imagePath != null) {
      allImages.add(imagePath!);
    }
    allImages.addAll(additionalImages);

    return {
      'name': name,
      'age': age,
      'workplace': workplace,
      'images': allImages,
      'cvUrl': cvUrl,
      'interests': interests,
      'location': location,
    };
  }
}

// Firebase'den dinamik olarak yükleneceği için bu liste artık boş
final List<User> users = [];
