import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_helper.dart';

class AkunScreen extends StatefulWidget {
  const AkunScreen({super.key});

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  String? userId;
  String? userRole;
  String? userJabatan;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final session = await SessionHelper.getUser();
    setState(() {
      userId = session['uid'];
      userRole = session['role'];
      userJabatan = session['jabatan'];
    });
  }

  Future<void> _ubahPassword(String uid, String newPassword) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'password': newPassword,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password berhasil diubah')),
    );

    _passwordController.clear(); // Reset password setelah berhasil
  }

  Future<void> _hapusAkun(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Akun berhasil dihapus')),
    );
  }

  Widget _buildAdminView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final uid = users[index].id;
            final isNonAdmin = data['role'] != 'admin';

            return ListTile(
              title: Text(data['email'] ?? 'Tanpa Email'),
              subtitle: Text('Role: ${data['role']}Jabatan: ${data['jabatan']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.lock_open),
                    onPressed: () => _showUbahPasswordDialog(uid),
                  ),
                  if (isNonAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _hapusAkun(uid),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUbahPasswordDialog(String uid) {
    final tempController = TextEditingController();
    bool obscureLocal = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Ubah Password'),
          content: TextField(
            controller: tempController,
            obscureText: obscureLocal,
            decoration: InputDecoration(
              labelText: 'Password Baru',
              suffixIcon: IconButton(
                icon: Icon(
                  obscureLocal ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setStateDialog(() => obscureLocal = !obscureLocal),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final pass = tempController.text.trim();
                if (pass.isNotEmpty) {
                  _ubahPassword(uid, pass);
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jabatan: ${userJabatan ?? '-'}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          const Text('Ubah Password Anda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password Baru',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final pass = _passwordController.text.trim();
              if (pass.isNotEmpty && userId != null) {
                _ubahPassword(userId!, pass);
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun Saya')),
      body: userRole == null
          ? const Center(child: CircularProgressIndicator())
          : userRole == 'admin'
              ? _buildAdminView()
              : _buildUserView(),
    );
  }
}
