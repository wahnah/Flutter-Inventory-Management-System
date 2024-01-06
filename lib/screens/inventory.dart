import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:retail/screens/home_page.dart';
import 'package:retail/services/AuthUtil.dart';


class Inventory extends StatefulWidget {
  @override
  _InventoryState createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {

  TextEditingController searchController = new TextEditingController();
 
  @override
  Widget build(BuildContext context) {
  TextEditingController searchController = TextEditingController();
  AppBar buildAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.blue,
      iconTheme: IconThemeData(color: Colors.black),
      title: Text(
        "Inventory",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
    
  }
  Widget floatingBar() => Ink(
  decoration: ShapeDecoration(
    shape: StadiumBorder(),
  ),
  child: FloatingActionButton.extended(
    onPressed: () {
     
        scanBarcodeNormal();
      
    },
    backgroundColor: Colors.black,
    icon: Icon(
      FontAwesomeIcons.barcode,
      color: Colors.white,
    ),
    label: Text(
      "SCAN",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  ),
);
   return Scaffold(
    appBar: buildAppBar(),
    
  floatingActionButton: floatingBar(),
  // Other widgets and configurations for the Scaffold
  body: Column(
    children: [ // Replace ScanWidget with your scan component
      SizedBox(height: 10), // Add spacing between scan and search bar
      TextField(
  controller: searchController,
  decoration: InputDecoration(
    hintText: 'Search product name',
    prefixIcon: Icon(Icons.search),
    suffix: ElevatedButton.icon(
      onPressed: () {
        if (searchController.text.isNotEmpty) {
          searchProduct(searchController.text);
        }
      },
      style: ElevatedButton.styleFrom(
        primary: Colors.black,
        onPrimary: Colors.white,
        shape: StadiumBorder(),
      ),
      icon: Icon(Icons.search),
      label: Text(''),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
),
    ],
  ),
);
}

startBarcodeScanStream() async {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
            "#ff6666", "Cancel", true, ScanMode.BARCODE)
        .listen((barcode) => print(barcode));
  }

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
Future searchProduct(String query) {
  return showDialog(
    context: context,
    builder: (context) {
      return StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection("products")
      .where("name", isEqualTo: query)
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
          child: Column(
            children: [
              Container(
                height: 350,
                width: 165,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot products =
                        snapshot.data.docs[index];
                    return ScanCard(
                      products: products,
                       // Pass the editProductDialog as the callback
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  },
);

    },
  );
}





}


class ScanCard extends StatelessWidget {
  const ScanCard({
    Key key,
    @required this.products,
    @required this.onEditPressed, // Add a callback function for edit button press
  }) : super(key: key);
  
  final DocumentSnapshot products;
  final Function(DocumentSnapshot) onEditPressed; // Declare the callback function

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
        Row(
          children: [
            Text(
              "\ZMK " + products['price'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(
              width: 60,
            ),
          ],
        ),
        SizedBox(
          width: 10,
        ),
        ElevatedButton(
  onPressed: () {
    
      editProductDialog(context, products);
   
  },
  child: Text('Edit Product'),
),
      ],
    );
  }

  void editProductDialog(BuildContext context, DocumentSnapshot product) {
  TextEditingController nameController = TextEditingController(text: product['name']);
  TextEditingController priceController = TextEditingController(text: product['price'].toString());
  TextEditingController quantityController = TextEditingController(text: product['quantity'].toString());
  TextEditingController categoryController = TextEditingController(text: product['category']);

  showDialog(
  context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
              ),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Price',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: 'Category',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog without saving changes
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Save the changes to the Firestore database
              FirebaseFirestore.instance
                  .collection('products')
                  .doc(product.id)
                  .update({
                'name': nameController.text,
                'price': priceController.text,
                'quantity': int.tryParse(quantityController.text) ?? 0,
                'category': categoryController.text,
              });

              Navigator.pop(context); // Close the dialog after saving changes
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}
}
