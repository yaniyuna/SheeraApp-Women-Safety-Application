import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheera/pages/user/subMenu/fake_incoming_call_screen.dart';
import 'package:sheera/providers/auth_provider.dart';
import 'package:sheera/services/api_services.dart';

class Fakecallpage extends StatefulWidget {
  const Fakecallpage({super.key});

  @override
  State<Fakecallpage> createState() => _FakecallpageState();
}

class _FakecallpageState extends State<Fakecallpage> {
  final ApiServices _apiService = ApiServices();

  // State baru untuk menampung data dari API
  bool _isLoading = true;
  List<dynamic> _skenarioList = [];
  Map<String, dynamic>? _selectedSkenario;

  @override
  void initState() {
    super.initState();
    // Ambil data skenario saat halaman pertama kali dibuka
    _fetchSkenarios();
  }

  // Fungsi untuk mengambil data skenario dari API
  Future<void> _fetchSkenarios() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      final data = await _apiService.getSkenarios(authProvider.token!);
      setState(() {
        _skenarioList = data;
        // Set pilihan default ke item pertama jika list tidak kosong
        if (_skenarioList.isNotEmpty) {
          _selectedSkenario = _skenarioList[0];
        }
        _isLoading = false;
      });
    } else {
      setState(() { _isLoading = false; });
    }
  }

  // Fungsi untuk memicu panggilan palsu
  Future<void> _triggerFakeCall() async {
    if (_selectedSkenario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih skenario panggilan terlebih dahulu.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Panggilan palsu akan dimulai dalam 10 detik...')),
    );

    await Future.delayed(const Duration(seconds: 10));

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => FakeIncomingCallScreen(
            callerName: _selectedSkenario!['nama_penelepon'],
            callerNumber: _selectedSkenario!['judul_skenario'],
            // Kirim URL audio dari skenario yang dipilih
            audioUrl: _selectedSkenario!['audio_url'], 
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.support_agent, size: 80, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Panggilan Palsu Terjadwal',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih skenario untuk keluar dari situasi yang tidak nyaman.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  
                  if (_skenarioList.isNotEmpty)
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedSkenario,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Skenario Panggilan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.list_alt_rounded),
                      ),
                      items: _skenarioList.map((skenario) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: skenario,
                          child: Text(skenario['judul_skenario']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSkenario = value;
                        });
                      },
                    )
                  else
                    const Center(child: Text('Tidak ada skenario tersedia.')),
                  
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _triggerFakeCall,
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Mulai Panggilan dalam 10 Detik'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}