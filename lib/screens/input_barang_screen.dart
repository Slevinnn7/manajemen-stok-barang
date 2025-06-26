import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_helper.dart';

class InputBarangScreen extends StatefulWidget {
  const InputBarangScreen({super.key});

  @override
  State<InputBarangScreen> createState() => _InputBarangScreenState();
}

class _InputBarangScreenState extends State<InputBarangScreen> {
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _namaPengambilController = TextEditingController();
  final TextEditingController _namaMobilController = TextEditingController();

  String _jenis = 'masuk';
  String? _userJabatan;
  String? _selectedBarang;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _loadUserJabatan();
  }

  Future<void> _loadUserJabatan() async {
    final session = await SessionHelper.getUser();
    setState(() => _userJabatan = session['jabatan']);
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
    final nama = _selectedBarang?.trim() ?? '';
    final jumlah = int.tryParse(_jumlahController.text.trim()) ?? 0;

    if (nama.isEmpty || jumlah <= 0) {
      setState(() => _status = 'Nama dan jumlah harus diisi dengan benar');
      return;
    }

    if (_jenis == 'keluar') {
      if (_namaPengambilController.text.trim().isEmpty || _namaMobilController.text.trim().isEmpty) {
        setState(() => _status = 'Nama pengambil dan mobil harus diisi');
        return;
      }
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
            'Apakah Anda yakin ingin menyimpan $jenisLabel "$nama" sejumlah $jumlah?'),
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
      final data = {
        'nama_barang': nama,
        'jumlah': jumlah,
        'jenis': _jenis,
        'tanggal': Timestamp.now(),
        'dicatat_oleh': _userJabatan ?? '-',
      };

      if (_jenis == 'keluar') {
        data['nama_pengambil'] = _namaPengambilController.text.trim();
        data['mobil'] = _namaMobilController.text.trim();
      }

      await FirebaseFirestore.instance.collection('transaksi').add(data);

      if (!mounted) return;

      setState(() {
        _status = 'Transaksi $_jenis berhasil disimpan';
        _selectedBarang = null;
        _jumlahController.clear();
        _namaPengambilController.clear();
        _namaMobilController.clear();
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

            if (_jenis == 'keluar') ...[
              TextField(
                controller: _namaPengambilController,
                decoration: const InputDecoration(labelText: 'Nama Pengambil'),
              ),
              TextField(
                controller: _namaMobilController,
                decoration: const InputDecoration(labelText: 'Mobil'),
              ),
            ],

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('barang').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final barangList = snapshot.data!.docs.map((doc) => doc['nama'] as String).toList();

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Nama Barang'),
                  value: _selectedBarang,
                  items: barangList.map((nama) {
                    return DropdownMenuItem<String>(
                      value: nama,
                      child: Text(nama),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedBarang = value),
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
