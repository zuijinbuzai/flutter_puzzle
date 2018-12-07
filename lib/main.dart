import 'package:flutter/material.dart';
import 'package:flutter_puzzle/page/GamePage.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "puzzle",
        theme: ThemeData.light(),
        home: Scaffold(
          body: HomePage(),
        ));
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GamePage(MediaQuery.of(context).size, 'images/1_free.jpg', 4);
  }
}
