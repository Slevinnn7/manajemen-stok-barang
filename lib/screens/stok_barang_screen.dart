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
  String _stokFilter = 'semua';

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

  void _showKeteranganWarna() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keterangan Warna Stok'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.green),
              title: Text('Stok Cukup'),
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.orange),
              title: Text('Stok Menipis (< 3)'),
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.red),
              title: Text('Stok Habis'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Stok Barang'),
        backgroundColor: const Color(0xFF03A9F4), 
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFB3E5FC)], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterJenis,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Jenis Transaksi',
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.filter_list, color: Colors.black),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Filter Stok',
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.warning, color: Colors.black),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 21.0, horizontal: 12.0),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Cari Nama Barang',
                    labelStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.black),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                  ),
                  style: const TextStyle(color: Colors.black),
                  onChanged: (value) => setState(() => _searchKeyword = value.toLowerCase()),
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

                        final stokMatch = _stokFilter == 'semua' ||
                            (_stokFilter == 'habis' && stokValue <= 0) ||
                            (_stokFilter == 'rendah' && stokValue > 0 && stokValue < 3);

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
                          return Card(
                            color: Colors.white.withOpacity(0.9),
                            child: ListTile(
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showKeteranganWarna,
        tooltip: 'Keterangan Warna Stok',
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.info_outline),
      ),
    );
  }
}
