class User {
  final String name;
  final String imagePath;

  User({
    required this.name,
    required this.imagePath,
  });
}

final List<User> users = [
  User(
    name: "Recep",
    imagePath: "assets/images/recep.png",
  ),
  User(
    name: "Müslüm",
    imagePath: "assets/images/muslum.png",
  ),
  User(
    name: "Dzeko",
    imagePath: "assets/images/dzeko.png",
  ),
  User(
    name: "Polat",
    imagePath: "assets/images/polat.png",
  ),
  User(
    name: "Fatih",
    imagePath: "assets/images/fatih.png",
  ),
];

