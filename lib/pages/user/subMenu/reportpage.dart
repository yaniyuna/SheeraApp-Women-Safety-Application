import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheera/pages/user/form/report_form_page.dart';
import 'package:sheera/providers/auth_provider.dart';
import 'package:sheera/services/api_services.dart';

class Reportpage extends StatefulWidget {
  const Reportpage({super.key});

  @override
  State<Reportpage> createState() => _ReportpageState();
}

class _ReportpageState extends State<Reportpage> {
  final ApiServices _apiService = ApiServices();
  final ScrollController _scrollController = ScrollController();
  
  // State untuk data dan UI
  List<dynamic> _laporanList = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  
  // State untuk pagination
  int _currentPage = 1;
  int _lastPage = 1;

  // State untuk filter dan search
  Timer? _debounce;
  final _searchController = TextEditingController();
  int? _selectedStatusId;
  
  // Data dummy untuk dropdown status
  final Map<String, int> _statusOptions = {
    'Semua Status': 0, // Kita gunakan 0 atau null untuk "semua"
    'Baru': 1,
    'Diverifikasi': 2,
    'Ditindaklanjuti': 3,
    'Selesai': 4,
  };

  @override
  void initState() {
    super.initState();
    _fetchLaporan();

    // Listener untuk search
    _searchController.addListener(_onSearchChanged);

    // Listener untuk pagination scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isFetchingMore && _currentPage < _lastPage) {
        _fetchLaporan(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Fungsi untuk mengambil data laporan dengan parameter
  Future<void> _fetchLaporan({bool loadMore = false}) async {
    // Jika bukan load more, ini adalah request baru, reset state
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _laporanList = [];
      });
    } else {
      setState(() { _isFetchingMore = true; });
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;

    try {
      final response = await _apiService.getLaporan(
        authProvider.token!,
        page: _currentPage,
        searchQuery: _searchController.text,
        statusId: _selectedStatusId == 0 ? null : _selectedStatusId,
      );
      
      final List<dynamic> newLaporan = response['data'];
      if (mounted) {
        setState(() {
          if (loadMore) {
            _laporanList.addAll(newLaporan); // Tambahkan data baru ke list
          } else {
            _laporanList = newLaporan; // Ganti list dengan data baru
          }
          _lastPage = response['last_page']; // Update info halaman terakhir
          if (loadMore) _currentPage++; // Naikkan halaman jika load more
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchLaporan();
    });
  }

  // Fungsi untuk hapus laporan (tidak berubah)
  Future<void> _deleteLaporan(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('▶️ Memulai proses hapus untuk Laporan ID: $id');
    
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      print('Aksi hapus dibatalkan oleh pengguna.');
      return;
    }
    
    print('✅ Pengguna mengonfirmasi hapus. Mencoba memanggil API...');
    
    // Tampilkan loading indicator kecil
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menghapus laporan...')));

    try {
      await _apiService.deleteLaporan(id: id, token: authProvider.token!);
      
      print('🎉 SUKSES! API berhasil menghapus laporan.');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Sembunyikan notifikasi "Menghapus..."
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dihapus'), backgroundColor: Colors.green),
      );
      
      print('🔄 Memuat ulang daftar laporan...');
      // Panggil _fetchLaporan untuk refresh data dari awal
      _fetchLaporan();
    } catch (e) {
      print('❌ TERJADI ERROR saat menghapus!');
      print('Pesan Error Lengkap: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Laporan Saya")),
      body: Column(
        children: [
          // --- UI UNTUK SEARCH DAN FILTER ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan judul...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Dropdown
                DropdownButton<int>(
                  value: _selectedStatusId ?? 0,
                  items: _statusOptions.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.value,
                      child: Text(entry.key),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() { _selectedStatusId = value; });
                    _fetchLaporan();
                  },
                ),
              ],
            ),
          ),
          // --- KONTEN UTAMA ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _fetchLaporan(),
                    child: _laporanList.isEmpty
                        ? const Center(child: Text('Tidak ada laporan ditemukan.'))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _laporanList.length + (_isFetchingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Tampilkan loading di item terakhir jika sedang load more
                              if (index == _laporanList.length) {
                                return const Center(child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ));
                              }
                              final laporan = _laporanList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 3,
                                child: ListTile(
                                  leading: Icon(Icons.article_rounded, color: Colors.pink[300]),
                                  title: Text(laporan['judul_laporan']),
                                  subtitle: Text('Status: ${laporan['status_laporan']['nama_status']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // --- TOMBOL EDIT ---
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                        tooltip: 'Edit Laporan',
                                        onPressed: () {
                                          // TODO: Modifikasi ReportFormPage agar bisa menerima data laporan
                                          // Seperti yang kita lakukan pada ContactFormPage
                                          print('Tombol Edit untuk ID ${laporan['id']} ditekan');
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => ReportFormPage(laporan: laporan)));
                                        },
                                      ),
                                      // --- TOMBOL DELETE ---
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        tooltip: 'Hapus Laporan',
                                        onPressed: () {
                                          // Tampilkan dialog konfirmasi sebelum hapus
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Konfirmasi Hapus'),
                                              content: Text('Yakin ingin menghapus laporan "${laporan['judul_laporan']}"?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
                                                TextButton(
                                                  onPressed: (){
                                                    Navigator.of(ctx).pop();
                                                    _deleteLaporan(laporan['id']);
                                                  }, 
                                                  child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                              ],
                                            )
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportFormPage()));
          if (result == true || result == null) {
            _fetchLaporan();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}