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

  String _jenis = 'masuk';
  String? _userJabatan;
  String? _selectedBarang;
  String? _selectedPlatMobil;
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
      if (_selectedPlatMobil == null) {
        setState(() => _status = 'Plat mobil harus dipilih');
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
      final Map<String, dynamic> data = {
        'nama_barang': nama,
        'jumlah': jumlah,
        'jenis': _jenis,
        'tanggal': Timestamp.now(),
        'dicatat_oleh': _userJabatan ?? '-',
      };

      if (_jenis == 'keluar') {
        data['mobil'] = _selectedPlatMobil ?? '';
      }

      await FirebaseFirestore.instance.collection('transaksi').add(data);

      if (!mounted) return;

      setState(() {
        _status = 'Transaksi $_jenis berhasil disimpan';
        _selectedBarang = null;
        _jumlahController.clear();
        _selectedPlatMobil = null;
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
        child: SingleChildScrollView(
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

              if (_jenis == 'keluar')
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('mobil').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return const Text('Gagal memuat data mobil');
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('Tidak ada data mobil');
                    }

                    final platList = snapshot.data!.docs
                        .map((doc) => doc['plat']?.toString() ?? '')
                        .where((plat) => plat.isNotEmpty)
                        .toList();

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Plat Mobil'),
                      value: _selectedPlatMobil,
                      items: [
                        for (int i = 0; i < platList.length; i++)
                          DropdownMenuItem<String>(
                            value: platList[i],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(platList[i]),
                                if (i < platList.length - 1)
                                  const Divider(height: 10, thickness: 1),
                              ],
                            ),
                          )
                      ],
                      onChanged: (value) => setState(() => _selectedPlatMobil = value),
                    );
                  },
                ),

              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('barang').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text('Gagal memuat data barang');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('Tidak ada data barang');
                  }

                  final barangList = snapshot.data!.docs.map((doc) => doc['nama'] as String).toList();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Nama Barang'),
                    value: _selectedBarang,
                    items: [
                      for (int i = 0; i < barangList.length; i++)
                        DropdownMenuItem<String>(
                          value: barangList[i],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(barangList[i]),
                              if (i < barangList.length - 1)
                                const Divider(height: 10, thickness: 1),
                            ],
                          ),
                        )
                    ],
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
      ),
    );
  }
}
