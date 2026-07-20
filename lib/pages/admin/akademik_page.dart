import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';

class ManageAkademikPage extends StatefulWidget {
  const ManageAkademikPage({super.key});

  @override
  State<ManageAkademikPage> createState() => _ManageAkademikPageState();
}

class _ManageAkademikPageState extends State<ManageAkademikPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _prodiList = [];
  List<Map<String, dynamic>> _semesterList = [];
  List<Map<String, dynamic>> _matkulList = [];
  List<Map<String, dynamic>> _dosenList = [];
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _jadwalList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;

      final futures = await Future.wait([
        client.from('program_studi').select().order('nama'),
        client.from('semester').select().order('created_at'),
        client
            .from('mata_kuliah')
            .select('*, program_studi(nama), semester(nama)')
            .order('kode'),
        client.from('dosen').select('*, users(nama)'),
        client
            .from('kelas')
            .select('*, mata_kuliah(nama, kode), dosen(users(nama))')
            .order('nama'),
        client
            .from('jadwal')
            .select(
              '*, kelas(*, mata_kuliah(*), dosen(users(nama))), semester(*)',
            )
            .order('hari'),
      ]);

      if (mounted) {
        setState(() {
          _prodiList = List<Map<String, dynamic>>.from(futures[0] as List);
          _semesterList = List<Map<String, dynamic>>.from(futures[1] as List);
          _matkulList = List<Map<String, dynamic>>.from(futures[2] as List);
          _dosenList = List<Map<String, dynamic>>.from(futures[3] as List);
          _kelasList = List<Map<String, dynamic>>.from(futures[4] as List);
          _jadwalList = List<Map<String, dynamic>>.from(futures[5] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack("Error memuat data akademik: $e", Colors.red);
      }
    }
  }

  void _snack(String msg, Color color) {
    AppTheme.showSnackBar(context, msg, backgroundColor: color);
  }

  // ===========================================================================
  // 1. PROGRAM STUDI CRUD
  // ===========================================================================
  Future<void> _addOrEditProdi([Map<String, dynamic>? item]) async {
    final kodeController = TextEditingController(text: item?['kode'] ?? '');
    final namaController = TextEditingController(text: item?['nama'] ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          item == null ? "Tambah Program Studi" : "Edit Program Studi",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 450,
            maxHeight: MediaQuery.of(context).size.height * 0.52,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Kode Prodi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: kodeController,
                  decoration: const InputDecoration(
                    hintText: "Contoh: TI",
                    prefixIcon: Icon(Icons.code, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Nama Prodi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    hintText: "Contoh: Teknik Informatika",
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          AppTheme.buildGradientButton(
            onPressed: () => Navigator.pop(context, true),
            text: "Simpan",
          ),
        ],
      ),
    );

    if (ok == true) {
      if (kodeController.text.trim().isEmpty ||
          namaController.text.trim().isEmpty)
        return;
      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;
        if (item == null) {
          await client.from('program_studi').insert({
            'kode': kodeController.text.trim().toUpperCase(),
            'nama': namaController.text.trim(),
          });
        } else {
          await client
              .from('program_studi')
              .update({
                'kode': kodeController.text.trim().toUpperCase(),
                'nama': namaController.text.trim(),
              })
              .eq('id', item['id']);
        }
        _snack("Program studi berhasil disimpan", Colors.green);
        _loadAllData();
      } catch (e) {
        setState(() => _isLoading = false);
        final errStr = e.toString();
        if (errStr.contains("program_studi_kode_key")) {
          _snack(
            "Gagal menyimpan: Kode Program Studi sudah digunakan",
            Colors.red,
          );
        } else {
          _snack("Gagal menyimpan: $e", Colors.red);
        }
      }
    }
  }

  Future<void> _deleteProdi(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Prodi"),
        content: const Text(
          "Yakin ingin menghapus prodi ini? Semua data terkait (mahasiswa, matkul, dll) akan terhapus.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await SupabaseConfig.client.from('program_studi').delete().eq('id', id);
        _loadAllData();
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains("foreign key constraint") ||
            errStr.contains("violates foreign key")) {
          _snack(
            "Gagal menghapus: Program Studi sedang digunakan oleh data lain",
            Colors.red,
          );
        } else {
          _snack("Gagal menghapus: $e", Colors.red);
        }
      }
    }
  }

  // ===========================================================================
  // 2. SEMESTER CRUD
  // ===========================================================================
  Future<void> _addOrEditSemester([Map<String, dynamic>? item]) async {
    final namaController = TextEditingController(text: item?['nama'] ?? '');
    bool status = item?['status'] ?? false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            item == null ? "Tambah Semester" : "Edit Semester",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: MediaQuery.of(ctx).size.height * 0.52,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nama Semester",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: namaController,
                    decoration: const InputDecoration(
                      hintText: "Contoh: Semester Ganjil 2026/2027",
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        "Status Aktif",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.textDark,
                        ),
                      ),
                      subtitle: const Text(
                        "Jadikan semester ini sebagai semester aktif utama",
                        style: TextStyle(fontSize: 11),
                      ),
                      value: status,
                      activeColor: AppTheme.primary,
                      onChanged: (val) => setDialogState(() => status = val),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal"),
            ),
            AppTheme.buildGradientButton(
              onPressed: () => Navigator.pop(ctx, true),
              text: "Simpan",
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      if (namaController.text.trim().isEmpty) return;
      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;
        final String? semId = item?['id'];

        if (item == null) {
          final newSem = await client
              .from('semester')
              .insert({'nama': namaController.text.trim(), 'status': status})
              .select()
              .single();

          if (status == true) {
            await client
                .from('semester')
                .update({'status': false})
                .neq('id', newSem['id']);
          }
        } else {
          await client
              .from('semester')
              .update({'nama': namaController.text.trim(), 'status': status})
              .eq('id', semId!);

          if (status == true) {
            await client
                .from('semester')
                .update({'status': false})
                .neq('id', semId);
          }
        }
        _snack("Semester berhasil disimpan", Colors.green);
        _loadAllData();
      } catch (e) {
        setState(() => _isLoading = false);
        final errStr = e.toString();
        if (errStr.contains("semester_nama_key")) {
          _snack("Gagal menyimpan: Nama Semester sudah digunakan", Colors.red);
        } else {
          _snack("Gagal menyimpan: $e", Colors.red);
        }
      }
    }
  }

  // ===========================================================================
  // 3. MATA KULIAH CRUD
  // ===========================================================================
  Future<void> _addOrEditMatkul([Map<String, dynamic>? item]) async {
    final kodeController = TextEditingController(text: item?['kode'] ?? '');
    final namaController = TextEditingController(text: item?['nama'] ?? '');
    int sks = item?['sks'] ?? 2;
    String? prodiId =
        item?['program_studi_id'] ??
        (_prodiList.isNotEmpty ? _prodiList.first['id'] : null);
    String? semesterId =
        item?['semester_id'] ??
        (_semesterList.isNotEmpty ? _semesterList.first['id'] : null);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            item == null ? "Tambah Mata Kuliah" : "Edit Mata Kuliah",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: MediaQuery.of(ctx).size.height * 0.52,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Kode MK",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: kodeController,
                    decoration: const InputDecoration(
                      hintText: "Contoh: IF101",
                      prefixIcon: Icon(
                        Icons.code_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Nama Mata Kuliah",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: namaController,
                    decoration: const InputDecoration(
                      hintText: "Contoh: Pemrograman Dasar",
                      prefixIcon: Icon(
                        Icons.book_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Jumlah SKS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: sks,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.star_outline,
                        color: AppTheme.primary,
                      ),
                    ),
                    items: [1, 2, 3, 4, 6]
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              "$v SKS",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => sks = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Program Studi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: prodiId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.school_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    items: _prodiList
                        .map(
                          (p) => DropdownMenuItem(
                            value: p['id'].toString(),
                            child: Text(
                              p['nama'],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setDialogState(() => prodiId = val),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Semester Target",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: semesterId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.calendar_month_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    items: _semesterList
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['id'].toString(),
                            child: Text(
                              s['nama'],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setDialogState(() => semesterId = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal"),
            ),
            AppTheme.buildGradientButton(
              onPressed: () => Navigator.pop(ctx, true),
              text: "Simpan",
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      if (kodeController.text.trim().isEmpty ||
          namaController.text.trim().isEmpty ||
          prodiId == null ||
          semesterId == null)
        return;
      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;
        final data = {
          'kode': kodeController.text.trim().toUpperCase(),
          'nama': namaController.text.trim(),
          'sks': sks,
          'program_studi_id': prodiId,
          'semester_id': semesterId,
        };

        if (item == null) {
          await client.from('mata_kuliah').insert(data);
        } else {
          await client.from('mata_kuliah').update(data).eq('id', item['id']);
        }
        _snack("Mata kuliah disimpan", Colors.green);
        _loadAllData();
      } catch (e) {
        setState(() => _isLoading = false);
        final errStr = e.toString();
        if (errStr.contains("mata_kuliah_kode_key")) {
          _snack(
            "Gagal menyimpan: Kode Mata Kuliah sudah digunakan",
            Colors.red,
          );
        } else {
          _snack("Gagal menyimpan: $e", Colors.red);
        }
      }
    }
  }

  // ===========================================================================
  // 4. KELAS CRUD
  // ===========================================================================
  Future<void> _addOrEditKelas([Map<String, dynamic>? item]) async {
    final namaController = TextEditingController(text: item?['nama'] ?? '');
    final kuotaController = TextEditingController(
      text: item?['kuota']?.toString() ?? '40',
    );
    String? mkId =
        item?['mata_kuliah_id'] ??
        (_matkulList.isNotEmpty ? _matkulList.first['id'] : null);
    String? dosenId =
        item?['dosen_id'] ??
        (_dosenList.isNotEmpty ? _dosenList.first['id'] : null);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            item == null ? "Tambah Kelas Baru" : "Edit Kelas",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: MediaQuery.of(ctx).size.height * 0.52,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nama Kelas",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: namaController,
                    decoration: const InputDecoration(
                      hintText: "Contoh: TI-A",
                      prefixIcon: Icon(
                        Icons.meeting_room_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Kuota Mahasiswa",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: kuotaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Contoh: 40",
                      prefixIcon: Icon(
                        Icons.people_alt_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Mata Kuliah",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: mkId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.book_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    items: _matkulList
                        .map(
                          (m) => DropdownMenuItem(
                            value: m['id'].toString(),
                            child: Text("[${m['kode']}] ${m['nama']}"),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setDialogState(() => mkId = val),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Dosen Pengampu",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: dosenId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppTheme.primary,
                      ),
                    ),
                    items: _dosenList
                        .map(
                          (d) => DropdownMenuItem(
                            value: d['id'].toString(),
                            child: Text(d['users']['nama']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setDialogState(() => dosenId = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal"),
            ),
            AppTheme.buildGradientButton(
              onPressed: () => Navigator.pop(ctx, true),
              text: "Simpan",
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final kName = namaController.text.trim();
      final kuota = int.tryParse(kuotaController.text);
      if (kName.isEmpty || kuota == null || mkId == null || dosenId == null)
        return;

      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;
        final data = {
          'nama': kName,
          'kuota': kuota,
          'mata_kuliah_id': mkId,
          'dosen_id': dosenId,
        };

        if (item == null) {
          await client.from('kelas').insert(data);
        } else {
          await client.from('kelas').update(data).eq('id', item['id']);
        }
        _snack("Kelas berhasil disimpan", Colors.green);
        _loadAllData();
      } catch (e) {
        setState(() => _isLoading = false);
        final errStr = e.toString();
        if (errStr.contains("kelas_nama_mata_kuliah_id_key")) {
          _snack(
            "Gagal menyimpan: Nama kelas untuk mata kuliah ini sudah digunakan",
            Colors.red,
          );
        } else {
          _snack("Gagal menyimpan kelas: $e", Colors.red);
        }
      }
    }
  }

  // ===========================================================================
  // 5. JADWAL CRUD
  // ===========================================================================
  Future<void> _addOrEditJadwal([Map<String, dynamic>? item]) async {
    String? kelasId =
        item?['kelas_id'] ??
        (_kelasList.isNotEmpty ? _kelasList.first['id'] : null);
    String hari = item?['hari'] ?? 'Senin';
    String ruangan = item?['ruangan'] ?? 'Ruang 101';
    String? semId =
        item?['semester_id'] ??
        (_semesterList.isNotEmpty ? _semesterList.first['id'] : null);

    TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 9, minute: 40);

    if (item != null) {
      final sArr = item['jam_mulai'].toString().split(':');
      final eArr = item['jam_selesai'].toString().split(':');
      start = TimeOfDay(hour: int.parse(sArr[0]), minute: int.parse(sArr[1]));
      end = TimeOfDay(hour: int.parse(eArr[0]), minute: int.parse(eArr[1]));
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            item == null ? "Buat Jadwal Kuliah" : "Edit Jadwal",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: MediaQuery.of(ctx).size.height * 0.52,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Kelas (Mata Kuliah & Dosen)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: kelasId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.meeting_room_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    items: _kelasList.map((k) {
                      final mk = k['mata_kuliah'];
                      final d = k['dosen']['users']['nama'];
                      return DropdownMenuItem(
                        value: k['id'].toString(),
                        child: Text(
                          "${k['nama']} - ${mk['nama']} ($d)",
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => kelasId = val),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Hari",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: hari,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.today_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    items:
                        [
                              'Senin',
                              'Selasa',
                              'Rabu',
                              'Kamis',
                              'Jumat',
                              'Sabtu',
                              'Minggu',
                            ]
                            .map(
                              (h) => DropdownMenuItem(value: h, child: Text(h)),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => hari = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ruangan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: TextEditingController(text: ruangan),
                    decoration: const InputDecoration(
                      hintText: "Contoh: Ruang 101",
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    onChanged: (val) => ruangan = val,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Semester Akademik",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: semId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.calendar_month_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    items: _semesterList
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['id'].toString(),
                            child: Text(s['nama']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setDialogState(() => semId = val),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Jam Mulai: ${start.format(ctx)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: ctx,
                                  initialTime: start,
                                );
                                if (time != null)
                                  setDialogState(() => start = time);
                              },
                              child: const Text("Pilih"),
                            ),
                          ],
                        ),
                        const Divider(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_filled,
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Jam Selesai: ${end.format(ctx)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: ctx,
                                  initialTime: end,
                                );
                                if (time != null)
                                  setDialogState(() => end = time);
                              },
                              child: const Text("Pilih"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal"),
            ),
            AppTheme.buildGradientButton(
              onPressed: () => Navigator.pop(ctx, true),
              text: "Simpan",
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      if (kelasId == null || semId == null || ruangan.trim().isEmpty) return;

      final startStr =
          "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00";
      final endStr =
          "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00";

      setState(() => _isLoading = true);
      try {
        final client = SupabaseConfig.client;
        final data = {
          'kelas_id': kelasId,
          'hari': hari,
          'jam_mulai': startStr,
          'jam_selesai': endStr,
          'ruangan': ruangan.trim(),
          'semester_id': semId,
        };

        if (item == null) {
          await client.from('jadwal').insert(data);
        } else {
          await client.from('jadwal').update(data).eq('id', item['id']);
        }
        _snack("Jadwal kuliah berhasil disimpan", Colors.green);
        _loadAllData();
      } catch (e) {
        setState(() => _isLoading = false);
        final errStr = e.toString();
        if (errStr.contains("jadwal_kelas_id_key")) {
          _snack(
            "Gagal menyimpan: Jadwal untuk kelas ini sudah ada",
            Colors.red,
          );
        } else {
          _snack("Gagal menyimpan jadwal: $e", Colors.red);
        }
      }
    }
  }

  Future<void> _deleteItem(String table, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text(
          "Yakin ingin menghapus item ini? Tindakan ini akan menghapus data yang bergantung.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        await SupabaseConfig.client.from(table).delete().eq('id', id);
        _snack("Data berhasil dihapus", Colors.green);
        _loadAllData();
      } catch (e) {
        setState(() => _isLoading = false);
        final errStr = e.toString();
        if (errStr.contains("foreign key constraint") ||
            errStr.contains("violates foreign key")) {
          String name = "Data";
          if (table == 'semester') name = "Semester";
          if (table == 'mata_kuliah') name = "Mata Kuliah";
          if (table == 'kelas') name = "Kelas";
          if (table == 'jadwal') name = "Jadwal";
          _snack(
            "Gagal menghapus: $name sedang digunakan oleh data lain",
            Colors.red,
          );
        } else {
          _snack("Gagal menghapus: $e", Colors.red);
        }
      }
    }
  }

  // ===========================================================================
  // LAYOUT & RENDERING
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Akademik"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Program Studi"),
            Tab(text: "Semester"),
            Tab(text: "Mata Kuliah"),
            Tab(text: "Kelas"),
            Tab(text: "Jadwal"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProdiList(),
                _buildSemesterList(),
                _buildMatkulList(),
                _buildKelasList(),
                _buildJadwalList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final tabIndex = _tabController.index;
          if (tabIndex == 0) _addOrEditProdi();
          if (tabIndex == 1) _addOrEditSemester();
          if (tabIndex == 2) _addOrEditMatkul();
          if (tabIndex == 3) _addOrEditKelas();
          if (tabIndex == 4) _addOrEditJadwal();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProdiList() {
    if (_prodiList.isEmpty)
      return const Center(child: Text("Belum ada data Prodi"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prodiList.length,
      itemBuilder: (context, index) {
        final item = _prodiList[index];
        return Card(
          child: ListTile(
            title: Text(
              item['nama'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Kode: ${item['kode']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _addOrEditProdi(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.accent),
                  onPressed: () => _deleteProdi(item['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSemesterList() {
    if (_semesterList.isEmpty)
      return const Center(child: Text("Belum ada data Semester"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _semesterList.length,
      itemBuilder: (context, index) {
        final item = _semesterList[index];
        final isActive = item['status'] == true;
        return Card(
          child: ListTile(
            title: Text(
              item['nama'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? "Aktif" : "Tidak Aktif",
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _addOrEditSemester(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.accent),
                  onPressed: () => _deleteItem('semester', item['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatkulList() {
    if (_matkulList.isEmpty)
      return const Center(child: Text("Belum ada data Mata Kuliah"));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _matkulList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _matkulList[index];
        final pName = item['program_studi'] != null
            ? item['program_studi']['nama']
            : '-';
        final sName = item['semester'] != null ? item['semester']['nama'] : '-';
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['kode'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${item['sks']} SKS",
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item['nama'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Prodi: $pName",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Semester: $sName",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(right: 8),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _addOrEditMatkul(item),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                        onPressed: () => _deleteItem('mata_kuliah', item['id']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKelasList() {
    if (_kelasList.isEmpty)
      return const Center(child: Text("Belum ada data Kelas"));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _kelasList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _kelasList[index];
        final mk = item['mata_kuliah'] ?? {};
        final dName = item['dosen'] != null && item['dosen']['users'] != null
            ? item['dosen']['users']['nama']
            : '-';
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Kelas ${item['nama']}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Kuota: ${item['kuota']} Mhs",
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          mk['nama'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Dosen: $dName",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Kode MK: ${mk['kode'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(right: 8),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _addOrEditKelas(item),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                        onPressed: () => _deleteItem('kelas', item['id']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJadwalList() {
    if (_jadwalList.isEmpty)
      return const Center(child: Text("Belum ada Jadwal Kuliah"));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _jadwalList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _jadwalList[index];
        final k = item['kelas'] ?? {};
        final mk = k['mata_kuliah'] ?? {};
        final dName = k['dosen'] != null && k['dosen']['users'] != null
            ? k['dosen']['users']['nama']
            : '-';
        final sName = item['semester'] != null ? item['semester']['nama'] : '-';
        final timeString =
            "${item['jam_mulai'].toString().substring(0, 5)} - ${item['jam_selesai'].toString().substring(0, 5)}";

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${item['hari']}, $timeString",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (item['ruangan'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains('ruang')
                                    ? (item['ruangan'] ?? '')
                                    : "Ruang ${item['ruangan'] ?? ''}",
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          mk['nama'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Kelas: ${k['nama'] ?? ''}  |  Dosen: $dName",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Semester: $sName",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(right: 8),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _addOrEditJadwal(item),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                        onPressed: () => _deleteItem('jadwal', item['id']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
