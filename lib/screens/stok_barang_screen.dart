import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StokBarangScreen extends StatelessWidget {
  const StokBarangScreen({super.key});

  Future<Map<String, int>> _hitungStok() async {
    final snapshot = await FirebaseFirestore.instance.collection('transaksi').get();
    final Map<String, int> stok = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final nama = data['nama_barang'] as String;
      final jumlah = data['jumlah'] as int;
      final jenis = data['jenis'] as String;

      stok[nama] = (stok[nama] ?? 0) + (jenis == 'masuk' ? jumlah : -jumlah);
    }

    return stok;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Stok Barang')),
      body: FutureBuilder<Map<String, int>>(
        future: _hitungStok(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada data stok'));
          }

          final stok = snapshot.data!;

          return ListView(
            children: stok.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                trailing: Text('Stok: ${entry.value}'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
