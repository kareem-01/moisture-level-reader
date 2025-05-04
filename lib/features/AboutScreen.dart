import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {

  final List<String> names = [
    'John Smith',
    'Maria Garcia',
    'David Johnson',
    'Sarah Williams',
    'Michael Brown',
    'Jennifer Jones',
    'Robert Davis',
    'Elizabeth Miller',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: names.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ListTile(
              title: Text(
                names[index],
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          );
        },
      ),
    );
  }
}