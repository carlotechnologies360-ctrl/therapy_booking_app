import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'home_page.dart';
import 'customer/customer_login.dart';
import 'customer/customer_signup.dart';
import 'massager/massager_login.dart';
import 'apply_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // uses  firebase options
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Massage App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/customer_login': (context) => const CustomerLoginPage(),
        '/customer_signup': (context) => const CustomerSignupPage(),
        '/massager_login': (context) => const MassagerLoginPage(),
        '/apply': (context) => const ApplyPage(),
      },
    );
  }
}
