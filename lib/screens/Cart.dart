import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:retail/screens/PurchaseHistory.dart';
import 'package:toast/toast.dart';

class Cart extends StatefulWidget {
  Cart({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _Cart createState() => _Cart();
}

class _Cart extends State<Cart> {
  User user; // Update the type to User
  Razorpay razorpay;
  int price;
  String phoneNumber;

  Future<void> getUserData() async {
    User userData = FirebaseAuth.instance.currentUser; // Remove the parentheses
    if (userData != null) {
      setState(() {
        user = userData;
        print(userData.uid);
        getUsercontact();
      });
    }
  }

 Future<void> getUsercontact() async {
  DocumentSnapshot<Map<String, dynamic>> cn = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  String number = cn.data()['phoneNumber'];
  if (number != null) {
    setState(() {
      phoneNumber = number;
    });
  }
}


  Future gettotalId() async {
    QuerySnapshot qn = await FirebaseFirestore.instance
        .collection('userData')
        .doc('${user.uid}')
        .collection('cartData')
        .get();
    return qn.docs.length.toString();
  }

  Future gettotal() async {
    int total = 0;
    QuerySnapshot qn = await FirebaseFirestore.instance
        .collection('userData')
        .doc('${user.uid}')
        .collection('cartData')
        .get();
    for (int i = 0; i < qn.docs.length; i++) {
      total = total + int.parse(qn.docs[i]['price']);
      price = total;
    }
    setState(() {
      price = total;
      return price;
    });
    return total;
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    gettotalId();
    gettotal();
    getUsercontact();
    razorpay = new Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlerPaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlerErrorFailure);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handlerExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    razorpay.clear();
  }

  void openCheckout() {
    var options = {
      'key': 'rzp_test_FP6SaOOCVO8nIk',
      'amount': price * 100,
      'name': 'Acme Corp.',
      'description': 'Grocery Product',
      'prefill': {'contact': phoneNumber, 'email': '${user.email}'},
      'external': {
        'wallet': ['paytm']
      }
    };
    try {
      razorpay.open(options);
    } catch (e) {
      print(e.toString());
    }
  }

  void handlerPaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment success');
    Toast.show('Payment success', context);
    await FirebaseFirestore.instance
        .collection('userData')
        .doc('${user.uid}')
        .collection('cartData')
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        FirebaseFirestore.instance
            .collection('userOrders')
            .doc('${user.uid}')
            .collection('orders')
            .doc()
            .set(result.data as Map<String, dynamic>);
      });
    });
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => PurchaseHistory()));
    razorpay.clear();
  }

  void handlerErrorFailure() {
    print('payment Error');
    Toast.show('Payment Error', context);
  }

  void handlerExternalWallet() {
    print('External wallet');
    Toast.show('External wallet', context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("userData")
                      .doc('${user.uid}')
                      .collection('cartData')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.data == null)
                      return Text(
                        '                    No Items In The Cart',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      );
                    return Container(
                        height: 382,
                        width: 395,
                        child: ListView.separated(
                            itemCount: snapshot.data.docs.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot products =
                                  snapshot.data.docs[index];
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  
                                  Text(
                                    products['name'],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    "\ZMK " + products['price'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  GestureDetector(
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        gettotalId();
                                      });
                                      FirebaseFirestore.instance
                                          .collection("userData")
                                          .doc('${user.uid}')
                                          .collection('cartData')
                                          .doc(products['id'])
                                          .delete()
                                          .then((result) {})
                                          .catchError((e) {
                                        print(e);
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      'Deleted',
      style: TextStyle(color: Colors.white, fontSize: 15),
      textAlign: TextAlign.start,
    ),
    duration: Duration(milliseconds: 300),
    backgroundColor: Color(0xFF3D82AE),
  ),
);

                                    },
                                  )
                                ],
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return SizedBox(height: 20);
                            }));
                  }),
            ],
          ),
        ),
        bottomNavigationBar: FutureBuilder(
            future: gettotalId(),
            builder: (context, snapshot) {
              return Container(
                margin: EdgeInsets.only(left: 35, bottom: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(right: 10),
                      padding: EdgeInsets.all(25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          FutureBuilder(
                              future: gettotal(),
                              builder: (context, price) {
                                return Text(
                                  "Total:                   " + '${price.data}',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w300),
                                );
                              }),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey[700],
                    ),
                    Container(
                      margin: EdgeInsets.only(right: 10),
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Row(
                        children: <Widget>[
                          Text("Quantity",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              )),
                          SizedBox(
                            width: 200,
                          ),
                          Text(
                              snapshot.data != null ? snapshot.data : 'Loading',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                    GestureDetector(
                      child: Container(
                        margin: EdgeInsets.only(right: 25),
                        padding: EdgeInsets.all(25),
                        decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "Pay",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        openCheckout();
                      },
                    ),
                  ],
                ),
              );
            }));
  }
}

AppBar buildAppBar() {
  return AppBar(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.blue,
    iconTheme: IconThemeData(color: Colors.black),
    title: Text(
      "My Orders",
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
  );
}
