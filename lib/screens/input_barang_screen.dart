import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InputBarangScreen extends StatefulWidget {
  const InputBarangScreen({super.key});

  @override
  State<InputBarangScreen> createState() => _InputBarangScreenState();
}

class _InputBarangScreenState extends State<InputBarangScreen> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  String _jenis = 'masuk';
  String _status = '';

  Future<void> _simpanTransaksi() async {
    final nama = _namaBarangController.text.trim();
    final jumlah = int.tryParse(_jumlahController.text.trim()) ?? 0;

    if (nama.isEmpty || jumlah <= 0) {
      setState(() => _status = 'Nama dan jumlah harus diisi dengan benar');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('transaksi').add({
        'nama_barang': nama,
        'jumlah': jumlah,
        'jenis': _jenis,
        'tanggal': Timestamp.now(),
      });

      setState(() => _status = 'Transaksi $_jenis berhasil disimpan');
      _namaBarangController.clear();
      _jumlahController.clear();
    } catch (e) {
      setState(() => _status = 'Gagal menyimpan data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Barang')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jenis Transaksi:', style: TextStyle(fontSize: 16)),
            DropdownButton<String>(
              value: _jenis,
              items: const [
                DropdownMenuItem(value: 'masuk', child: Text('Barang Masuk')),
                DropdownMenuItem(value: 'keluar', child: Text('Barang Keluar')),
              ],
              onChanged: (value) => setState(() => _jenis = value!),
            ),
            TextField(
              controller: _namaBarangController,
              decoration: const InputDecoration(labelText: 'Nama Barang'),
            ),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _simpanTransaksi,
              child: const Text('Simpan'),
            ),
            const SizedBox(height: 10),
            Text(
              _status,
              style: TextStyle(
                color: _status.contains('berhasil')
                    ? Colors.green
                    : Colors.red,
              ),
            )
          ],
        ),
      ),
    );
  }
}
