import 'package:flutter/material.dart';
import 'input_barang_screen.dart';
import 'stok_barang_screen.dart';
import 'riwayat_screen.dart';
import 'akun_screen.dart';
import '../services/session_helper.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _logout(BuildContext context) async {
    await SessionHelper.clearUser();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(context, 'Input Barang', Icons.add_box,
                const InputBarangScreen()),
            _buildMenuCard(context, 'Lihat Stok', Icons.inventory,
                const StokBarangScreen()),
            _buildMenuCard(context, 'Riwayat', Icons.history,
                const RiwayatScreen()),
            _buildMenuCard(context, 'Akun', Icons.person,
                const AkunScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, String title, IconData icon, Widget screen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.teal),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16))
            ],
          ),
        ),
      ),
    );
  }
}