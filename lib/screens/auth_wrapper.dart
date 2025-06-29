import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheera/pages/admin/admin_home_page.dart';
import 'package:sheera/pages/login/login_page.dart';
import 'package:sheera/pages/user/mainMenu/main_page.dart';
import 'package:sheera/providers/auth_provider.dart';


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Tampilkan loading spinner mengecek auto-login
    if (authProvider.isLoading && !authProvider.isAuthenticated) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.isAuthenticated) {
      if (authProvider.isAdmin) {
        // Jika admin, arahkan ke halaman utama admin
        return const AdminHomePage();
      } else {
        // Jika user biasa, arahkan ke halaman utama user
        return const MainPage(); 
      }
    } 
    
    if (authProvider.isAuthenticated) {
      // Jika login berhasil, tampilkan MainPage
      return const MainPage();
    } else {
      // Jika tidak, tampilkan halaman login
      return const LoginPage();
    }
  }
}