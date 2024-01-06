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

import 'checkout.dart';

class MgtPage extends StatefulWidget {
  MgtPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MgtPageState createState() => _MgtPageState();
}

class _MgtPageState extends State<MgtPage> {
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
  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.BARCODE);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    if (barcodeScanRes != '-1' || null) {
      return showDialog(
          context: context,
          builder: (context) {
            return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("products")
                    .where("barcode", isEqualTo: '$barcodeScanRes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Dialog(
                      child: Container(
                        height: 300,
                        child: Text('Product Not Found'),
                      ),
                    );
                  } else {
                    return Dialog(
                      child: Container(
                        height: 350,
                        child: Column(children: [
                          Container(
                              height: 350,
                              width: 165,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: snapshot.data.docs.length,
                                itemBuilder: (context, index) {
                                  DocumentSnapshot products =
                                      snapshot.data.docs[index];
                                  return ScanCard(products: products);
                                },
                              )),
                        ]),
                      ),
                    );
                  }
                });
          });
    }
  }
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // UserAccountsDrawerHeader code...

              SizedBox(height: 20),

              FutureBuilder<int>(
      future: countProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Display a loading indicator while fetching the count
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Display an error message if there was an error
        } else {
          final productCount = snapshot.data;
          return Text('Product Count: $productCount'); // Display the count of products
        }
      },
    ),

              SizedBox(height: 20),

             FutureBuilder<int>(
      future: calculateTotalQuantity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Display a loading indicator while calculating the total
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Display an error message if there was an error
        } else {
          final totalQuantity = snapshot.data;
          return Text('Total Products in Stock: $totalQuantity'); // Display the total quantity
        }
      },
    ),

              SizedBox(height: 20),

             FutureBuilder<double>(
      future: calculateTotalCost(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final totalCost = snapshot.data;
          return Text('Total Products Cost: \ZMK ${totalCost.toStringAsFixed(2)}');
        }
      },
    ),

              SizedBox(height: 20),

              SquareCardButton(
                color: Colors.blue,
                icon: Icons.favorite,
                label: 'Inventory',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Inventory()),
                  );
                },
              ),

              SizedBox(height: 20),

              SquareCardButton(
                color: Colors.blue,
                icon: Icons.star,
                label: 'Invoices',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Invoice()),
                  );
                },
              ),

              SizedBox(height: 20),

              SquareCardButton(
                color: Colors.blue,
                icon: Icons.camera,
                label: 'Cotations',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Cotation()),
                  );
                },
              ),
            ],
          ),
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
        "Inventory Management",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.shopping_cart,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pushNamed('/cartpage');
          },
        )
      ],
    );
  }

  
      
}
class SquareCardButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const SquareCardButton({
    this.color,
    this.icon,
    this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        color: color,
        child: SizedBox(
          width: 150,
          height: 250,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.black,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ItemCard extends StatelessWidget {
  const ItemCard({
    Key key,
    @required this.products,
  }) : super(key: key);

  final DocumentSnapshot products;

  @override
Widget build(BuildContext context) {
  User user = FirebaseAuth.instance.currentUser;
  String _userId = user?.uid ?? ''; // Assign an empty string if user is null

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0 / 4),
        child: Text(
          products['name'],
          style: TextStyle(
            color: Color(0xFF535353),
          ),
        ),
      ),
      Row(
        children: [
          Text(
            "\ZMK " + products['price'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 60,
          ),
          GestureDetector(
            child: Icon(
              CupertinoIcons.cart_fill_badge_plus,
              color: Colors.black,
              size: 30,
            ),
            onTap: () {
              DocumentReference<Map<String, dynamic>> documentReference =
                  FirebaseFirestore.instance
                      .collection('userData')
                      .doc(_userId)
                      .collection('cartData')
                      .doc();
              documentReference
                  .set({
                    'uid': _userId,
                    'barcode': products['barcode'],
                    'name': products['name'],
                    'category': products['category'],
                    'price': products['price'],
                    'id': documentReference.id, // Use id instead of deprecated documentID
                  })
                  .then((result) {})
                  .catchError((e) {
                    print(e);
                  });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Added to Cart',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.start,
                  ),
                  duration: Duration(milliseconds: 300),
                  backgroundColor: Color(0xFF3D82AE),
                ),
              );
            },
          ),
        ],
      )
    ],
  );
}

}

class ScanCard extends StatelessWidget {
  const ScanCard({
    Key key,
    @required this.products,
  }) : super(key: key);
  final DocumentSnapshot products;

  @override
Widget build(BuildContext context) {
  User user = FirebaseAuth.instance.currentUser;
  String _userId = user?.uid ?? ''; // Assign an empty string if user is null

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0 / 4),
        child: Text(
          products['name'],
          style: TextStyle(
            color: Color(0xFF535353),
            fontSize: 18,
          ),
        ),
      ),
      Column(
        children: [
          Text(
            "category: " + products['category'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(
            width: 30,
          ),
        ],
      ),
      Column(
        children: [
          Text(
            "quantity: " + products['quantity'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(
            width: 30,
          ),
        ],
      ),
      Row(
        children: [
          Text(
            "price: \ZMK" + products['price'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          
        ],
      ),
      SizedBox(
        width: 10,
      ),
      SizedBox(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              primary: Color(0xFF3D82AE),
              onPrimary: Colors.white,
            ),
            onPressed: () {
              DocumentReference<Map<String, dynamic>> documentReference =
                  FirebaseFirestore.instance
                      .collection('userData')
                      .doc(_userId)
                      .collection('cartData')
                      .doc();
              documentReference
                  .set({
                    'uid': _userId,
                    'barcode': products['barcode'],
                    'name': products['name'],
                    'category': products['category'],
                    'price': products['price'],
                    'id': documentReference.id, // Use id instead of deprecated documentID
                  })
                  .then((result) {
                    dialogTrigger(context);
                  })
                  .catchError((e) {
                    print(e);
                  });
            },
            child: Text(
              'Add to cart',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    ],
  );
}

}

Future<bool> dialogTrigger(BuildContext context) async {
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Job done', style: TextStyle(fontSize: 22.0)),
          content: Text(
            'Added Successfully',
            style: TextStyle(fontSize: 20.0),
          ),
          actions: <Widget>[
            TextButton(
  child: Text(
    'Alright',
    style: TextStyle(fontSize: 18),
  ),
  onPressed: () {
    Navigator.of(context).pop();
  },
)

          ],
        );
      });
}
