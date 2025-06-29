import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheera/pages/user/form/report_form_page.dart';
import 'package:sheera/providers/auth_provider.dart';
import 'package:sheera/services/sync_service.dart';
import 'package:sheera/helpers/dbhelper.dart';
import 'package:sheera/models/laporan.dart';

class Reportpage extends StatefulWidget {
  const Reportpage({super.key});

  @override
  State<Reportpage> createState() => _ReportpageState();
}

class _ReportpageState extends State<Reportpage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();

  List<Laporan> _laporanList = [];
  bool _isLoading = true;

  Timer? _debounce;
  final _searchController = TextEditingController();

  String _searchQuery = '';
  int? _selectedStatusId;

  final Map<String, int> _statusOptions = {
    'Semua Status': 0,
    'Baru': 1,
    'Diverifikasi': 2,
    'Ditindaklanjuti': 3,
    'Selesai': 4,
  };

  @override
  void initState() {
    super.initState();
    _refreshData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _refreshData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() { _isLoading = true; });
    }

    await _loadFromLocalDB();

    if (showLoading && mounted) {
      setState(() { _isLoading = false; });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token != null) {
        await _syncService.syncData(authProvider.token!);
        await _loadFromLocalDB();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync Error: ${e.toString()}")));
      }
    }
  }
  
  Future<void> _loadFromLocalDB() async {
    final data = await _dbHelper.getLaporanList();
    if (mounted) {
      setState(() {
        _laporanList = data.map((item) => Laporan.fromDbMap(item)).toList();
      });
    }
  }
  
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  Future<void> _deleteLaporan(Laporan laporan) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus laporan "${laporan.judulLaporan}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _dbHelper.markLaporanForDeletion(laporan.id!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan ditandai untuk dihapus.'), backgroundColor: Colors.orange),
      );
      
      await _loadFromLocalDB();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token != null) {
        _syncService.syncData(authProvider.token!); 
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final List<Laporan> filteredList = _laporanList.where((laporan) {
      final titleMatches = laporan.judulLaporan.toLowerCase().contains(_searchQuery.toLowerCase());
      final statusMatches = _selectedStatusId == null || _selectedStatusId == 0 
                              ? true // Jika 'Semua Status' dipilih, loloskan semua
                              : laporan.statusLaporanId == _selectedStatusId;

      return titleMatches && statusMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Laporan Saya")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
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
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _refreshData(),
                    child: filteredList.isEmpty
                        ? const Center(child: Text('Tidak ada laporan ditemukan.'))
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final laporan = filteredList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 3,
                                child: ListTile(
                                  leading: Icon(
                                      laporan.isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded, 
                                      color: laporan.isSynced ? Colors.green : Colors.orange),
                                  title: Text(laporan.judulLaporan),
                                  subtitle: Text('Status: ${laporan.statusNama}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => ReportFormPage(laporan: laporan)));
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteLaporan(laporan),
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
            _refreshData(showLoading: false);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}