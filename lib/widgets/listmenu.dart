import 'package:flutter/material.dart';
import 'package:sheera/pages/user/subMenu/comunity_alert_page.dart';
import 'package:sheera/pages/user/subMenu/emergencydetail.dart';
import 'package:sheera/pages/user/subMenu/fakecallpage.dart';
import 'package:sheera/pages/user/subMenu/reportpage.dart';


class ListMenu extends StatelessWidget {
  const ListMenu({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> menuItems = [
      {
        "name": "Comunity Alert",
        "icon": Icons.people,
        "color": Colors.blue,
        "route": CommunityAlertPage(),
      },
      {
        "name": "Laporkan",
        "icon": Icons.report,
        "color": Colors.red,
        "route": Reportpage(),
      },
      {
        "name": "Fake Call",
        "icon": Icons.phone,
        "color": Colors.orange,
        "route": Fakecallpage(),
      },
      {
        "name": "Lainnya",
        "icon": Icons.list_alt_outlined,
        "color": Colors.green,
        "route": Emergencydetail(),
      },
      
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Pilihan Menu",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(0.2),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), 
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.85,
            ),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              var menu = menuItems[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => menu["route"]),
                  );
                },
                child: MenuBox(
                  name: menu["name"],
                  icon: menu["icon"],
                  color: menu["color"],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


class MenuBox extends StatelessWidget {
  const MenuBox({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Gunakan ClipRRect agar konten yang di-scroll tidak "bocor" keluar dari sudut Card
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        // SOLUSI UTAMA: Bungkus konten dengan SingleChildScrollView
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Efek scroll yang lebih halus
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}