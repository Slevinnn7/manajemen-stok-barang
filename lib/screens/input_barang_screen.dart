import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_helper.dart';

class InputBarangScreen extends StatefulWidget {
  const InputBarangScreen({super.key});

  @override
  State<InputBarangScreen> createState() => _InputBarangScreenState();
}

class _InputBarangScreenState extends State<InputBarangScreen> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  String _jenis = 'masuk';
  String? _userJabatan;
  String _status = '';
  List<String> _daftarNamaBarang = [];

  @override
  void initState() {
    super.initState();
    _loadUserJabatan();
    _loadNamaBarang();
  }

  Future<void> _loadUserJabatan() async {
    final session = await SessionHelper.getUser();
    setState(() => _userJabatan = session['jabatan']);
  }

  Future<void> _loadNamaBarang() async {
    final snapshot = await FirebaseFirestore.instance.collection('transaksi').get();
    final namaSet = <String>{};
    for (var doc in snapshot.docs) {
      final nama = doc['nama_barang']?.toString().trim();
      if (nama != null && nama.isNotEmpty) {
        namaSet.add(nama);
      }
    }
    setState(() => _daftarNamaBarang = namaSet.toList());
  }

  Future<int> _getStokSaatIni(String namaBarang) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('transaksi')
        .where('nama_barang', isEqualTo: namaBarang)
        .get();

    int totalStok = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['jenis'] == 'masuk') {
        totalStok += (data['jumlah'] ?? 0) as int;
      } else if (data['jenis'] == 'keluar') {
        totalStok -= (data['jumlah'] ?? 0) as int;
      }
    }
    return totalStok;
  }

  Future<void> _simpanTransaksi() async {
    final nama = _namaBarangController.text.trim();
    final jumlah = int.tryParse(_jumlahController.text.trim()) ?? 0;

    if (nama.isEmpty || jumlah <= 0) {
      setState(() => _status = 'Nama dan jumlah harus diisi dengan benar');
      return;
    }

    if (_jenis == 'keluar') {
      final stokSaatIni = await _getStokSaatIni(nama);
      if (jumlah > stokSaatIni) {
        setState(() => _status = 'Persediaan barang tidak cukup');
        return;
      }
    }

    final jenisLabel = _jenis == 'masuk' ? 'Barang Masuk' : 'Barang Keluar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(
          'Apakah Anda yakin ingin menyimpan $jenisLabel "$nama" sejumlah $jumlah?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('transaksi').add({
        'nama_barang': nama,
        'jumlah': jumlah,
        'jenis': _jenis,
        'tanggal': Timestamp.now(),
        'dicatat_oleh': _userJabatan ?? '-',
      });

      if (!mounted) return;

      setState(() {
        _status = 'Transaksi $_jenis berhasil disimpan';
        _namaBarangController.clear();
        _jumlahController.clear();
        _jenis = 'masuk';
      });
    } catch (e) {
      if (!mounted) return;
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
            const SizedBox(height: 10),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _daftarNamaBarang.where((nama) =>
                    nama.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _namaBarangController.text = selection;
              },
              fieldViewBuilder: (context, _, focusNode, onEditingComplete) {
                return TextField(
                  controller: _namaBarangController,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: const InputDecoration(labelText: 'Nama Barang'),
                );
              },
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
                color: _status.contains('berhasil') ? Colors.green : Colors.red,
              ),
            )
          ],
        ),
      ),
    );
  }
}
