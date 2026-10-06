import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentQuizBestScore {
  final String studentUid;
  final String studentName;
  final String studentEmail;
  final String studentNisn;
  final String? photoUrl;
  final String quizId;
  final String quizTitle;
  final int bestScore;
  final int attemptsUsed;
  final DateTime? lastAttemptDate;

  StudentQuizBestScore({
    required this.studentUid,
    required this.studentName,
    required this.studentEmail,
    required this.studentNisn,
    this.photoUrl,
    required this.quizId,
    required this.quizTitle,
    required this.bestScore,
    required this.attemptsUsed,
    this.lastAttemptDate,
  });
}

class QuizHistoryPage extends StatefulWidget {
  final String? userRole;
  const QuizHistoryPage({super.key, this.userRole});

  @override
  State<QuizHistoryPage> createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> with SingleTickerProviderStateMixin {
  String? _effectiveRole;
  bool _isLoadingRole = true;

  // State untuk Akun Guru
  TabController? _tabController;
  List<StudentQuizBestScore> _allStudentScores = [];
  bool _isLoadingTeacherData = false;
  String _searchQuery = "";
  String _selectedQuizFilter = "Semua Kuis";
  String _selectedSortBy = "Nilai Tertinggi"; // Default: nilai paling bagus
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determineRole();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determineRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (widget.userRole != null && widget.userRole!.isNotEmpty) {
      _effectiveRole = widget.userRole;
      _initRoleView();
      return;
    }

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _effectiveRole = doc.data()?['role'] ?? 'student';
        } else {
          _effectiveRole = 'student';
        }
      } catch (_) {
        _effectiveRole = 'student';
      }
    } else {
      _effectiveRole = 'student';
    }

    _initRoleView();
  }

  void _initRoleView() {
    if (_effectiveRole == 'teacher') {
      _tabController = TabController(length: 2, vsync: this);
      _fetchTeacherScores();
    }
    if (mounted) {
      setState(() {
        _isLoadingRole = false;
      });
    }
  }

  Future<void> _fetchTeacherScores() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTeacherData = true;
    });

    try {
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      List<StudentQuizBestScore> results = [];

      final futures = usersSnap.docs.map((userDoc) async {
        final userData = userDoc.data();
        final studentUid = userDoc.id;
        final studentName = userData['username'] ?? 'Siswa';
        final studentEmail = userData['email'] ?? '';
        final studentNisn = userData['nisn'] ?? '';
        final photoUrl = userData['photoUrl'];

        // 1. Coba ambil dari koleksi quiz_attempts
        final attemptsSnap = await userDoc.reference.collection('quiz_attempts').get();

        if (attemptsSnap.docs.isNotEmpty) {
          for (var attDoc in attemptsSnap.docs) {
            final aData = attDoc.data();
            final quizId = aData['quizId'] ?? attDoc.id;
            final quizTitle = aData['quizTitle'] ?? 'Kuis';
            final bestScore = (aData['bestScore'] ?? aData['lastScore'] ?? 0) as int;
            final attemptsUsed = (aData['attemptsUsed'] ?? 1) as int;
            DateTime? lastDate;
            if (aData['updatedAt'] != null && aData['updatedAt'] is Timestamp) {
              lastDate = (aData['updatedAt'] as Timestamp).toDate();
            }

            results.add(StudentQuizBestScore(
              studentUid: studentUid,
              studentName: studentName,
              studentEmail: studentEmail,
              studentNisn: studentNisn,
              photoUrl: photoUrl,
              quizId: quizId,
              quizTitle: quizTitle,
              bestScore: bestScore,
              attemptsUsed: attemptsUsed,
              lastAttemptDate: lastDate,
            ));
          }
        } else {
          // 2. Fallback: jika belum ada quiz_attempts, cari dari history dan ambil skor tertinggi
          final histSnap = await userDoc.reference.collection('history').get();
          if (histSnap.docs.isNotEmpty) {
            Map<String, Map<String, dynamic>> quizMap = {};
            for (var hDoc in histSnap.docs) {
              final hData = hDoc.data();
              final qTitle = hData['quizTitle'] ?? 'Kuis';
              final score = (hData['score'] ?? 0) as int;
              DateTime? dt;
              if (hData['timestamp'] != null && hData['timestamp'] is Timestamp) {
                dt = (hData['timestamp'] as Timestamp).toDate();
              }

              if (!quizMap.containsKey(qTitle) || score > (quizMap[qTitle]!['bestScore'] as int)) {
                quizMap[qTitle] = {
                  'quizId': hData['quizId'] ?? qTitle,
                  'quizTitle': qTitle,
                  'bestScore': score,
                  'attempts': (quizMap[qTitle]?['attempts'] ?? 0) + 1,
                  'date': dt ?? quizMap[qTitle]?['date'],
                };
              } else {
                quizMap[qTitle]!['attempts'] = (quizMap[qTitle]!['attempts'] as int) + 1;
              }
            }

            for (var entry in quizMap.values) {
              results.add(StudentQuizBestScore(
                studentUid: studentUid,
                studentName: studentName,
                studentEmail: studentEmail,
                studentNisn: studentNisn,
                photoUrl: photoUrl,
                quizId: entry['quizId'],
                quizTitle: entry['quizTitle'],
                bestScore: entry['bestScore'],
                attemptsUsed: entry['attempts'],
                lastAttemptDate: entry['date'],
              ));
            }
          }
        }
      });

      await Future.wait(futures);

      if (mounted) {
        setState(() {
          _allStudentScores = results;
          _isLoadingTeacherData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTeacherData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat nilai murid: $e")),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Waktu tidak diketahui";
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return "Waktu tidak diketahui";
    }

    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    String hour = dt.hour.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');

    return "$day-$month-${dt.year} pukul $hour:$minute";
  }

  // BADGE NILAI CANTIK & BEBAS OVERFLOW
  Widget _buildScoreBadge(int score, {String label = "NILAI"}) {
    final bool isPassed = score >= 70;
    final Color bg = isPassed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final Color border = isPassed ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80);
    final Color textColor = isPassed ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

    return Container(
      constraints: const BoxConstraints(minWidth: 58),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? Colors.green : Colors.orange).withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$score",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_isLoadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Riwayat Kuis"),
          backgroundColor: const Color(0xFF6A11CB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text("Silakan login kembali")),
      );
    }

    final bool isTeacher = _effectiveRole == 'teacher';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text(
          isTeacher ? "Riwayat & Nilai Kuis" : "Riwayat Kuis",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: isTeacher && _tabController != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.amber,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.leaderboard_rounded), text: "Nilai Siswa"),
                  Tab(icon: Icon(Icons.person_rounded), text: "Riwayat Saya"),
                ],
              )
            : null,
      ),
      body: isTeacher && _tabController != null
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildTeacherView(),
                _buildMyHistoryView(user.uid),
              ],
            )
          : _buildMyHistoryView(user.uid),
    );
  }

  // ================= VIEW RIWAYAT PRIBADI (SISWA / GURU) =================
  Widget _buildMyHistoryView(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 12),
                const Text(
                  "Belum ada riwayat kuis.",
                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final score = (data['score'] ?? 0) as int;
            final title = data['quizTitle'] ?? "Kuis";
            final String date = _formatDate(data['timestamp']);
            final bool isPassed = score >= 70;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              elevation: 1,
              shadowColor: Colors.black.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon status
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isPassed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPassed ? Icons.check_circle_rounded : Icons.replay_rounded,
                        color: isPassed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Detail judul dan tanggal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  date,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPassed ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPassed ? "Lulus" : "Perlu Peningkatan",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isPassed ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Tampilan Badge Nilai Cantik & Tidak Overflow
                    _buildScoreBadge(score, label: "NILAI"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= VIEW KHUSUS GURU (NILAI MURID TERBAIK) =================
  Widget _buildTeacherView() {
    if (_isLoadingTeacherData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6A11CB)),
            SizedBox(height: 14),
            Text("Memuat data nilai seluruh siswa...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Ambil daftar unik judul kuis untuk filter
    final Set<String> quizTitles = {"Semua Kuis"};
    for (var item in _allStudentScores) {
      quizTitles.add(item.quizTitle);
    }

    // Terapkan filter & pencarian
    List<StudentQuizBestScore> filteredList = _allStudentScores.where((item) {
      final matchesSearch = item.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.studentNisn.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesQuiz = _selectedQuizFilter == "Semua Kuis" || item.quizTitle == _selectedQuizFilter;
      return matchesSearch && matchesQuiz;
    }).toList();

    // Urutkan data
    if (_selectedSortBy == "Nilai Tertinggi") {
      filteredList.sort((a, b) => b.bestScore.compareTo(a.bestScore));
    } else if (_selectedSortBy == "Nama Siswa (A-Z)") {
      filteredList.sort((a, b) => a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase()));
    } else if (_selectedSortBy == "Terbaru") {
      filteredList.sort((a, b) {
        if (a.lastAttemptDate == null) return 1;
        if (b.lastAttemptDate == null) return -1;
        return b.lastAttemptDate!.compareTo(a.lastAttemptDate!);
      });
    }

    // Hitung ringkasan statistik
    final int totalPengerjaan = filteredList.length;
    final double rataRata = totalPengerjaan > 0
        ? filteredList.map((e) => e.bestScore).reduce((a, b) => a + b) / totalPengerjaan
        : 0.0;
    final int skorTertinggi = totalPengerjaan > 0
        ? filteredList.map((e) => e.bestScore).reduce((a, b) => a > b ? a : b)
        : 0;

    return RefreshIndicator(
      color: const Color(0xFF6A11CB),
      onRefresh: _fetchTeacherScores,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Banner Ringkasan Statistik
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A11CB).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Ringkasan Nilai Siswa",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Total Pengerjaan", "$totalPengerjaan", Icons.people_outline_rounded),
                    Container(height: 35, width: 1, color: Colors.white24),
                    _buildStatItem("Rata-Rata", rataRata.toStringAsFixed(1), Icons.show_chart_rounded),
                    Container(height: 35, width: 1, color: Colors.white24),
                    _buildStatItem("Nilai Tertinggi", "$skorTertinggi", Icons.emoji_events_rounded),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Cari nama siswa atau NISN...",
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6A11CB)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = "";
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 1.5),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
          ),
          const SizedBox(height: 12),

          // Baris Filter Kuis & Urutan
          Row(
            children: [
              // Dropdown Filter Kuis
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: quizTitles.contains(_selectedQuizFilter) ? _selectedQuizFilter : "Semua Kuis",
                      icon: const Icon(Icons.filter_list_rounded, size: 20, color: Color(0xFF6A11CB)),
                      items: quizTitles.map((title) {
                        return DropdownMenuItem<String>(
                          value: title,
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (newVal) {
                        if (newVal != null) {
                          setState(() {
                            _selectedQuizFilter = newVal;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Dropdown Pengurutan (Default: Nilai Tertinggi / Nilai Paling Bagus)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSortBy,
                    icon: const Icon(Icons.sort_rounded, size: 20, color: Color(0xFF6A11CB)),
                    items: const [
                      DropdownMenuItem(
                        value: "Nilai Tertinggi",
                        child: Text("Nilai Tertinggi", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      DropdownMenuItem(
                        value: "Nama Siswa (A-Z)",
                        child: Text("Nama (A-Z)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      DropdownMenuItem(
                        value: "Terbaru",
                        child: Text("Terbaru", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ],
                    onChanged: (newVal) {
                      if (newVal != null) {
                        setState(() {
                          _selectedSortBy = newVal;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daftar Kartu Nilai Siswa
          if (filteredList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _allStudentScores.isEmpty
                        ? "Belum ada siswa yang mengerjakan kuis."
                        : "Tidak ada siswa yang cocok dengan filter pencarian.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ],
              ),
            )
          else
            ...List.generate(filteredList.length, (index) {
              final item = filteredList[index];
              final bool isPassed = item.bestScore >= 70;
              final String date = _formatDate(item.lastAttemptDate);

              // Ranking Badge untuk pengurutan nilai tertinggi
              Widget? rankWidget;
              if (_selectedSortBy == "Nilai Tertinggi") {
                if (index == 0) {
                  rankWidget = _buildMedalBadge("🥇", Colors.amber.shade700);
                } else if (index == 1) {
                  rankWidget = _buildMedalBadge("🥈", Colors.blueGrey.shade600);
                } else if (index == 2) {
                  rankWidget = _buildMedalBadge("🥉", Colors.brown.shade400);
                } else {
                  rankWidget = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "#${index + 1}",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                  );
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                elevation: 1,
                shadowColor: Colors.black.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar Siswa
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF6A11CB).withOpacity(0.12),
                            backgroundImage: (item.photoUrl != null && item.photoUrl!.isNotEmpty)
                                ? NetworkImage(item.photoUrl!)
                                : NetworkImage("https://ui-avatars.com/api/?name=${item.studentName}&background=random&size=64&color=fff"),
                          ),
                          if (rankWidget != null)
                            Positioned(
                              bottom: -4,
                              right: -4,
                              child: rankWidget,
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),

                      // Informasi Siswa & Kuis
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.studentNisn.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                "NISN: ${item.studentNisn}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 13, color: Color(0xFF6A11CB)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.quizTitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPassed ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPassed ? "Lulus" : "Perlu Bimbingan",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isPassed ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh_rounded, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${item.attemptsUsed}x coba",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    date,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Tampilan Nilai Terbaik
                      _buildScoreBadge(item.bestScore, label: "TERBAIK"),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMedalBadge(String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 3,
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}