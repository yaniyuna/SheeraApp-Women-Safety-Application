import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage('assets/appimages/han.png'),
        ),
        const SizedBox(height: 10),
        const Text(
          "Han Sheng",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Text(
          "No HP. +6281XXXXX",
          style: TextStyle(fontSize: 14, color: Colors.red),
        ),
        const Text(
          "Perguruan Tianxi, kota Yunan",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
