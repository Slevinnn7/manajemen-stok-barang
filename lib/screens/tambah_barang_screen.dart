import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TambahBarangScreen extends StatefulWidget {
  const TambahBarangScreen({super.key});

  @override
  State<TambahBarangScreen> createState() => _TambahBarangScreenState();
}

class _TambahBarangScreenState extends State<TambahBarangScreen> {
  final TextEditingController _namaBarangController = TextEditingController();
  bool _isLoading = false;

  Future<void> _simpanBarang() async {
    if (_namaBarangController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama barang tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('barang').add({
        'nama_barang': _namaBarangController.text.trim(),
        'created_at': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Barang berhasil ditambahkan")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dengan style modern
      appBar: AppBar(
        title: const Text(
          "Tambah Barang Baru",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 10,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Masukkan Detail Barang",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // TextField dengan icon & style lebih menarik
                    TextField(
                      controller: _namaBarangController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.edit, color: Colors.blueAccent),
                        labelText: "Nama Barang",
                        hintText: "Contoh: Ban Truk",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Tombol simpan lebih terlihat (warna hijau terang)
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _simpanBarang,
                              icon: const Icon(Icons.check_circle_outline, size: 22),
                              label: const Text(
                                "Simpan Barang",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent.shade700, // ✅ lebih terlihat
                                foregroundColor: Colors.white, // teks & ikon putih
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 6, // bayangan biar lebih timbul
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
