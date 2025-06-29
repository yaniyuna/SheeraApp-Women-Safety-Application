import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:sheera/models/laporan.dart';
import 'package:sheera/pages/admin/admin_report_detail_page.dart';
import 'package:sheera/providers/auth_provider.dart';
import 'package:sheera/services/api_services.dart';


class AdminReportListPage extends StatefulWidget {
  const AdminReportListPage({super.key});

  @override
  State<AdminReportListPage> createState() => _AdminReportListPageState();
}

class _AdminReportListPageState extends State<AdminReportListPage> {
  final ApiServices _apiService = ApiServices();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _laporanList = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;

  // State untuk filter dan search
  Timer? _debounce;
  final _searchController = TextEditingController();
  int? _selectedStatusId;

  // Opsi dropdown untuk admin
  final Map<String, int?> _statusOptions = {
    'Semua Status': null,
    'Baru': 1,
    'Diverifikasi': 2,
    'Ditindaklanjuti': 3,
    'Selesai': 4,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAdminReports();
    });
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore && _currentPage < _lastPage) {
      _fetchAdminReports(loadMore: true);
    }
  }

  // Fungsi untuk mengambil laporan, sekarang dengan parameter
  Future<void> _fetchAdminReports({bool loadMore = false}) async {
    if (loadMore && _isFetchingMore) return;

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
    if (authProvider.token == null) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final response = await _apiService.getLaporan(
        authProvider.token!,
        page: _currentPage,
        searchQuery: _searchController.text,
        statusId: _selectedStatusId,
      );
      
      final List<dynamic> newLaporan = response['data'] ?? [];
      final int lastPageFromApi = response['last_page'] ?? 1;

      if (mounted) {
        setState(() {
          _lastPage = lastPageFromApi;
          if (loadMore) {
            _laporanList.addAll(newLaporan);
            _currentPage++;
          } else {
            _laporanList = newLaporan;
            if (_laporanList.isNotEmpty && _lastPage > 1) {
              _currentPage = 2; 
            }
          }
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  // Fungsi untuk search dengan jeda
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      _fetchAdminReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan judul...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<int?>(
                    value: _selectedStatusId,
                    hint: const Text('Status'),
                    underline: const SizedBox(),
                    isDense: true,
                    items: _statusOptions.entries.map((entry) {
                      return DropdownMenuItem<int?>(
                        value: entry.value,
                        child: Text(entry.key),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() { _selectedStatusId = value; });
                      _fetchAdminReports();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _fetchAdminReports(),
                    child: _laporanList.isEmpty
                        ? const Center(child: Text('Tidak ada laporan ditemukan.'))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _laporanList.length + (_isFetchingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _laporanList.length) {
                                return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                              }
                              final laporan = _laporanList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(laporan['user']?['nama_lengkap']?.substring(0, 1) ?? '?'),
                                  ),
                                  title: Text(laporan['judul_laporan'] ?? 'Tanpa Judul'),
                                  subtitle: Text('Pelapor: ${laporan['user']?['nama_lengkap']}\nStatus: ${laporan['status_laporan']?['nama_status'] ?? 'N/A'}'),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    final bool? hasChanged = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AdminReportDetailPage(laporan: laporan)),
                                    );
                                    if (hasChanged == true) {
                                      _fetchAdminReports();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
