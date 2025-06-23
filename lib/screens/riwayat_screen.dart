import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  String _filterJenis = 'semua';
  String _searchNama = '';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  bool _filterData(Map<String, dynamic> data) {
    final nama = (data['nama_barang'] ?? '').toString().toLowerCase();
    final jenis = data['jenis'] ?? '';
    final tanggal = (data['tanggal'] as Timestamp).toDate();

    final matchJenis = _filterJenis == 'semua' || jenis == _filterJenis;
    final matchNama = nama.contains(_searchNama.toLowerCase());
    final matchTanggal = (_startDate == null || tanggal.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
        (_endDate == null || tanggal.isBefore(_endDate!.add(const Duration(days: 1))));

    return matchJenis && matchNama && matchTanggal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _filterJenis,
                        items: const [
                          DropdownMenuItem(value: 'semua', child: Text('Semua')),
                          DropdownMenuItem(value: 'masuk', child: Text('Masuk')),
                          DropdownMenuItem(value: 'keluar', child: Text('Keluar')),
                        ],
                        onChanged: (value) => setState(() => _filterJenis = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Cari Nama Barang'),
                        onChanged: (value) => setState(() => _searchNama = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _selectDateRange(context),
                      icon: const Icon(Icons.date_range),
                      label: const Text('Filter Tanggal'),
                    ),
                    Text(_startDate == null
                        ? 'Semua Tanggal'
                        : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transaksi')
                  .orderBy('tanggal', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada transaksi'));
                }

                final transaksi = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .where(_filterData)
                    .toList();

                if (transaksi.isEmpty) {
                  return const Center(child: Text('Tidak ada data yang cocok'));
                }

                return ListView.builder(
                  itemCount: transaksi.length,
                  itemBuilder: (context, index) {
                    final data = transaksi[index];
                    final tanggal = (data['tanggal'] as Timestamp).toDate();
                    final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(tanggal);

                    return ListTile(
                      leading: Icon(
                        data['jenis'] == 'masuk' ? Icons.add : Icons.remove,
                        color: data['jenis'] == 'masuk' ? Colors.green : Colors.red,
                      ),
                      title: Text(data['nama_barang'] ?? '-'),
                      subtitle: Text('Jumlah: ${data['jumlah']}  •  Tanggal: $formattedDate'),
                      trailing: Text(
                        data['jenis'] == 'masuk' ? 'Masuk' : 'Keluar',
                        style: TextStyle(
                          color: data['jenis'] == 'masuk' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
