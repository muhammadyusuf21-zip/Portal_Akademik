import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../utils/theme.dart';
import '../../utils/supabase_config.dart';
import '../../utils/format_utils.dart';

class KhsPage extends StatefulWidget {
  final Map<String, dynamic> studentDetails;
  final Map<String, dynamic>? activeSemester;
  final bool isTab;

  const KhsPage({
    super.key,
    required this.studentDetails,
    this.activeSemester,
    this.isTab = false,
  });

  @override
  State<KhsPage> createState() => _KhsPageState();
}

class _KhsPageState extends State<KhsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _semesters = [];
  String? _selectedSemesterId; // 'all' for cumulative, or specific semester ID
  String _studentName = '';

  @override
  void initState() {
    super.initState();
    _loadKhsData();
  }

  Future<void> _loadKhsData() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;

      // 1. Get Student Name from profile
      final profile = await SupabaseConfig.getCurrentUserProfile();
      _studentName = profile?['nama'] ?? 'Mahasiswa';

      // 2. Fetch All Semesters
      final List<dynamic> semData = await client
          .from('semester')
          .select()
          .order('created_at', ascending: false);
      _semesters = List<Map<String, dynamic>>.from(semData);

      // 3. Fetch All Grades for the current student
      final List<dynamic> gradesData = await client
          .from('nilai')
          .select('*, kelas(*, mata_kuliah(*, semester(*)), dosen(users(nama)))')
          .eq('mahasiswa_id', widget.studentDetails['id']);
      _grades = List<Map<String, dynamic>>.from(gradesData);

      // 4. Default Selected Semester to active semester if available, else first in list, else 'all'
      if (widget.activeSemester != null &&
          _semesters.any((s) => s['id'] == widget.activeSemester!['id'])) {
        _selectedSemesterId = widget.activeSemester!['id'];
      } else if (_semesters.isNotEmpty) {
        _selectedSemesterId = _semesters.first['id'];
      } else {
        _selectedSemesterId = 'all';
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data KHS: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  double _getGradePoint(String? grade) {
    if (grade == null) return 0.0;
    switch (grade.toUpperCase()) {
      case 'A': return 4.0;
      case 'B': return 3.0;
      case 'C': return 2.0;
      case 'D': return 1.0;
      case 'E': return 0.0;
      default: return 0.0;
    }
  }

  Color _getGradeColor(String? grade) {
    if (grade == null) return Colors.grey;
    switch (grade.toUpperCase()) {
      case 'A': return Colors.green.shade700;
      case 'B': return Colors.blue.shade700;
      case 'C': return Colors.orange.shade700;
      case 'D': return Colors.deepOrange.shade700;
      case 'E': return Colors.red.shade700;
      default: return Colors.grey;
    }
  }

  // Filter grades based on selected semester
  List<Map<String, dynamic>> get _filteredGrades {
    if (_selectedSemesterId == 'all') {
      return _grades;
    }
    return _grades.where((g) {
      final sem = g['kelas']?['mata_kuliah']?['semester'];
      return sem != null && sem['id'] == _selectedSemesterId;
    }).toList();
  }

  int get _totalSks {
    int total = 0;
    for (var grade in _filteredGrades) {
      final sks = grade['kelas']?['mata_kuliah']?['sks'];
      if (sks != null && grade['grade'] != null) {
        total += (sks as num).toInt();
      }
    }
    return total;
  }

  double get _gpa {
    double totalPoints = 0;
    int totalSksWithGrade = 0;
    for (var grade in _filteredGrades) {
      final sks = grade['kelas']?['mata_kuliah']?['sks'];
      final gStr = grade['grade'];
      if (sks != null && gStr != null) {
        final sksInt = (sks as num).toInt();
        totalPoints += sksInt * _getGradePoint(gStr);
        totalSksWithGrade += sksInt;
      }
    }
    return totalSksWithGrade > 0 ? totalPoints / totalSksWithGrade : 0.0;
  }

  String get _selectedSemesterName {
    if (_selectedSemesterId == 'all') return 'Transkrip Nilai Kumulatif';
    final sem = _semesters.firstWhere((s) => s['id'] == _selectedSemesterId, orElse: () => {'nama': '-'});
    return sem['nama'];
  }

  Future<void> _printPdf() async {
    final pdf = pw.Document();
    final list = _filteredGrades;
    final double computedGpa = _gpa;
    final int computedSks = _totalSks;
    final String semName = _selectedSemesterName;
    final String dateStr = "${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Instansi Akademik
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'KEMENTERIAN PENDIDIKAN, KEBUDAYAAN, RISET, DAN TEKNOLOGI',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'UNIVERSITAS PENGELOLA DATA MAHASISWA',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'Fakultas Ilmu Komputer dan Teknologi Informasi',
                        style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Divider(thickness: 2),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        _selectedSemesterId == 'all' ? 'TRANSKRIP NILAI AKADEMIK' : 'KARTU HASIL STUDI (KHS)',
                        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                      ),
                      pw.SizedBox(height: 16),
                    ],
                  ),
                ),

                // Informasi Biodata Mahasiswa
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.SizedBox(width: 80, child: pw.Text('Nama', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Text(': $_studentName'),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.SizedBox(width: 80, child: pw.Text('NIM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Text(': ${widget.studentDetails['nim']}'),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.SizedBox(width: 90, child: pw.Text('Program Studi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Text(': ${widget.studentDetails['program_studi']?['nama'] ?? '-'}'),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.SizedBox(width: 90, child: pw.Text('Semester', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Text(': $semName'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Tabel Nilai
                pw.Table.fromTextArray(
                  headers: ['No', 'Kode MK', 'Mata Kuliah', 'SKS', 'Nilai Angka', 'Grade', 'Bobot', 'SKS * Bobot'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignment: pw.Alignment.center,
                  columnWidths: {
                    0: const pw.FixedColumnWidth(25),
                    1: const pw.FixedColumnWidth(60),
                    2: const pw.FlexColumnWidth(),
                    3: const pw.FixedColumnWidth(40),
                    4: const pw.FixedColumnWidth(60),
                    5: const pw.FixedColumnWidth(45),
                    6: const pw.FixedColumnWidth(45),
                    7: const pw.FixedColumnWidth(60),
                  },
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  data: List<List<dynamic>>.generate(list.length, (index) {
                    final row = list[index];
                    final mk = row['kelas']?['mata_kuliah'] ?? {};
                    final double sksVal = (mk['sks'] ?? 0).toDouble();
                    final double gPoint = _getGradePoint(row['grade']);
                    return [
                      (index + 1).toString(),
                      mk['kode'] ?? '-',
                      mk['nama'] ?? '-',
                      mk['sks']?.toString() ?? '0',
                      formatNilai(row['nilai_akhir']),
                      row['grade'] ?? '-',
                      gPoint.toStringAsFixed(1),
                      (sksVal * gPoint).toStringAsFixed(1),
                    ];
                  }),
                ),
                pw.SizedBox(height: 20),

                // Ringkasan SKS dan IP
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.SizedBox(),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total SKS Diambil : $computedSks SKS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            _selectedSemesterId == 'all'
                                ? 'Indeks Prestasi Kumulatif (IPK)  : ${computedGpa.toStringAsFixed(2)}'
                                : 'Indeks Prestasi Semester (IPS) : ${computedGpa.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),

                // Tanda Tangan
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 12),
                        pw.Text('Menyetujui,', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Dosen Wali Akademik', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 50),
                        pw.Text('( ___________________________ )', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Medan, $dateStr', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Ketua Program Studi,', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 50),
                        pw.Text('( ___________________________ )', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'KHS_${widget.studentDetails['nim']}_$_selectedSemesterId.pdf',
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KHS & Transkrip Nilai"),
        elevation: 0,
        automaticallyImplyLeading: !widget.isTab,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Pilih Semester / Transkrip",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _selectedSemesterId,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.calendar_month_outlined, color: AppTheme.primary),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: 'all',
                                      child: Text("Transkrip Kumulatif (Semua)"),
                                    ),
                                    ..._semesters.map((s) {
                                      return DropdownMenuItem<String>(
                                        value: s['id'],
                                        child: Text(s['nama'], overflow: TextOverflow.ellipsis),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedSemesterId = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            onPressed: _filteredGrades.isEmpty ? null : _printPdf,
                            icon: const Icon(Icons.print_outlined, size: 20, color: Colors.white),
                            label: const Text("CETAK", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GPA Overview Cards
                  _buildGpaOverview(),
                  const SizedBox(height: 20),

                  // Nilai List
                  const Text(
                    "Daftar Nilai Kuliah",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  _buildGradesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGpaOverview() {
    final totalCredits = _totalSks;
    final computedGpa = _gpa;

    return Row(
      children: [
        // Card SKS
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.collections_bookmark_outlined, color: AppTheme.secondary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total SKS", style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                        const SizedBox(height: 2),
                        Text(
                          "$totalCredits SKS",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Card IPS / IPK
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_graph_outlined, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedSemesterId == 'all' ? "IP Kumulatif" : "IP Semester",
                          style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          computedGpa.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradesList() {
    final list = _filteredGrades;
    if (list.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.grade_outlined, color: Colors.grey.shade400, size: 48),
                const SizedBox(height: 12),
                const Text(
                  "Belum ada nilai yang diinput oleh dosen untuk semester ini.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final row = list[index];
        final k = row['kelas'] ?? {};
        final mk = k['mata_kuliah'] ?? {};
        final dName = k['dosen']?['users']?['nama'] ?? '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Grade Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: row['grade'] != null
                        ? _getGradeColor(row['grade']).withOpacity(0.1)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      row['grade'] ?? '-',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: row['grade'] != null
                            ? _getGradeColor(row['grade'])
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Class Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "[${mk['kode'] ?? ''}] ${mk['nama'] ?? ''}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Dosen: $dName | SKS: ${mk['sks'] ?? 0}",
                        style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildMiniBadge("Tugas: ${formatNilai(row['nilai_tugas'])}"),
                          _buildMiniBadge("UTS: ${formatNilai(row['nilai_uts'])}"),
                          _buildMiniBadge("UAS: ${formatNilai(row['nilai_uas'])}"),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Final Score Label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Nilai Akhir", style: TextStyle(fontSize: 9, color: AppTheme.textLight)),
                    const SizedBox(height: 1),
                    Text(
                      formatNilai(row['nilai_akhir']),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
    );
  }
}
