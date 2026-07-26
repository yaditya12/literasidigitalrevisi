import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/materi.dart';
import '../services/auth_service.dart';
import 'achievements_page.dart';
import 'add_materi_page.dart';
import 'join_quiz_page.dart';
import 'leaderboard_page.dart';
import 'login_page.dart';
import 'manage_simulation_page.dart';
import 'materi_page.dart';
import 'profile_page.dart';
import 'simulation_page.dart';
import 'upload_materi_link_page.dart';
import 'video_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _defaultCoverUrl =
      'https://img.freepik.com/free-vector/online-education-concept_23-2148532793.jpg';

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Buat Kelas / Kuis Baru',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 15),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.book, color: Colors.indigo),
                  ),
                  title: const Text('Teks Materi & Kuis'),
                  subtitle: const Text('Ketik bahan bacaan dan kuis di aplikasi'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddMateriPage(isQuizOnly: false),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.quiz, color: Colors.orange),
                  ),
                  title: const Text('Kuis Saja (Tantangan)'),
                  subtitle: const Text('Hanya buat kuis dengan Kode Unik'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddMateriPage(isQuizOnly: true),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOptionsDialog(String docId, MateriModel item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Opsi: ${item.title}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMateriPage(
                      materi: item,
                      docId: docId,
                      isQuizOnly: item.content.isEmpty,
                    ),
                  ),
                );
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('materi')
                    .doc(docId)
                    .delete();
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService().logout();

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openExternalLink(String link) async {
    final String cleanLink = link.trim();

    if (cleanLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link materi kosong')),
      );
      return;
    }

    final Uri? url = Uri.tryParse(cleanLink);

    if (url == null || !url.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format link tidak valid')),
      );
      return;
    }

    final bool opened = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka link tersebut')),
      );
    }
  }

  void _showMateriDialog({
    required String docId,
    required String title,
    required String type,
    required String userRole,
    required String coverUrl,
    required String link,
  }) {
    final String imageUrl = coverUrl.trim().isNotEmpty
        ? coverUrl.trim()
        : _defaultCoverUrl;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: Colors.indigo.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      userRole == 'teacher'
                          ? 'Anda dapat membuka atau menghapus materi ini.'
                          : 'Materi ini akan dibuka di browser/aplikasi Anda.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        if (userRole == 'teacher') ...[
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(
                                  color: Colors.redAccent,
                                ),
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                await FirebaseFirestore.instance
                                    .collection('materi_siap_pakai')
                                    .doc(docId)
                                    .delete();
                              },
                              child: const Text(
                                'Hapus',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (userRole != 'teacher') ...[
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Batal',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: userRole == 'teacher'
                                  ? const Color(0xFF00BFA5)
                                  : const Color(0xFF6A11CB),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _openExternalLink(link);
                            },
                            child: Text(
                              userRole == 'teacher' ? 'Buka Materi' : 'Buka',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _parseQuiz(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  String _stringValue(Map<String, dynamic> data, String key, String fallback) {
    final dynamic value = data[key];

    if (value == null) return fallback;

    final String text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        String userRole = 'student';
        String displayName = 'Student';
        String photoUrl = '';
        int points = 0;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final Map<String, dynamic>? userData = userSnapshot.data!.data();

          if (userData != null) {
            userRole = (userData['role'] ?? 'student').toString();
            displayName = (userData['username'] ?? 'User').toString();
            photoUrl = (userData['photoUrl'] ?? '').toString();
            points = (userData['points'] is num)
                ? (userData['points'] as num).toInt()
                : 0;
          }
        }

        final bool isTeacher = userRole == 'teacher';

        final Color primaryColor = isTeacher
            ? const Color(0xFF00BFA5)
            : const Color(0xFF6A11CB);

        final Color gradientEndColor = isTeacher
            ? const Color(0xFF00897B)
            : const Color(0xFF2575FC);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          floatingActionButton: isTeacher
              ? FloatingActionButton(
                  backgroundColor: primaryColor,
                  onPressed: _showCreateOptions,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(
                displayName,
                points,
                userRole,
                photoUrl,
                primaryColor,
                gradientEndColor,
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickMenu(
                          context,
                          Icons.add,
                          'Join Quiz',
                          const Color(0xFF9C27B0),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JoinQuizPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 15),
                        _buildQuickMenu(
                          context,
                          Icons.bar_chart,
                          'Rank',
                          const Color(0xFF00BFA5),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LeaderboardPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 15),
                        _buildQuickMenu(
                          context,
                          Icons.emoji_events,
                          'Badge',
                          const Color(0xFFFF7043),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AchievementsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 15),
                        _buildQuickMenu(
                          context,
                          Icons.security,
                          'Simulasi',
                          Colors.blue,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SimulationPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 15),
                        _buildQuickMenu(
                          context,
                          Icons.play_circle_fill,
                          'Video',
                          Colors.redAccent,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VideoPage(),
                              ),
                            );
                          },
                        ),
                        if (isTeacher) ...[
                          const SizedBox(width: 15),
                          _buildQuickMenu(
                            context,
                            Icons.edit_document,
                            'Kelola',
                            Colors.orange,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManageSimulationPage(),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(width: 15),
                        _buildQuickMenu(
                          context,
                          Icons.logout,
                          'Logout',
                          Colors.redAccent,
                          _showLogoutDialog,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTeacher
                            ? 'Ruang Guru: Materi Eksternal'
                            : 'Materi Literasi Tambahan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('materi_siap_pakai')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty && !isTeacher) {
                    return const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 150,
                        child: Center(
                          child: Text(
                            'Belum ada materi tambahan dari guru.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }

                  final int itemCount = isTeacher ? docs.length + 1 : docs.length;

                  return SliverToBoxAdapter(
                    child: Container(
                      height: 220,
                      margin: const EdgeInsets.only(top: 10),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          if (isTeacher && index == 0) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const UploadMateriLinkPage(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 130,
                                margin: const EdgeInsets.only(right: 15),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle,
                                      size: 45,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Tambah\nMateri Baru',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final int dataIndex = isTeacher ? index - 1 : index;
                          final doc = docs[dataIndex];
                          final Map<String, dynamic> materi = doc.data();

                          final String title =
                              _stringValue(materi, 'title', 'Tanpa Judul');
                          final String type =
                              _stringValue(materi, 'type', 'Materi');
                          final String cover =
                              _stringValue(materi, 'cover', _defaultCoverUrl);
                          final String link = _stringValue(materi, 'link', '');

                          return GestureDetector(
                            onTap: () {
                              _showMateriDialog(
                                docId: doc.id,
                                title: title,
                                type: type,
                                userRole: userRole,
                                coverUrl: cover,
                                link: link,
                              );
                            },
                            child: Container(
                              width: 130,
                              margin: const EdgeInsets.only(right: 15),
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 6,
                                            offset: const Offset(2, 4),
                                          ),
                                        ],
                                        image: DecorationImage(
                                          image: NetworkImage(cover),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.6),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        alignment: Alignment.bottomCenter,
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.link,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                type,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                  child: Text(
                    'Kelas & Kuis Interaktif',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('materi')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, materiSnapshot) {
                  if (materiSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = materiSnapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Belum ada materi kelas.'),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        mainAxisExtent: 185,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = docs[index];
                          final Map<String, dynamic> data = doc.data();

                          final MateriModel item = MateriModel(
                            id: doc.id,
                            title: _stringValue(
                              data,
                              'title',
                              'Tanpa Judul',
                            ),
                            content: _stringValue(data, 'content', ''),
                            quiz: _parseQuiz(data['quiz']),
                          );

                          final bool isQuizOnly = item.content.trim().isEmpty;

                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MateriPage(materi: item),
                                ),
                              );
                            },
                            onLongPress: isTeacher
                                ? () => _showOptionsDialog(doc.id, item)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: isQuizOnly
                                    ? Colors.orange.shade400
                                    : Colors.indigo.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(top: 25),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              item.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 5,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            isQuizOnly
                                                ? 'Tantangan Kuis'
                                                : 'Materi & Kuis',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.9),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isQuizOnly
                                                ? Colors.orange.shade700
                                                : Colors.indigo.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: docs.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(
    String name,
    int points,
    String role,
    String photoUrl,
    Color primaryColor,
    Color gradientEnd,
  ) {
    final String avatarUrl = photoUrl.trim().isNotEmpty
        ? photoUrl.trim()
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff';

    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      automaticallyImplyLeading: false,
      backgroundColor: primaryColor,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'ZonaDigi',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.only(
            top: 125,
            left: 20,
            right: 20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfilePage(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white24,
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Selamat Datang!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        role == 'teacher' ? '(Guru)' : '(Siswa)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMenu(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 65,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}