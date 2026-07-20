import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';

class KrsApprovalPage extends StatefulWidget {
  const KrsApprovalPage({super.key});

  @override
  State<KrsApprovalPage> createState() => _KrsApprovalPageState();
}

class _KrsApprovalPageState extends State<KrsApprovalPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _krsRawList = [];
  Map<String, List<Map<String, dynamic>>> _groupedKrs = {};

  @override
  void initState() {
    super.initState();
    _loadPendingKrs();
  }

  Future<void> _loadPendingKrs() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      // Fetch KRS that is pending approval
      final List<dynamic> data = await client
          .from('krs')
          .select('*, mahasiswa(*, users(nama)), semester(*), jadwal(*, kelas(*, mata_kuliah(*)))')
          .eq('status', 'menunggu');
      
      _krsRawList = List<Map<String, dynamic>>.from(data);
      
      // Group by Mahasiswa ID
      final Map<String, List<Map<String, dynamic>>> tempGroup = {};
      for (var item in _krsRawList) {
        final mId = item['mahasiswa_id'];
        if (!tempGroup.containsKey(mId)) {
          tempGroup[mId] = [];
        }
        tempGroup[mId]!.add(item);
      }

      if (mounted) {
        setState(() {
          _groupedKrs = tempGroup;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat krs: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processKrs(String mId, String status, List<Map<String, dynamic>> items) async {
    final action = status == 'disetujui' ? "Menyetujui" : "Menolak";
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text("Konfirmasi $action KRS"),
        content: Text("Yakin ingin mengubah status KRS mahasiswa ini menjadi '$status'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'disetujui' ? Colors.green : AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(status == 'disetujui' ? "Setujui" : "Tolak"),
          )
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;

        // 1. Update status KRS untuk mahasiswa tersebut yang 'menunggu'
        await client
            .from('krs')
            .update({'status': status})
            .eq('mahasiswa_id', mId)
            .eq('status', 'menunggu');

        // 2. Jika disetujui, masukkan mahasiswa ke tabel 'nilai' kelas tersebut agar dosen bisa input nilai
        if (status == 'disetujui') {
          for (var krsItem in items) {
            final kelasId = krsItem['jadwal']['kelas_id'];
            // Insert ke tabel nilai (gunakan upsert agar tidak error jika sudah ada)
            await client.from('nilai').upsert({
              'mahasiswa_id': mId,
              'kelas_id': kelasId,
            }, onConflict: 'mahasiswa_id, kelas_id');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("KRS berhasil di-$status"), backgroundColor: Colors.green),
        );
        _loadPendingKrs();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memproses KRS: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDetailDialog(String mName, String nim, List<Map<String, dynamic>> items) {
    try {
      int totalSks = 0;
      for (var it in items) {
        final j = it['jadwal'];
        if (j == null) continue;
        final k = j['kelas'];
        if (k == null) continue;
        final mk = k['mata_kuliah'];
        if (mk == null) continue;
        final sksVal = mk['sks'];
        if (sksVal != null) {
          totalSks += (sksVal as num).toInt();
        }
      }

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("NIM: $nim | Total SKS: $totalSks SKS", style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (ctx, idx) {
                  final it = items[idx];
                  final j = it['jadwal'];
                  if (j == null) return const SizedBox();
                  final k = j['kelas'];
                  if (k == null) return const SizedBox();
                  final mk = k['mata_kuliah'];
                  if (mk == null) return const SizedBox();
                  
                  String timeStr = "";
                  if (j['jam_mulai'] != null && j['jam_selesai'] != null) {
                    final start = j['jam_mulai'].toString();
                    final end = j['jam_selesai'].toString();
                    final s = start.length >= 5 ? start.substring(0, 5) : start;
                    final e = end.length >= 5 ? end.substring(0, 5) : end;
                    timeStr = "$s - $e";
                  }
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("[${mk['kode'] ?? ''}] ${mk['nama'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text("Kelas: ${k['nama'] ?? ''} | SKS: ${mk['sks'] ?? ''}"),
                          Text("Jadwal: ${j['hari'] ?? ''}, $timeStr (${(j['ruangan'] ?? '').toString().toLowerCase().contains('ruang') ? (j['ruangan'] ?? '') : "Ruang ${j['ruangan'] ?? ''}"})", style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Tutup"),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _processKrs(items.first['mahasiswa_id'], 'ditolak', items);
                  },
                  child: const Text("Tolak"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _processKrs(items.first['mahasiswa_id'], 'disetujui', items);
                  },
                  child: const Text("Setujui"),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("KRS_DIALOG_ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memproses data: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Persetujuan KRS"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedKrs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                      SizedBox(height: 12),
                      Text(
                        "Semua pengajuan KRS sudah diproses",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groupedKrs.keys.length,
                  itemBuilder: (context, index) {
                    final mId = _groupedKrs.keys.elementAt(index);
                    final items = _groupedKrs[mId]!;
                    final first = items.first;
                    final mName = first['mahasiswa']['users']['nama'] ?? '';
                    final nim = first['mahasiswa']['nim'] ?? '';
                    final semesterName = first['semester']['nama'] ?? '';
                    
                    int totalSks = 0;
                    for (var it in items) {
                      totalSks += (it['jadwal']['kelas']['mata_kuliah']['sks'] as num).toInt();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(mName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("NIM: $nim | Semester: $semesterName"),
                            Text("Pengajuan: ${items.length} Kelas ($totalSks SKS)", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => _showDetailDialog(mName, nim, items),
                      ),
                    );
                  },
                ),
    );
  }
}
