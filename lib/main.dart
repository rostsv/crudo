import 'package:flutter/material.dart';

void main() => runApp(const CrudoApp());

class CrudoApp extends StatelessWidget {
  const CrudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crudo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004D49)),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('Crudo'))),
    );
  }
}
