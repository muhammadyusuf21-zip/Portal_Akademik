import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';

class AdminAllAssignmentsPage extends StatefulWidget {
  const AdminAllAssignmentsPage({super.key});

  @override
  State<AdminAllAssignmentsPage> createState() => _AdminAllAssignmentsPageState();
}

class _AdminAllAssignmentsPageState extends State<AdminAllAssignmentsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assignmentsList = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> data = await SupabaseConfig.client
          .from('tugas')
          .select('*, kelas(*, mata_kuliah(*)), dosen(users(nama))')
          .order('deadline', ascending: true);

      if (mounted) {
        setState(() {
          _assignmentsList = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat tugas: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAssignments {
    if (_searchQuery.isEmpty) return _assignmentsList;
    return _assignmentsList.where((item) {
      final title = (item['judul'] ?? '').toString().toLowerCase();
      final desc = (item['deskripsi'] ?? '').toString().toLowerCase();
      final course = (item['kelas']['mata_kuliah']['nama'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return title.contains(q) || desc.contains(q) || course.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAssignments;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Tugas Kuliah"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Cari Judul Tugas atau Mata Kuliah",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text("Tidak ada tugas ditemukan"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final title = item['judul'] ?? '';
                          final desc = item['deskripsi'] ?? 'Tidak ada deskripsi.';
                          final courseName = item['kelas']['mata_kuliah']['nama'] ?? '';
                          final className = item['kelas']['nama'] ?? '';
                          final dosenName = item['dosen']['users']['nama'] ?? '';
                          
                          final deadlineDate = DateTime.parse(item['deadline']).toLocal();
                          final dlString = "${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year} ${deadlineDate.hour.toString().padLeft(2, '0')}:${deadlineDate.minute.toString().padLeft(2, '0')}";
                          final hasAttachment = item['url_file'] != null && item['url_file'].toString().isNotEmpty;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                        ),
                                      ),
                                      if (hasAttachment)
                                        const Chip(
                                          label: Text("Ada Lampiran", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                                          backgroundColor: Color(0xFFEFF6FF),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Mata Kuliah: $courseName (Kelas $className)", style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                  Text("Dosen: $dosenName", style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
                                  const Divider(height: 20),
                                  Text(
                                    desc,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.timer_outlined, size: 14, color: AppTheme.accent),
                                          SizedBox(width: 4),
                                          Text("Batas Waktu:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                                        ],
                                      ),
                                      Text(
                                        dlString,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accent),
                                      ),
                                    ],
                                  )
                                ],
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
}

