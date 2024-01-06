import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retail/screens/cotation.dart';
import 'package:retail/screens/inventory.dart';
import 'package:retail/screens/invoice.dart';
import 'package:retail/add_pro/add_product.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:retail/screens/PurchaseHistory.dart';
import 'package:retail/screens/mgt.dart';
import 'package:retail/screens/pos.dart';

import 'checkout.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User user;

  Future<void> getUserData() async {
    User userData = FirebaseAuth.instance.currentUser;
    setState(() {
      user = userData;
      print(userData.uid);
    });
  }

  Future<void> getUser() async {
    DocumentSnapshot<Map<String, dynamic>> cn = await FirebaseFirestore.instance
        .collection('users')
        .doc('${user.uid}')
        .get();
    return cn;
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    getUser();
  }

  startBarcodeScanStream() async {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
            "#ff6666", "Cancel", true, ScanMode.BARCODE)
        .listen((barcode) => print(barcode));
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  

  Future<int> countProducts() async {
    final collectionRef = FirebaseFirestore.instance.collection('products');
    final snapshot = await collectionRef.get();
    return snapshot.size;
  }

  Future<int> calculateTotalQuantity() async {
    final collectionRef = FirebaseFirestore.instance.collection('products');
    final snapshot = await collectionRef.get();
    int totalQuantity = 0;

    for (var doc in snapshot.docs) {
      final productData = doc.data();
      final quantity = productData['quantity'] ?? 0; // Assuming 'quantity' is the field name for quantity in each product document
      totalQuantity += quantity;
    }

    return totalQuantity;
  }

  Future<double> calculateTotalCost() async {
    final collectionRef = FirebaseFirestore.instance.collection('products');
    final snapshot = await collectionRef.get();
    double totalCost = 0;

    for (var doc in snapshot.docs) {
      final productData = doc.data();
      final price = double.tryParse(productData['price']) ?? 0.0; // Assuming 'price' is the field name for price in each product document
      final quantity = productData['quantity'] ?? 0; // Assuming 'quantity' is the field name for quantity in each product document
      final productCost = price * quantity;
      totalCost += productCost;
    }

    return totalCost;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[250],
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: buildAppBar(),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            FutureBuilder(
                future: getUser(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return UserAccountsDrawerHeader(
                        currentAccountPicture: new CircleAvatar(
                          radius: 60.0,
                          backgroundColor: Colors.transparent,
                          backgroundImage: NetworkImage(
                              "https://cdn2.iconfinder.com/data/icons/website-icons/512/User_Avatar-512.png"),
                        ),
                        accountName: Text(
                          "Name: ${snapshot.data['displayName']}",
                          style: TextStyle(fontSize: 15),
                        ),
                        accountEmail: Text(
                          "Email: ${snapshot.data['email']}",
                          style: TextStyle(fontSize: 15),
                        ));
                  } else {
                    return CircularProgressIndicator();
                  }
                }),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text(
                "Purchase History",
                style: TextStyle(
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                    fontSize: 20),
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => PurchaseHistory()));
              },
            ),
            ListTile(
              leading: Icon(Icons.plus_one_rounded),
              title: Text(
                "Add products",
                style: TextStyle(
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                    fontSize: 20),
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => AddProduct()));
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text(
                "Log out",
                style: TextStyle(
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                    fontSize: 20),
              ),
              onTap: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut().then(
                  (value) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/loginpage', (Route<dynamic> route) => false);
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
      MaterialPageRoute(builder: (context) => PosPage())); // Navigate to the Point of Sale screen
              },
              child: Card(
                color: Colors.blue,
                child: SizedBox(
                  width: 150,
                  height: 250,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: Colors.black,
                        size: 40,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Point of Sale",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MgtPage())); // Navigate to the Inventory Management screen
              },
              child: Card(
                color: Colors.blue,
                child: SizedBox(
                  width: 150,
                  height: 250,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book,
                        color: Colors.black,
                        size: 40,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Inventory Management",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.blue,
      iconTheme: IconThemeData(color: Colors.black),
      title: Text(
        "Scan&Pay",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    
    );
  }

  
}

class PointOfSale extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Point of Sale"),
      ),
      body: Center(
        child: Text(
          "Point of Sale Screen",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class InventoryManagement extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inventory Management"),
      ),
      body: Center(
        child: Text(
          "Inventory Management Screen",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
