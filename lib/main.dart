import 'package:flutter/material.dart';
import 'package:ucanble_tinder/login_page.dart';
import 'users.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: Color.fromRGBO(122, 121, 122, 1.0),
            onPrimary: Color.fromARGB(255, 138, 171, 255),
            secondary: Color.fromARGB(255, 8, 22, 43),
            onSecondary: Color.fromARGB(255, 65, 65, 67),
            error: Color.fromARGB(255, 201, 0, 253),
            onError: Color.fromARGB(255, 243, 243, 244),
            surface: Colors.white,
            onSurface: Colors.black87,
          )
      ),
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
