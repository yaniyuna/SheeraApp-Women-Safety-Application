import 'package:flutter/material.dart';
import '../../../widgets/feature_tile.dart';

class Emergencydetail extends StatelessWidget {
  const Emergencydetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EMERGENCY DETAILS"),
        backgroundColor: Colors.pink,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          FeatureTile(
            icon: Icons.chat,
            title: "Chatbox",
            description: "AI akan membantumu dalam menjaga ketenangan saat kondisi darurat",
          ),
          FeatureTile(
            icon: Icons.mic,
            title: "Rekaman Darurat",
            description: "Nyalakan rekaman darurat apabila anda merasa terancam",
          ),
          FeatureTile(
            icon: Icons.phone_forwarded,
            title: "Panggilan Palsu",
            description: "Lakukan panggilan palsu untuk pengelabuhi pelaku",
          ),
        ],
      ),
    );
  }
}
