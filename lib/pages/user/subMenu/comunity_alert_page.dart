import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sheera/pages/user/subMenu/report_detail_page.dart';
import 'package:sheera/providers/auth_provider.dart';
import 'package:sheera/services/api_services.dart';

class CommunityAlertPage extends StatefulWidget {
  const CommunityAlertPage({super.key});

  @override
  State<CommunityAlertPage> createState() => _CommunityAlertPageState();
}

class _CommunityAlertPageState extends State<CommunityAlertPage> {
  final ApiServices _apiService = ApiServices();
  List<dynamic> _alertList = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _fetchDataForRole();
  }

  Future<void> _fetchDataForRole() async {
    setState(() { _isLoading = true; });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    try {
      Map<String, dynamic> response;
      // Cek role dari pengguna yang sedang login
      if (authProvider.isAdmin) {
        // Jika ADMIN, panggil endpoint laporan biasa untuk melihat semua laporan
        print("Fetching data as ADMIN");
        response = await _apiService.getLaporan(authProvider.token!);
      } else {
        // Jika USER BIASA, panggil endpoint community alert
        print("Fetching data as USER for community alerts");
        response = await _apiService.getCommunityAlerts(authProvider.token!);
      }
      
      if (mounted) {
        setState(() {
          _alertList = response['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      // ... (penanganan error)
       if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil info role untuk menyesuaikan judul
    bool isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Panel Laporan Admin' : 'Community Alert'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDataForRole,
              child: _alertList.isEmpty
                  ? const Center(child: Text('Tidak ada data untuk ditampilkan.'))
                  : ListView.builder(
                      itemCount: _alertList.length,
                      itemBuilder: (context, index) {
                        final alert = _alertList[index];
                        // Parsing tanggal agar bisa diformat
                        final waktuKejadian = DateTime.parse(alert['waktu_kejadian']);
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 3,
                          clipBehavior: Clip.antiAlias, // Agar sudutnya rapi
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Baris Judul Laporan
                                Text(
                                  alert['judul_laporan'] ?? 'Tanpa Judul',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                
                                // Baris Tanggal Kejadian
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('d MMMM yyyy, HH:mm').format(waktuKejadian),
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Baris Tombol Aksi
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.visibility_outlined, size: 18),
                                    label: const Text('Lihat Detail'),
                                    onPressed: () {
                                      // Navigasi ke halaman detail sambil mengirim data laporan
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReportDetailPage(laporan: alert),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pink[50],
                                      foregroundColor: Colors.pink[800],
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}