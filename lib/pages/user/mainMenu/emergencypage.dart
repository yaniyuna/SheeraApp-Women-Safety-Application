import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheera/pages/user/form/contact_form_page.dart';
import 'package:sheera/providers/auth_provider.dart';
import 'package:sheera/services/api_services.dart'; 
import 'package:url_launcher/url_launcher.dart';

class Emergencypage extends StatefulWidget {
  const Emergencypage({super.key});

  @override
  State<Emergencypage> createState() => _EmergencypageState();
}

class _EmergencypageState extends State<Emergencypage> {
  final ApiServices _apiService = ApiServices();
  List<dynamic> _kontakList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Panggil data saat halaman pertama kali dibuka
    _fetchKontakDarurat();
  }

  // Fungsi untuk mengambil data kontak dari API
  Future<void> _fetchKontakDarurat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      final data = await _apiService.getKontak(authProvider.token!);
      setState(() {
        _kontakList = data;
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk melakukan panggilan telepon
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa melakukan panggilan ke $phoneNumber')),
      );
    }
  }

  // Fungsi untuk mengirim SMS
  Future<void> _sendSms(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': 'Tolong! Saya dalam keadaan darurat.',
      },
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _kontakList.isEmpty
              ? _buildEmptyState()
              : _buildContactView(),
    );
  }

  // Tampilan jika kontak darurat kosong
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.contact_emergency_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Anda belum menambahkan kontak darurat.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactFormPage()),
              );
              if (result == true) {
                _fetchKontakDarurat();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Kontak Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          )
        ],
      ),
    );
  }

    // Tampilan jika kontak darurat ada
    Widget _buildContactView() {
    // Ambil kontak pertama sebagai kontak utama
    final primaryContact = _kontakList[0];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Future<void> _deleteContact() async {
      // Tampilkan dialog konfirmasi
      final bool? shouldDelete = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus kontak "${primaryContact['nama_kontak']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Ya, Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      // Jika user menekan "Ya, Hapus"
      if (shouldDelete == true) {
        try {
          await _apiService.deleteKontak(
            id: primaryContact['id'],
            token: authProvider.token!,
          );
          // Refresh daftar kontak setelah berhasil dihapus
          _fetchKontakDarurat();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bagian Profile Header (Avatar, Nama, No HP)
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://i.pinimg.com/736x/45/e3/bf/45e3bf50f043e1d94870afc2d2972251.jpg'),
          ),
          const SizedBox(height: 16),
          Text(
            primaryContact['nama_kontak'],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'No HP. ${primaryContact['nomor_telepon']}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Bagian Tombol Call
          const Text(
            'Notifikasi Darurat!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tekan "CALL" untuk menghubungi nomor darurat!',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _makePhoneCall(primaryContact['nomor_telepon']),
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.red.withOpacity(0.3), spreadRadius: 8, blurRadius: 10),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call, color: Colors.white, size: 50),
                  Text('CALL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bagian Tombol SMS
          const Text(
            'Pesan SMS lokasi GPS anda akan terkirim ke kontak darurat',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          TextButton(
            onPressed: () => _sendSms(primaryContact['nomor_telepon']),
            child: const Text('Kirim SMS Manual'),
          ),

          
          const Divider(height: 30, indent: 20, endIndent: 20, thickness: 1),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Tombol Edit Kontak
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Kirim data kontak yang ingin diedit melalui constructor
                      builder: (context) => ContactFormPage(contact: primaryContact),
                    ),
                  );
                  // Jika halaman edit mengembalikan 'true', refresh data
                  if (result == true) {
                    _fetchKontakDarurat();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),

              // Tombol Hapus Kontak
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
                onPressed: _deleteContact, // Panggil fungsi hapus
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}