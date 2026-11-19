import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studio_track/data/designers_list.dart';

class LeaveReportScreen extends StatefulWidget {
  final VoidCallback onNavigateToWorkboard;
  final VoidCallback onNavigateToHoursReport;
  final VoidCallback? onNavigateToLogin;

  const LeaveReportScreen({
    super.key,
    required this.onNavigateToWorkboard,
    required this.onNavigateToHoursReport,
    this.onNavigateToLogin,
  });

  @override
  State<LeaveReportScreen> createState() => _LeaveReportScreenState();
}

class _LeaveReportScreenState extends State<LeaveReportScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        final isVeryCompact = constraints.maxWidth < 600;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFC),
          body: Column(
            children: [
              _buildTopNav(isCompact: isCompact, isVeryCompact: isVeryCompact),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVeryCompact ? 16 : (isCompact ? 24 : 36),
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(isNarrow: isCompact),
                      const SizedBox(height: 24),
                      _buildHeroComingSoonCard(isCompact: isCompact),
                      const SizedBox(height: 28),
                      _buildRoadmapSection(isCompact: isCompact),
                      const SizedBox(height: 28),
                      _buildMockPreviewTableCard(isCompact: isCompact),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TOP NAVIGATION BAR ---
  Widget _buildTopNav({required bool isCompact, required bool isVeryCompact}) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 14 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAEFF5))),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 90,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF25206A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/logo/exouzia_logo.webp',
                    width: 80,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.layers_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isVeryCompact ? 'Studio' : 'Design Media Studio',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          SizedBox(width: isCompact ? 12 : 28),
          _buildNavTab('Workboard', isActive: false, onTap: widget.onNavigateToWorkboard),
          const SizedBox(width: 6),
          _buildNavTab('Hours Report', isActive: false, onTap: widget.onNavigateToHoursReport),
          const SizedBox(width: 6),
          // _buildNavTab('Leave Report', isActive: true, onTap: () {}),
          const Spacer(),
          if (!isVeryCompact) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Module Progressing',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (widget.onNavigateToLogin != null)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onNavigateToLogin,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'SA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4338CA),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavTab(String title, {required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF1E1B4B) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeaderSection({required bool isNarrow}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'ATELIER OPERATIONS • ATTENDANCE & LEAVE MODULE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              'Leave Report',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.6,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timelapse_rounded, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 5),
                  Text(
                    'PROGRESSING',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB45309),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.rocket_launch_outlined, size: 14, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 5),
                  Text(
                    'COMING SOON',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4338CA),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Studio absence management, vacation requests, paid-time-off (PTO) allowances, and designer roster availability.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // --- HERO COMING SOON / PROGRESSING CARD ---
  Widget _buildHeroComingSoonCard({required bool isCompact}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEEF2FF).withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFFBEB).withValues(alpha: 0.5),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.beach_access_rounded,
                          size: 28,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leave Management & Attendance Tracking Under Development',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'We are engineering a full-suite leave management system for Design Media Studio. '
                            'This screen is progressing through active implementation to sync designer PTO, sick leave, '
                            'and casual absences directly with the real-time Workboard capacity calculations.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Progress status bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.engineering_rounded, size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 8),
                              Text(
                                'Development Milestone: Phase 2 of 4',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '65% Progressing',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.65,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completed: Data schema & Firestore structures • Current focus: Multi-tier approval flow & calendar views',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Action Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onNavigateToWorkboard,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text('Back to Workboard', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25206A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.onNavigateToHoursReport,
                      icon: const Icon(Icons.bar_chart_rounded, size: 16),
                      label: Text('View Hours Report', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E293B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  }

  // --- ROADMAP & UPCOMING CAPABILITIES ---
  Widget _buildRoadmapSection({required bool isCompact}) {
    final features = [
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'One-Click Leave Requests',
        'desc': 'Submit vacation, personal leave, or medical absence requests with instant lead notification.',
        'tag': 'IN PROGRESS',
        'tagColor': const Color(0xFFD97706),
        'tagBg': const Color(0xFFFFFBEB),
      },
      {
        'icon': Icons.groups_rounded,
        'title': 'Studio Coverage Calendar',
        'desc': 'Visual timeline showing designer presence to maintain minimum creative roster coverage during deadlines.',
        'tag': 'NEXT SPRINT',
        'tagColor': const Color(0xFF4F46E5),
        'tagBg': const Color(0xFFEEF2FF),
      },
      {
        'icon': Icons.sync_alt_rounded,
        'title': 'Dynamic Workboard Sync',
        'desc': 'Approved leave automatically updates daily 7.5h allocation goals and rebalances active task pipelines.',
        'tag': 'NEXT SPRINT',
        'tagColor': const Color(0xFF4F46E5),
        'tagBg': const Color(0xFFEEF2FF),
      },
      {
        'icon': Icons.file_download_outlined,
        'title': 'Leave Quota & Export',
        'desc': 'Automatic tracking of 18 annual leave allowances per designer with monthly payroll CSV export.',
        'tag': 'PLANNED',
        'tagColor': const Color(0xFF64748B),
        'tagBg': const Color(0xFFF1F5F9),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPCOMING CAPABILITIES IN THIS MODULE',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final cardWidth = isCompact ? box.maxWidth : (box.maxWidth - 36) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: features.map((f) {
                return Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Icon(f['icon'] as IconData, size: 20, color: const Color(0xFF25206A)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: f['tagBg'] as Color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              f['tag'] as String,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: f['tagColor'] as Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        f['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f['desc'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- MOCK PREVIEW TABLE CARD ---
  Widget _buildMockPreviewTableCard({required bool isCompact}) {
    final previewRows = [
      {
        'designer': designers.isNotEmpty ? designers[0].name : 'Jawad',
        'type': 'Casual Leave',
        'typeColor': const Color(0xFF3B82F6),
        'dates': 'Nov 12 - Nov 13 (2 Days)',
        'reason': 'Personal family event',
        'status': 'Approved',
        'statusBg': const Color(0xFFECFDF5),
        'statusColor': const Color(0xFF047857),
        'remaining': '14 days remaining',
      },
      {
        'designer': designers.length > 1 ? designers[1].name : 'Sabith Amjadi',
        'type': 'Annual Vacation',
        'typeColor': const Color(0xFF8B5CF6),
        'dates': 'Dec 22 - Dec 29 (6 Days)',
        'reason': 'Year-end holiday',
        'status': 'Reviewing',
        'statusBg': const Color(0xFFFFFBEB),
        'statusColor': const Color(0xFFB45309),
        'remaining': '12 days remaining',
      },
      {
        'designer': designers.length > 2 ? designers[2].name : 'Muhd. Nizam',
        'type': 'Sick Leave',
        'typeColor': const Color(0xFFEF4444),
        'dates': 'Nov 04 (1 Day)',
        'reason': 'Medical recovery',
        'status': 'Completed',
        'statusBg': const Color(0xFFF1F5F9),
        'statusColor': const Color(0xFF475569),
        'remaining': '16 days remaining',
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Preview Roster Prototype',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'DEMO ONLY',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Active schema connected',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAEFF5)),
          // Table header
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('DESIGNER', style: GoogleFonts.jetBrainsMono(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                ),
                Expanded(
                  flex: 2,
                  child: Text('LEAVE TYPE', style: GoogleFonts.jetBrainsMono(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                ),
                if (!isCompact)
                  Expanded(
                    flex: 3,
                    child: Text('SCHEDULED DATES', style: GoogleFonts.jetBrainsMono(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                  ),
                Expanded(
                  flex: 2,
                  child: Text('STATUS', style: GoogleFonts.jetBrainsMono(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                ),
                if (!isCompact)
                  Expanded(
                    flex: 2,
                    child: Text('BALANCE', style: GoogleFonts.jetBrainsMono(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAEFF5)),
          // Rows
          ...previewRows.map((r) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFFEEF2FF),
                          child: Text(
                            (r['designer'] as String).substring(0, 1),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r['designer'] as String,
                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      r['type'] as String,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: r['typeColor'] as Color),
                    ),
                  ),
                  if (!isCompact)
                    Expanded(
                      flex: 3,
                      child: Text(
                        r['dates'] as String,
                        style: GoogleFonts.jetBrainsMono(fontSize: 11.5, color: const Color(0xFF475569)),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: r['statusBg'] as Color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r['status'] as String,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: r['statusColor'] as Color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isCompact)
                    Expanded(
                      flex: 2,
                      child: Text(
                        r['remaining'] as String,
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

