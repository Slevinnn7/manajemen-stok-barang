import 'package:flutter/material.dart';
import 'input_barang_screen.dart';
import 'stok_barang_screen.dart';
import 'riwayat_screen.dart';
import 'akun_screen.dart';
import '../services/session_helper.dart';
import 'login_screen.dart';
import 'tambah_barang_screen.dart';
import 'tambah_plat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _role = '';
  String _jabatan = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final role = await SessionHelper.getRole() ?? '';
    final jabatan = await SessionHelper.getJabatan() ?? '';
    setState(() {
      _role = role;
      _jabatan = jabatan;
    });
  }

  void _logout() async {
    await SessionHelper.clearUser();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  bool get isAdmin => _role == 'admin';
  bool get isKepalaGudang => _jabatan == 'Kepala Gudang';
  bool get isStaffGudang => _jabatan == 'Staff Gudang';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF03A9F4),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFB3E5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              if (isAdmin || isKepalaGudang)
                _buildMenuCard(
                  context,
                  'Input Barang',
                  Icons.add_box,
                  const InputBarangScreen(),
                ),

              _buildMenuCard(
                context,
                'Lihat Stok',
                Icons.inventory,
                const StokBarangScreen(),
              ),

              if (isAdmin || isKepalaGudang)
                _buildMenuCard(
                  context,
                  'Riwayat',
                  Icons.history,
                  const RiwayatScreen(),
                ),

              _buildMenuCard(
                context,
                'Akun',
                Icons.person,
                const AkunScreen(),
              ),

              if (isAdmin || isKepalaGudang)
                _buildMenuCard(
                  context,
                  'Tambah Barang Baru',
                  Icons.add_circle,
                  const TambahBarangScreen(),
                ),
              if (isAdmin || isKepalaGudang)
                _buildMenuCard(
                  context,
                  'Tambah Plat Mobil',
                  Icons.directions_car,
                  const TambahPlatScreen(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, String title, IconData icon, Widget screen) {
    return Card(
      elevation: 6,
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.teal),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
