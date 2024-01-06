import 'package:flutter/material.dart';
import 'package:retail/screens/Cart.dart';
import 'package:retail/check.dart';
import 'package:retail/screens/PurchaseHistory.dart';
import 'package:retail/screens/cotation.dart';
import 'package:retail/screens/cotationslist.dart';
import 'package:retail/screens/invoiceslist.dart';
import 'package:retail/screens/mgt.dart';
import 'package:retail/screens/pdf_viewer_page.dart';
import 'package:retail/screens/pos.dart';
import 'package:retail/screens/receiptslist.dart';
import 'package:retail/screens/signup.dart';
import 'package:retail/screens/inventory.dart';
import 'package:retail/screens/invoice.dart';
import 'package:retail/screens/checkout.dart';
import 'package:retail/screens/splashscreen.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp();
  runApp(MyApp());
  }

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final routes = <String, WidgetBuilder>{
    '/check': (BuildContext context) => new Check(),
    '/homepage': (BuildContext context) => new HomePage(),
    '/loginpage': (BuildContext context) => new LoginPage(),
    '/signup': (BuildContext context) => new Signup(),
    '/inventory':(BuildContext context) => new Inventory(),
    '/invoice':(BuildContext context) => new Invoice(),
    '/Cotation':(BuildContext context) => new Cotation(),
    '/CheckOut':(BuildContext context) => new CheckOut(),
    '/cartpage': (BuildContext context) => new Cart(),
    '/mgtpage': (BuildContext context) => new MgtPage(),
    '/pospage': (BuildContext context) => new PosPage(),
    '/purchasehistory':  (BuildContext context) => new PurchaseHistory(),
    '/PDFViewerPage':  (BuildContext context) => new PDFViewerPage(),
    '/receipts': (BuildContext context) => receiptslist(),
        '/invoices': (BuildContext context) => invoiceslist(),
        '/cotations': (BuildContext context) => cotationslist(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetailApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        fontFamily: 'Nunito',
      ),
      home: SplashScreen(),
      routes: routes,
    );
  }
}
