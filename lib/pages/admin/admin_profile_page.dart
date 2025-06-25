import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheera/providers/auth_provider.dart'; // Sesuaikan path jika perlu

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data user yang sedang login dari AuthProvider
    // Kita gunakan watch agar UI ikut update jika ada perubahan di masa depan
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Tampilan jika karena suatu hal data user tidak ada
    if (user == null) {
      return const Center(child: Text('Data admin tidak ditemukan.'));
    }

    return Scaffold(
      // Kita tidak perlu AppBar di sini karena sudah ada di AdminHomePage
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Bagian Header Profil
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.pink[400],
                    child: Text(
                      user['nama_lengkap']?.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user['nama_lengkap'] ?? 'Nama Admin',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(
                      user['role']?.toUpperCase() ?? 'ADMIN',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bagian Detail Informasi
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: user['email'] ?? 'Tidak ada email',
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildInfoTile(
                  icon: Icons.phone_outlined,
                  title: 'Nomor Telepon',
                  subtitle: user['nomor_telepon'] ?? 'Tidak ada nomor telepon',
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Tombol Logout
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('LOGOUT'),
            onPressed: () {
              // Tampilkan dialog konfirmasi sebelum logout
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Apakah Anda yakin ingin keluar dari sesi admin?'),
                  actions: [
                    TextButton(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text('Ya, Logout', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        // Tutup dialog, lalu panggil fungsi logout dari provider
                        Navigator.of(ctx).pop();
                        authProvider.logout();
                      },
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk membuat ListTile yang rapi
  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
    );
  }
}
