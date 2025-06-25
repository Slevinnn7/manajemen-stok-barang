import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StokBarangScreen extends StatefulWidget {
  const StokBarangScreen({super.key});

  @override
  State<StokBarangScreen> createState() => _StokBarangScreenState();
}

class _StokBarangScreenState extends State<StokBarangScreen> {
  String _searchKeyword = '';
  String _filterJenis = 'semua';
  String _stokFilter = 'semua'; // Tambahan filter stok

  Map<String, int> _hitungStok(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> stok = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final nama = (data['nama_barang'] ?? '').toString().toLowerCase();
      final jumlah = int.tryParse(data['jumlah'].toString()) ?? 0;
      final jenis = (data['jenis'] ?? '').toString().toLowerCase();

      if (nama.isEmpty || jumlah == 0) continue;
      if (_filterJenis != 'semua' && jenis != _filterJenis) continue;

      if (jenis == 'masuk') {
        stok[nama] = (stok[nama] ?? 0) + jumlah;
      } else if (jenis == 'keluar') {
        stok[nama] = (stok[nama] ?? 0) - jumlah;
      }
    }

    return stok;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Stok Barang')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterJenis,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Transaksi',
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'semua', child: Text('Semua')),
                      DropdownMenuItem(value: 'masuk', child: Text('Masuk')),
                      DropdownMenuItem(value: 'keluar', child: Text('Keluar')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterJenis = value ?? 'semua');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _stokFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter Stok',
                      prefixIcon: Icon(Icons.warning),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'semua', child: Text('Semua')),
                      DropdownMenuItem(value: 'habis', child: Text('Stok Habis')),
                      DropdownMenuItem(value: 'rendah', child: Text('Stok < 3')),
                    ],
                    onChanged: (value) {
                      setState(() => _stokFilter = value ?? 'semua');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Cari Nama Barang',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _searchKeyword = value.toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transaksi')
                    .orderBy('tanggal', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Tidak ada data transaksi'));
                  }

                  final docs = snapshot.data!.docs;
                  final stok = _hitungStok(docs);

                  final filteredStok = stok.entries.where((entry) {
                    final nameMatch = entry.key.contains(_searchKeyword);
                    final stokValue = entry.value;

                    final stokMatch = _stokFilter == 'semua'
                        || (_stokFilter == 'habis' && stokValue <= 0)
                        || (_stokFilter == 'rendah' && stokValue > 0 && stokValue < 3);

                    return nameMatch && stokMatch;
                  }).toList();

                  if (filteredStok.isEmpty) {
                    return const Center(child: Text('Barang tidak ditemukan'));
                  }

                  return ListView.builder(
                    itemCount: filteredStok.length,
                    itemBuilder: (context, index) {
                      final entry = filteredStok[index];
                      final jumlah = entry.value;
                      return ListTile(
                        leading: const Icon(Icons.inventory),
                        title: Text(entry.key.toUpperCase()),
                        trailing: jumlah <= 0
                            ? const Text(
                                'Habis',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : Text(
                                '$jumlah',
                                style: TextStyle(
                                  color: jumlah < 3 ? Colors.orange : Colors.teal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
