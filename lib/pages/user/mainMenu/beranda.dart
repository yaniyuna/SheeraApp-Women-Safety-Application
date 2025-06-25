import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- 1. Tambahkan import ini
import 'package:sheera/providers/auth_provider.dart'; // <-- 2. Tambahkan import ini (ganti 'sheera' jika perlu)
import '../../../widgets/carouselnews.dart';
import '../../../widgets/learnmore.dart';
import '../../../widgets/listmenu.dart';
//import 'package:sheera/widgets/quickmenu.dart'; // Ganti "your_project" dengan nama proyek Anda

class Beranda extends StatefulWidget {
  //const Beranda({super.key});
  @override
  _BerandaState createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  @override
  Widget build(BuildContext context) {
    // 3. Ambil data user yang sedang login dari AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        //backgroundColor: const Color.fromARGB(255, 197, 164, 219),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Beranda'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              print('Click start');
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_active),
            onPressed: () {
              print('Click start');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              // 4. Gunakan data user yang dinamis
              accountName: Text(user?['nama_lengkap'] ?? 'Nama Pengguna'),
              accountEmail: Text(user?['email'] ?? 'email@pengguna.com'),
              currentAccountPicture: GestureDetector(
                onTap: () {},
                child: CircleAvatar(
                  // Ganti dengan gambar profil dari user jika ada, atau gunakan default
                  backgroundColor: Colors.white,
                  child: Text(
                    user?['nama_lengkap']?.substring(0, 1) ?? 'P', // Ambil huruf pertama dari nama
                    style: TextStyle(fontSize: 40.0, color: Colors.pink),
                  ),
                ),
              ),
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/appimages/bg.jpg'),
                    fit: BoxFit.cover),
              ),
            ),
            ListTile(
              title: Text('Notification'),
              trailing: Icon(Icons.notifications_none),
            ),
            ListTile(
              title: Text('Setting'),
              trailing: Icon(Icons.settings),
            ),
            // 5. Tambahkan Divider dan Tombol Logout di sini
            const Divider(), // Garis pemisah
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Tampilkan dialog konfirmasi sebelum logout
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          title: const Text('Konfirmasi Logout'),
                          content: const Text('Apakah Anda yakin ingin keluar?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Batal'),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                            ),
                            TextButton(
                              child: Text('Ya, Keluar', style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                // Tutup dialog
                                Navigator.of(ctx).pop();
                                // Panggil fungsi logout
                                authProvider.logout();
                                // AuthWrapper akan otomatis mengarahkan ke halaman login
                              },
                            )
                          ],
                        ));
              },
            ),
          ],
        ),
      ),
      
      body: Column(
        children: <Widget>[
          CarouselNews(),
          Expanded(
              child: Column(
            children: <Widget>[
              Expanded(child: ListMenu()),
              Learnmore(),
            ],
          )),
        ],
      ),
    );
  }
}