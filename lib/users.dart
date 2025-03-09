class User {
  final String name;
  final int age;
  final String imagePath;

  User({
    required this.name,
    required this.imagePath,
    required this.age,
  });
}
final List<User> users = [
  User(
    name: "Recep",
    age: 49,
    imagePath: "assets/images/recep.png",
  ),
  User(
    name: "Müslüm",
    age: 70,
    imagePath: "assets/images/muslum.png",
  ),
  User(
    name: "Dzeko",
    age: 39,
    imagePath: "assets/images/dzeko.png",
  ),
  User(
    name: "Polat",
    age: 28,
    imagePath: "assets/images/polat.png",
  ),
  User(
    name: "Fatih",
    age: 67,
    imagePath: "assets/images/fatih.png",
  ),
  User(
    name: "Alperen",
    age: 21,
    imagePath: "assets/images/alperen.png",
  ),
  User(
    name: "Hakkı",
    age: 20,
    imagePath: "assets/images/hakki.png",
  ),
  User(
    name: "Kayra",
    age: 21,
    imagePath: "assets/images/kayra.png",
  )
];

