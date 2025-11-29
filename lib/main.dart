import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'home_page.dart';
import 'customer/customer_login.dart';
import 'customer/customer_signup.dart';
import 'massager/massager_login.dart';
import 'massager/massager_signup.dart';
import 'massager/massager_home_page.dart';
import 'massager/massager_enter_code_page.dart';
import 'apply_page.dart';
import 'customer/customer_home_page.dart';
import 'customer/cart_page.dart';
import 'customer/booking_page.dart';
import 'customer/customer_bookings_page.dart';
import 'providers/cart_provider.dart';
import 'providers/session_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized, continue
    print('Firebase already initialized: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => SessionProvider()),
      ],
      child: MaterialApp(
        title: 'Massage App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.teal),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/customer_login': (context) => const CustomerLoginPage(),
          '/customer_signup': (context) => const CustomerSignupPage(),
          '/massager_login': (context) => const MassagerLoginPage(),
          '/massager_signup': (context) => const MassagerSignupPage(),
          '/apply': (context) => const ApplyPage(),
          '/customer_home': (context) => const CustomerHomePage(),
          '/cart': (context) => const CartPage(),
          '/booking': (context) => const BookingPage(),
          '/customer_bookings': (context) => const CustomerBookingsPage(),
          '/massager_enter_code': (context) => const MassagerEnterCodePage(),
          '/massager_home': (context) => const MassagerHomePage(therapistCode: 'THERAPIST123'),
        },
      ),
    );
  }
}
