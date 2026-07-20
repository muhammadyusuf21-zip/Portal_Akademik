import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';
import '../../utils/format_utils.dart';

class AdminAllGradesPage extends StatefulWidget {
  const AdminAllGradesPage({super.key});

  @override
  State<AdminAllGradesPage> createState() => _AdminAllGradesPageState();
}

class _AdminAllGradesPageState extends State<AdminAllGradesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _gradesList = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> data = await SupabaseConfig.client
          .from('nilai')
          .select('*, mahasiswa(*, users(nama)), kelas(*, mata_kuliah(*))')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _gradesList = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat nilai: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredGrades {
    if (_searchQuery.isEmpty) return _gradesList;
    return _gradesList.where((item) {
      final nama = (item['mahasiswa']['users']['nama'] ?? '').toString().toLowerCase();
      final nim = (item['mahasiswa']['nim'] ?? '').toString().toLowerCase();
      final mk = (item['kelas']['mata_kuliah']['nama'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return nama.contains(q) || nim.contains(q) || mk.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGrades;

    // Group grades by student
    final Map<String, Map<String, dynamic>> groupedMap = {};
    for (final grade in filtered) {
      final m = grade['mahasiswa'] ?? {};
      final mId = m['id']?.toString() ?? '';
      if (mId.isEmpty) continue;

      if (!groupedMap.containsKey(mId)) {
        groupedMap[mId] = {
          'mahasiswa': m,
          'nama': m['users']?['nama'] ?? '-',
          'nim': m['nim'] ?? '',
          'grades': <Map<String, dynamic>>[],
        };
      }
      (groupedMap[mId]!['grades'] as List<Map<String, dynamic>>).add(grade);
    }

    final List<Map<String, dynamic>> groupedList = groupedMap.values.toList();
    // Sort students alphabetically by name
    groupedList.sort((a, b) => (a['nama'] as String).toLowerCase().compareTo((b['nama'] as String).toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Seluruh Nilai Mahasiswa"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Cari Mahasiswa, NIM, atau Mata Kuliah",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupedList.isEmpty
                    ? const Center(child: Text("Tidak ada data nilai ditemukan"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: groupedList.length,
                        itemBuilder: (context, index) {
                          final student = groupedList[index];
                          final nama = student['nama'] ?? '-';
                          final nim = student['nim'] ?? '';
                          final studentGrades = student['grades'] as List<Map<String, dynamic>>;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                key: PageStorageKey("${student['mahasiswa']['id']}_${_searchQuery.isNotEmpty}"),
                                initiallyExpanded: _searchQuery.isNotEmpty,
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                                  child: const Icon(Icons.person, color: AppTheme.primary),
                                ),
                                title: Text(
                                  nama,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                ),
                                subtitle: Text("NIM: $nim", style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${studentGrades.length} MK",
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                children: studentGrades.map((gradeItem) {
                                  final mk = gradeItem['kelas']['mata_kuliah'];
                                  final mkName = mk['nama'] ?? '';
                                  final kelasName = gradeItem['kelas']['nama'] ?? '';
                                  
                                  final tugas = formatNilai(gradeItem['nilai_tugas']);
                                  final uts = formatNilai(gradeItem['nilai_uts']);
                                  final uas = formatNilai(gradeItem['nilai_uas']);
                                  final akhir = formatNilai(gradeItem['nilai_akhir']);
                                  final gradeVal = gradeItem['grade'] ?? '-';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "$mkName (Kelas $kelasName)",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: (gradeVal == 'A' || gradeVal == 'B') 
                                                    ? Colors.green.withOpacity(0.1) 
                                                    : Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "Grade: $gradeVal",
                                                style: TextStyle(
                                                  color: (gradeVal == 'A' || gradeVal == 'B') 
                                                      ? Colors.green 
                                                      : Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildScoreColumn("Tugas", tugas),
                                            _buildScoreColumn("UTS", uts),
                                            _buildScoreColumn("UAS", uas),
                                            _buildScoreColumn("Nilai Akhir", akhir),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String label, String score) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
        const SizedBox(height: 4),
        Text(score, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }
}
