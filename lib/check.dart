import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retail/screens/home_page.dart';
import 'package:retail/screens/login_page.dart';

class Check extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  return FutureBuilder<User>(
    future: FirebaseAuth.instance.authStateChanges().first,
    builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        // While waiting for the future to complete, show a loading indicator
        return CircularProgressIndicator();
      }
      if (snapshot.hasData) {
        // User is logged in
        User user = snapshot.data; // This is your user instance
        return HomePage();
      } else {
        // No user is logged in
        return LoginPage();
      }
    },
  );
}
}
