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

class PurchaseHistory extends StatefulWidget {
  @override
  _PurchaseHistoryState createState() => _PurchaseHistoryState();
}

class _PurchaseHistoryState extends State<PurchaseHistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Purchase History")),
      body: ListView(
        children: [
          InkWell(
            child: CustomTile(title: "Receipts", route: "/receipts"),
            onTap: () {
              Navigator.pushNamed(context, "/receipts");
            },
          ),
          InkWell(
            child: CustomTile(title: "Invoices", route: "/invoices"),
            onTap: () {
              Navigator.pushNamed(context, "/invoices");
            },
          ),
          InkWell(
            child: CustomTile(title: "Cotations", route: "/cotations"),
            onTap: () {
              Navigator.pushNamed(context, "/cotations");
            },
          ),
        ],
      ),
    );
  }
}

class CustomTile extends StatelessWidget {
  final String title;
  final String route;

  CustomTile({this.title, this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      // Add your custom tile design here
      child: ListTile(
        title: Text(title),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
