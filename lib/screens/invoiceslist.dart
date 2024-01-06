import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:retail/screens/pdf_viewer_page.dart';

class invoiceslist extends StatefulWidget {
  @override
  _invoiceslistState createState() => _invoiceslistState();
}

class _invoiceslistState extends State<invoiceslist> {
  List<String> invoiceNumbers = []; // List to store invoice numbers
  String searchValue = ''; // Value entered in the search bar
  int selectedInvoiceIndex = -1; // Index of the selected invoice
  TextEditingController searchController = TextEditingController();
List<String> searchResults = [];


  @override
  void initState() {
    super.initState();
    listExample();
    // Fetch invoice numbers when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    AppBar buildAppBar() {
  return AppBar(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.blue,
    iconTheme: IconThemeData(color: Colors.black),
    title: Text('Invoices'),
  );
}

  Widget floatingBar() => Ink(
  decoration: ShapeDecoration(
    shape: StadiumBorder(),
  ),
  child: FloatingActionButton.extended(
    onPressed: () {
     
       search(context);
      
    },
    backgroundColor: Colors.black,
    icon: Icon(
      FontAwesomeIcons.search,
      color: Colors.white,
    ),
    label: Text(
      "SEARCH",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        child: invoiceNumbers.isEmpty
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: searchResults.isEmpty ? invoiceNumbers.length : searchResults.length,
                itemBuilder: (context, index) {
                  final invoiceNumber = searchResults.isEmpty ? invoiceNumbers[index] : searchResults[index];
                  return ListTile(
                    title: Text(invoiceNumber),
                    onTap: () async {
                      final url = invoiceNumber;
                      try {
                        final file = await loadFirebase(url);
                        if (file != null) {
                          openPDF(context, file);
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Error'),
                              content: Text('Failed to load PDF file.'),
                              actions: [
                                ElevatedButton(
                                  child: Text('OK'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Error'),
                            content: Text('An error occurred while loading the PDF file.'),
                            actions: [
                              ElevatedButton(
                                child: Text('OK'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                        print(e);
                      }
                    },
                  );
                },
              ),
      ),
    ],
  );
}

  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
      );


  void search(BuildContext context) {
  setState(() {
    searchResults = invoiceNumbers
        .where((invoiceNumber) => invoiceNumber.contains(searchValue))
        .toList();
  });

 
}


  Future<File> loadFirebase(String url) async {
    try {
      final refPDF = firebase_storage.FirebaseStorage.instance.ref('invoices').child(url);
      final bytes = await refPDF.getData();

      return _storeFile(url, bytes);
    } catch (e) {
      return null;
    }
  }

  static Future<File> _storeFile(String url, List<int> bytes) async {
    final filename = basename(url);
    final dir = await getApplicationDocumentsDirectory();

    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> listExample() async {
    firebase_storage.ListResult result =
        await firebase_storage.FirebaseStorage.instance.ref().child('invoices').listAll();

    List<String> fileNames = [];
    result.items.forEach((firebase_storage.Reference ref) {
      fileNames.add(ref.name);
      print('Found file: ${ref.name}');
    });

    setState(() {
      invoiceNumbers = fileNames;
    });
  }
}
