import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  static const Color _headerStart = Color(0xFFFF8A3D);
  static const Color _headerEnd = Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text('User belum login'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _headerStart),
            );
          }

          int currentPoints = 0;

          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final data = userSnapshot.data!.data();
            if (data != null) {
              currentPoints = _readInt(data['points']);
            }
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('history')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, historySnapshot) {
              if (historySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _headerStart),
                );
              }

              final historyDocs = historySnapshot.data?.docs ?? [];
              final int totalQuizDone = historyDocs.length;

              int perfectScores = 0;
              for (final doc in historyDocs) {
                final data = doc.data();
                final int correctAnswers = _readInt(data['correctAnswers']);
                final int totalQuestions = _readInt(data['totalQuestions']);

                if (totalQuestions > 0 && correctAnswers == totalQuestions) {
                  perfectScores++;
                }
              }

              final achievements = _buildDigitalLiteracyAchievements(
                currentPoints: currentPoints,
                totalQuizDone: totalQuizDone,
                perfectScores: perfectScores,
              );

              final int unlockedCount =
                  achievements.where((item) => item.unlocked).length;

              return Column(
                children: [
                  _buildHeader(
                    context,
                    unlockedCount: unlockedCount,
                    total: achievements.length,
                    currentPoints: currentPoints,
                    totalQuizDone: totalQuizDone,
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: achievements.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.58,
                      ),
                      itemBuilder: (context, index) {
                        return _buildBadgeCard(achievements[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<_AchievementItem> _buildDigitalLiteracyAchievements({
    required int currentPoints,
    required int totalQuizDone,
    required int perfectScores,
  }) {
    return [
      _AchievementItem(
        title: 'Warga Digital Baru',
        desc: 'Berhasil masuk dan memulai perjalanan literasi digital',
        icon: Icons.person_add_alt_1,
        unlocked: true,
        color: const Color(0xFFFF9800),
      ),
      _AchievementItem(
        title: 'Penjelajah Digital',
        desc: 'Selesaikan 3 kuis literasi digital',
        icon: Icons.explore,
        unlocked: totalQuizDone >= 3,
        color: const Color(0xFF42A5F5),
      ),
      _AchievementItem(
        title: 'Detektif Hoaks',
        desc: 'Kumpulkan 500 poin dari kuis literasi digital',
        icon: Icons.fact_check,
        unlocked: currentPoints >= 500,
        color: const Color(0xFF8E24AA),
      ),
      _AchievementItem(
        title: 'Penjaga Privasi',
        desc: 'Capai 1.500 poin sebagai pelindung data pribadi',
        icon: Icons.privacy_tip,
        unlocked: currentPoints >= 1500,
        color: const Color(0xFF26A69A),
      ),
      _AchievementItem(
        title: 'Ahli Keamanan Akun',
        desc: 'Raih 3 nilai sempurna pada kuis',
        icon: Icons.shield,
        unlocked: perfectScores >= 3,
        color: const Color(0xFFEF5350),
      ),
      _AchievementItem(
        title: 'Netizen Beretika',
        desc: 'Capai 3.000 poin dan tunjukkan etika digital yang baik',
        icon: Icons.forum,
        unlocked: currentPoints >= 3000,
        color: const Color(0xFFFF7043),
      ),
      _AchievementItem(
        title: 'Pemburu Phishing',
        desc: 'Selesaikan 8 kuis untuk melatih kewaspadaan digital',
        icon: Icons.gpp_good,
        unlocked: totalQuizDone >= 8,
        color: const Color(0xFF5C6BC0),
      ),
      _AchievementItem(
        title: 'Duta Literasi Digital',
        desc: 'Capai 5.000 poin dan jadilah teladan literasi digital',
        icon: Icons.workspace_premium,
        unlocked: currentPoints >= 5000,
        color: const Color(0xFFFFB300),
      ),
    ];
  }

  Widget _buildHeader(
    BuildContext context, {
    required int unlockedCount,
    required int total,
    required int currentPoints,
    required int totalQuizDone,
  }) {
    final double progress = total == 0 ? 0 : unlockedCount / total;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_headerStart, _headerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 16),
              const Text(
                'Badge Literasi Digital',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$unlockedCount dari $total badge berhasil dibuka',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      icon: Icons.stars_rounded,
                      label: 'Poin',
                      value: '$currentPoints',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatChip(
                      icon: Icons.quiz_rounded,
                      label: 'Kuis Selesai',
                      value: '$totalQuizDone',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(_AchievementItem item) {
    final bool isUnlocked = item.unlocked;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUnlocked
              ? item.color.withOpacity(0.25)
              : Colors.grey.shade200,
          width: isUnlocked ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnlocked
                ? item.color.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon lingkaran badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? item.color.withOpacity(0.14)
                  : Colors.grey.shade100,
              border: Border.all(
                color: isUnlocked
                    ? item.color.withOpacity(0.3)
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Icon(
              item.icon,
              size: 25,
              color: isUnlocked ? item.color : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          // Judul badge - fleksibel dan TIDAK AKAN PERNAH terpotong
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 46),
            child: Center(
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: isUnlocked ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Deskripsi persyaratan badge yang jelas dan terbaca
          Expanded(
            child: Center(
              child: Text(
                item.desc,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Status chip (Terbuka / Terkunci)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFFE8F5E9)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isUnlocked
                    ? const Color(0xFFA5D6A7)
                    : Colors.grey.shade300,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUnlocked
                      ? Icons.check_circle_rounded
                      : Icons.lock_outline_rounded,
                  size: 12,
                  color: isUnlocked
                      ? const Color(0xFF2E7D32)
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  isUnlocked ? 'Terbuka' : 'Terkunci',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked
                        ? const Color(0xFF2E7D32)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementItem {
  final String title;
  final String desc;
  final IconData icon;
  final bool unlocked;
  final Color color;

  const _AchievementItem({
    required this.title,
    required this.desc,
    required this.icon,
    required this.unlocked,
    required this.color,
  });
}