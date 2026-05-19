import 'package:flutter/material.dart';
import 'contacts_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Danh bạ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ContactsListScreen(),
    );
  }
}