import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:beep_player/beep_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;


class Invoice extends StatefulWidget {
  @override
  _InvoiceState createState() => _InvoiceState();
}

class ScannedItem {
  DocumentSnapshot product;
  int quantity;
  double itemTotal;

  ScannedItem(this.product, this.quantity, this.itemTotal);
}
enum PaymentOption { cash, card, mobileMoney }

class _InvoiceState extends State<Invoice> {
  static const BeepFile _beepFile = BeepFile('assets/sounds/bip.wav');

  List<String> products = [];
  List<ScannedItem> scannedObjects = [];
  int quantity = 1; // Initialize with a default value of 1
  double itemTotal = 0;
  double totalPrice = 0;
  String searchValue = ''; 
  TextEditingController _recipientController = TextEditingController();
  TextEditingController _recipientnameController = TextEditingController();
  PaymentOption _selectedPaymentOption = PaymentOption.cash;
  ValueNotifier<PaymentOption> _selectedPaymentOptionNotifier = ValueNotifier<PaymentOption>(PaymentOption.cash);
  TextEditingController searchController = TextEditingController();
  List<String> searchResults = [];


  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    listExample();
    BeepPlayer.load(_beepFile);
  }

  @override
  void dispose() {
    BeepPlayer.unload(_beepFile);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppBar buildAppBar() {
      return AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          "Checkout Products",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
      IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          search(context);
        },
      ),
    ],
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
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
    return Scaffold(
      appBar: buildAppBar(),
      floatingActionButton: floatingBar(),
      body: 
  
          buildInvoiceList(),
   
    );
  }

  Future<void> startBarcodeScanStream() async {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
            "#ff6666", "Cancel", true, ScanMode.BARCODE)
        .listen((barcode) => print(barcode));
  }

  Future<void> playBip() async {
    await player.setSource(AssetSource('sounds/bip.wav'));
  }

  Future<void> scanBarcodeNormal() async {
  String barcodeScanRes;

  try {
    barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print(barcodeScanRes);
  } on PlatformException {
    barcodeScanRes = 'Failed to get platform version.';
  }

  if (!mounted) return;

  if (barcodeScanRes != '-1' && barcodeScanRes != null) {
    // Check if the item is already scanned
    if (scannedObjects.any((item) => item.product['barcode'] == barcodeScanRes)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Duplicate Item'),
          content: Text('This item has already been scanned.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showScannedItemsDialog();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("products")
                .where("barcode", isEqualTo: barcodeScanRes)
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
                DocumentSnapshot product = snapshot.data.docs.first;
                ScannedItem scannedItem = ScannedItem(product, quantity, itemTotal);
                scannedObjects.add(scannedItem);

                totalPrice += (double.tryParse(product['price']) ?? 0) * quantity;

                return Dialog(
                  child: SingleChildScrollView(
                    child: Container(
                      height: 500,
                      child: Column(
                        children: [
                          Container(
                            height: 450,
                            width: 200,
                            child: ListView.builder(
                              itemCount: scannedObjects.length,
                              itemBuilder: (context, index) {
                                ScannedItem scannedItem = scannedObjects[index];
                                DocumentSnapshot product = scannedItem.product;
                                int quantity = scannedItem.quantity;
                                double price = double.tryParse(product['price']) ?? 0;
                                double itemTotal = price * quantity;
                                scannedItem.itemTotal = itemTotal;

                                return ListTile(
                                  title: Text(product['name']),
                                  subtitle: Text('Price: \ZMK${product['price']}'),
                                  trailing: SizedBox(
                                    width: 50,
                                    child: TextFormField(
                                      initialValue: quantity.toString(),
                                      onChanged: (value) {
                                        setState(() {
                                          scannedItem.quantity = int.tryParse(value) ?? 0;
                                          scannedItem.itemTotal = price * int.tryParse(value);

                                          totalPrice +=
                                              (scannedItem.quantity - quantity) * price;
                                        });
                                      },
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      scannedObjects.removeAt(index);
                                      totalPrice -= itemTotal;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          Container(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        //scanBarcodeNormal();
                                      },
                                      child: Text('Next'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        showInvoiceDialog();
                                      },
                                      child: Text('Done'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
}


void handleTappedItem(String product) {
  // Check if the item is already scanned
  if (scannedObjects.any((item) => item.product['name'] == product)) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Duplicate Item'),
        content: Text('This item has already been scanned.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showScannedItemsDialog();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("products")
              .where("name", isEqualTo: product)
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
              DocumentSnapshot product = snapshot.data.docs.first;
              ScannedItem scannedItem = ScannedItem(product, quantity, itemTotal);
              scannedObjects.add(scannedItem);

              totalPrice += (double.tryParse(product['price']) ?? 0) * quantity;

              return Dialog(
                child: SingleChildScrollView(
                  child: Container(
                    height: 500,
                    child: Column(
                      children: [
                        Container(
                          height: 450,
                          width: 200,
                          child: ListView.builder(
                            itemCount: scannedObjects.length,
                            itemBuilder: (context, index) {
                              ScannedItem scannedItem = scannedObjects[index];
                              DocumentSnapshot product = scannedItem.product;
                              int quantity = scannedItem.quantity;
                              double price = double.tryParse(product['price']) ?? 0;
                              double itemTotal = price * quantity;
                              scannedItem.itemTotal = itemTotal;

                              return ListTile(
                                title: Text(product['name']),
                                subtitle: Text('Price: \ZMK${product['price']}'),
                                trailing: SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    initialValue: quantity.toString(),
                                    onChanged: (value) {
                                      setState(() {
                                        scannedItem.quantity = int.tryParse(value) ?? 0;
                                        scannedItem.itemTotal = price * int.tryParse(value);

                                        totalPrice +=
                                            (scannedItem.quantity - quantity) * price;
                                      });
                                    },
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    scannedObjects.removeAt(index);
                                    totalPrice -= itemTotal;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        Container(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      //scanBarcodeNormal();
                                    },
                                    child: Text('Next'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showInvoiceDialog();
                                    },
                                    child: Text('Done'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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


Widget buildInvoiceList() {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  searchController.clear();
                  searchResults.clear();
                });
              },
            ),
          ),
          onChanged: (value) {
            setState(() {
              searchValue = value;
            });
          },
        ),
      ),
      Expanded(
        child: products.isEmpty
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: searchResults.isEmpty ? products.length : searchResults.length,
                itemBuilder: (context, index) {
                  final product = searchResults.isEmpty ? products[index] : searchResults[index];
                  return ListTile(
                    title: Text(product),
                    onTap: () async {
                      handleTappedItem(product);
                    },
                  );
                },
              ),
      ),
    ],
  );
}

void showScannedItemsDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: SingleChildScrollView(
          child: Container(
            height: 500,
            child: Column(
              children: [
                Container(
                  height: 450,
                  width: 200,
                  child: ListView.builder(
                    itemCount: scannedObjects.length,
                    itemBuilder: (context, index) {
                      ScannedItem scannedItem = scannedObjects[index];
                      DocumentSnapshot product = scannedItem.product;
                      int quantity = scannedItem.quantity;
                      double price = double.tryParse(product['price']) ?? 0;
                      double itemTotal = price * quantity;
                      scannedItem.itemTotal = itemTotal;

                      return ListTile(
                        title: Text(product['name']),
                        subtitle: Text('Price: \ZMK${product['price']}'),
                        trailing: SizedBox(
                          width: 50,
                          child: TextFormField(
                            initialValue: quantity.toString(),
                            onChanged: (value) {
                              setState(() {
                                scannedItem.quantity = int.tryParse(value) ?? 0;
                                scannedItem.itemTotal = price * int.tryParse(value);

                                totalPrice +=
                                    (scannedItem.quantity - quantity) * price;
                              });
                            },
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            scannedObjects.removeAt(index);
                            totalPrice -= itemTotal;
                          });
                        },
                      );
                    },
                  ),
                ),
                Container(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              //scanBarcodeNormal();
                            },
                            child: Text('Next'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              showInvoiceDialog();
                            },
                            child: Text('Done'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void search(BuildContext context) {
  setState(() {
    searchResults = products
        .where((name) => name.contains(searchValue))
        .toList();
  });

 
}



void showInvoiceDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Total Price: \ZMK${totalPrice.toStringAsFixed(2)}'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _recipientController,
                    decoration: InputDecoration(
                      labelText: 'Customer Email',
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _recipientnameController,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    File invoice = await generateInvoice();
                    await sendInvoice(invoice);
                    //await storeScannedItems(); // Store the scanned items in the database
                    BeepPlayer.play(_beepFile);
                    scannedObjects.clear();
                    _recipientController.clear();
                    _recipientnameController.clear();
                    setState(() {
                      totalPrice = 0;
                    });
                    Navigator.pop(context); // Close the invoice dialog
                  },
                  child: Text('Send Receipt'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


String generateUniqueInvoiceNumber() {
  // Generate a unique invoice number based on your logic
  // You can use a combination of date, time, random numbers, or any other criteria
  final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final String random = Random().nextInt(1000).toString().padLeft(3, '0');
  return 'INV_$timestamp$random';
}

  Future<File> generateInvoice() async {
  final pdf = pw.Document();

  final DateTime currentDate = DateTime.now();
  final String invoiceNumber = generateUniqueInvoiceNumber();

  pdf.addPage(
    pw.MultiPage(
      build: (context) {
        return <pw.Widget>[
          pw.Container(
            margin: pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Text(
              'Kamiza Book Sellers',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
         pw.Container(
            margin: pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Text(
              'Invoice $invoiceNumber',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(
            margin: pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Text('Customer Information'),
          ),
          pw.Container(
            margin: pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Customer Name:'),
                pw.Text(_recipientnameController.text),
              ],
            ),
          ),
          pw.Container(
            margin: pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Customer Email:'),
                pw.Text(_recipientController.text),
              ],
            ),
          ),
          pw.Container(
            margin: pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date:'),
                pw.Text(currentDate.toString()),
              ],
            ),
          ),
          pw.Container(
            margin: pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Text('Product Details'),
          ),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(),
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            headerHeight: 30,
            cellHeight: 40,
            cellAlignment: pw.Alignment.center,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(),
            headerPadding: pw.EdgeInsets.symmetric(vertical: 5),
            cellPadding: pw.EdgeInsets.symmetric(vertical: 5),
            data: <List<String>>[
              <String>['Product Name', 'Quantity', 'Price', 'Total'],
              ...scannedObjects.map((item) {
                return <String>[
                  item.product['name'],
                  item.quantity.toString(),
                  '${item.product['price']}',
                  '${item.itemTotal.toStringAsFixed(2)}',
                ];
              }).toList(),
              <String>['', '', 'Discount:', ' - '],
              <String>['', '', 'Total:', '\ZMK${totalPrice.toStringAsFixed(2)}'],
            ],
          ),
          pw.Container(
            margin: pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Cashier: Wana Chilila'),
              ],
            ),
          ),
        ];
      },
    ),
  );

  final output = await getTemporaryDirectory();
  final outputFile = File('${output.path}/invoice.pdf');
  await outputFile.writeAsBytes(await pdf.save());
  firebase_storage.UploadTask task = await uploadFile(outputFile, invoiceNumber);
  return outputFile;
}


  Future<void> sendInvoice(File invoice) async {
    final Email email = Email(
      body: 'Please find the attached invoice.',
      subject: 'invoice',
      recipients: [_recipientController.text],
      attachmentPaths: [invoice.path],
    );

    await FlutterEmailSender.send(email);
  }

  Future<void> storeScannedItems() async {
  CollectionReference productsRef = FirebaseFirestore.instance.collection('products');
  CollectionReference scannedItemsRef = FirebaseFirestore.instance.collection('scanned_items');

  String invoiceNumber = generateUniqueInvoiceNumber(); // Generate the invoice number

  for (ScannedItem item in scannedObjects) {
    await scannedItemsRef.doc(invoiceNumber).collection('items').add({
      'product_name': item.product['name'],
      'quantity': item.quantity,
      'price': item.product['price'],
      'item_total': item.itemTotal,
      'payment_option': _selectedPaymentOption.toString(),
    });

    await productsRef.doc(item.product.id).update({
      'quantity': FieldValue.increment(-item.quantity),
    });
  }
}


Future<firebase_storage.UploadTask> uploadFile(File file, String invoiceNumber) async {  
  

  firebase_storage.UploadTask uploadTask;  
  
  
  // Create a Reference to the file  
  firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance  
  .ref()  
      .child('invoices')  
      .child(invoiceNumber);  
  
  final metadata = firebase_storage.SettableMetadata(  
      contentType: 'file/pdf',  
      customMetadata: {'picked-file-path': file.path});  
  print("Uploading..!");  
  
  uploadTask = ref.putData(await file.readAsBytes(), metadata);  
  
  print("done..!");  
  return Future.value(uploadTask);  
}


Future<void> listExample() async {
  QuerySnapshot productsSnapshot = await FirebaseFirestore.instance.collection('products').get();

  List<String> products = productsSnapshot.docs.map((doc) => doc['name'] as String).toList();

  setState(() {
    this.products = products;
  });
}




}