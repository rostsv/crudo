import 'package:flutter/material.dart';
import 'package:crudo/ui/core/themes/theme.dart';

void main() => runApp(const CrudoApp());

class CrudoApp extends StatelessWidget {
  const CrudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crudo',
      debugShowCheckedModeBanner: false,
      theme: crudoTheme,
      home: const Scaffold(body: Center(child: Text('Crudo'))),
    );
  }
}
