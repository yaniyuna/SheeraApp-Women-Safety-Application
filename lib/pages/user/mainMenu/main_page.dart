import 'package:flutter/material.dart';

// Sesuaikan path import ini dengan struktur proyek Anda
import 'package:sheera/pages/user/mainMenu/beranda.dart' as beranda;
import 'package:sheera/pages/user/mainMenu/mappage.dart' as mappage;
import 'package:sheera/pages/user/mainMenu/emergencypage.dart' as emergencypage;


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _controller,
        children: <Widget>[
          beranda.Beranda(), // Halaman Beranda sekarang berada di bawah Provider
          emergencypage.Emergencypage(),
          mappage.Mappage(),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.pink[50],
        child: TabBar(
          controller: _controller,
          indicatorColor: Colors.pink,
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.home), text: "Beranda"),
            Tab(icon: Icon(Icons.emergency_share), text: "Darurat"),
            Tab(icon: Icon(Icons.map), text: "Peta"),
          ],
        ),
      ),
    );
  }
}