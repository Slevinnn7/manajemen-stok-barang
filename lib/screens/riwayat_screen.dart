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
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: const Color(0xFF03A9F4), // Biru muda
      ),
      body: Stack(
        children: [
          // Background gradasi putih ke biru muda
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFB3E5FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filterJenis,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Jenis Transaksi',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
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
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Cari Nama Barang',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                            elevation: 2,
                          ),
                        ),
                        Text(
                          _startDate == null
                              ? 'Semua Tanggal'
                              : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(6),
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
                          final formattedDate =
                              DateFormat('dd MMM yyyy HH:mm').format(tanggal);
                          final isKeluar = data['jenis'] == 'keluar';

                          return Card(
                            color: Colors.white.withOpacity(0.9),
                            child: ListTile(
                              leading: Icon(
                                isKeluar ? Icons.remove : Icons.add,
                                color: isKeluar ? Colors.red : Colors.green,
                              ),
                              title: Text(data['nama_barang'] ?? '-'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Jumlah: ${data['jumlah']}'),
                                  if (isKeluar)
                                    Text('Plat Mobil: ${data['mobil'] ?? '-'}')
                                  else
                                    Text('Dicatat oleh: ${data['dicatat_oleh'] ?? '-'}'),
                                  Text('Tanggal: $formattedDate'),
                                ],
                              ),
                              trailing: Text(
                                isKeluar ? 'Keluar' : 'Masuk',
                                style: TextStyle(
                                  color: isKeluar ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
