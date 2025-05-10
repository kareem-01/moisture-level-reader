import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final List<String> names = [
    'Ahmed Mohamed Ahmed Gaber (App developer)',
    'Hassan Mohamed Hassan',
    'Eyad Mohamed Noby',
    'Ahmed Mohamed Ahmed Abdelrahim',
    'Saif Eldin Ramadan Fawzy(App developer)',
    'Shahd Abdallah Mohamed',
    'Alaa Mohamed Mohsen',
    'Bassant Mohamed Ahmed',
    'Suhaila Mohamed Abdelmageed',
    'Zeina Emad Mabrok',
    'Nourhan Alaa Ahmed',
    'Sandy Ibrahim Abdellatif Zain Eldin',
    'Habiba Hany Ali',
    'Raja Khaled Mahmoud',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        spacing: 16.0,
        children: [
          Text('Team Members:'),
          Expanded(
            child: ListView.builder(
              itemCount: names.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2.0,
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: ListTile(
                    title: Text(
                      names[index],
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
