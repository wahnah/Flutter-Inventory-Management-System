import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: camel_case_types
class crudProduct {
  Future<void> addData(products) async {
    FirebaseFirestore.instance.collection('products').add(products).catchError((e) {
      print(e);
    });
  }
}
