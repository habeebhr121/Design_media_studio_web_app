import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- DATA MODELS ---

class DesignerReport {
  final String name;
  final String role;
  final String avatarUrl;
  final String billablePercent;
  final double loggedHours;
  final double billableHours;
  final int activeTasks;
  final double quotaHours;
  final double progressPercent;

  DesignerReport({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.billablePercent,
    required this.loggedHours,
    required this.billableHours,
    required this.activeTasks,
    required this.quotaHours,
    required this.progressPercent,
  });
}

class WorkTypeDistribution {
  final String title;
  final double hours;
  final int percentage;
  final Color barColor;

  WorkTypeDistribution({
    required this.title,
    required this.hours,
    required this.percentage,
    required this.barColor,
  });
}

class HoursLogEntry {
  final String id;
  final String date;
  final String designerInitials;
  final Color initialsBg;
  final String designerName;
  final String deliverable;
  final String typeTag;
  final String timeSlot;
  final double totalHours;
  final String status;
  final Color statusBg;
  final Color statusDot;
  final Color statusText;

  HoursLogEntry({
    required this.id,
    required this.date,
    required this.designerInitials,
    required this.initialsBg,
    required this.designerName,
    required this.deliverable,
    required this.typeTag,
    required this.timeSlot,
    required this.totalHours,
    required this.status,
    required this.statusBg,
    required this.statusDot,
    required this.statusText,
  });
}

// --- HOURS REPORT SCREEN ---

class HoursReportScreen extends StatefulWidget {
  final VoidCallback onNavigateToWorkboard;

  const HoursReportScreen({
    super.key,
    required this.onNavigateToWorkboard,
  });

  @override
  State<HoursReportScreen> createState() => _HoursReportScreenState();
}

class _HoursReportScreenState extends State<HoursReportScreen> {
  String _selectedTimeframe = 'This Week';
  String _selectedDesignerFilter = 'All Designers';
  final TextEditingController _searchController = TextEditingController();

  late List<DesignerReport> _designers;
  late List<WorkTypeDistribution> _workTypes;
  late List<HoursLogEntry> _hoursLogs;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initData() {
    _designers = [
      DesignerReport(
        name: 'Elena Rostova',
        role: 'Principal Art Director',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
        billablePercent: '92% Billable',
        loggedHours: 42.5,
        billableHours: 39.0,
        activeTasks: 5,
        quotaHours: 40.0,
        progressPercent: 1.06,
      ),
      DesignerReport(
        name: 'Marcus Chen',
        role: 'Senior Motion & 3D',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
        billablePercent: '84% Billable',
        loggedHours: 38.0,
        billableHours: 32.0,
        activeTasks: 4,
        quotaHours: 40.0,
        progressPercent: 0.95,
      ),
      DesignerReport(
        name: 'Maya Patel',
        role: 'Identity & Systems',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
        billablePercent: '81% Billable',
        loggedHours: 36.0,
        billableHours: 29.0,
        activeTasks: 4,
        quotaHours: 40.0,
        progressPercent: 0.90,
      ),
      DesignerReport(
        name: 'Liam Vance',
        role: 'UI & Print Specialist',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
        billablePercent: '83% Billable',
        loggedHours: 31.5,
        billableHours: 26.0,
        activeTasks: 3,
        quotaHours: 40.0,
        progressPercent: 0.79,
      ),
    ];

    _workTypes = [
      WorkTypeDistribution(
        title: 'Brand & Logo System',
        hours: 44.0,
        percentage: 38,
        barColor: const Color(0xFF1E1B4B),
      ),
      WorkTypeDistribution(
        title: 'Poster & Editorial Print',
        hours: 35.5,
        percentage: 24,
        barColor: const Color(0xFF3B82F6),
      ),
      WorkTypeDistribution(
        title: 'Motion & Video Production',
        hours: 32.0,
        percentage: 22,
        barColor: const Color(0xFF7C2D12),
      ),
      WorkTypeDistribution(
        title: 'Art Direction & Editing',
        hours: 21.5,
        percentage: 14,
        barColor: const Color(0xFF4F46E5),
      ),
      WorkTypeDistribution(
        title: 'Internal Reviews & QA',
        hours: 15.0,
        percentage: 10,
        barColor: const Color(0xFF64748B),
      ),
    ];

    _hoursLogs = [
      HoursLogEntry(
        id: '1',
        date: 'Today, 24 Oct',
        designerInitials: 'ER',
        initialsBg: const Color(0xFFC7D2FE),
        designerName: 'Elena Rostova',
        deliverable: 'Kroma Nordic Brand Identity Guidelines',
        typeTag: 'Logo System',
        timeSlot: '09:15 - 13:45',
        totalHours: 4.5,
        status: 'Completed',
        statusBg: const Color(0xFFEFF6FF),
        statusDot: const Color(0xFF2563EB),
        statusText: const Color(0xFF1E40AF),
      ),
      HoursLogEntry(
        id: '2',
        date: 'Today, 24 Oct',
        designerInitials: 'MC',
        initialsBg: const Color(0xFFDDD6FE),
        designerName: 'Marcus Chen',
        deliverable: 'Voxel Kinetic Launch Teaser (0:30)',
        typeTag: 'Video Motion',
        timeSlot: '10:00 - 16:30',
        totalHours: 6.0,
        status: 'Completed',
        statusBg: const Color(0xFFEFF6FF),
        statusDot: const Color(0xFF2563EB),
        statusText: const Color(0xFF1E40AF),
      ),
      HoursLogEntry(
        id: '3',
        date: 'Today, 24 Oct',
        designerInitials: 'MP',
        initialsBg: const Color(0xFFFED7AA),
        designerName: 'Maya Patel',
        deliverable: 'Architectural Biennale Exhibition Poster',
        typeTag: 'Poster / Print',
        timeSlot: '11:00 - 16:15',
        totalHours: 5.25,
        status: 'Completed',
        statusBg: const Color(0xFFEFF6FF),
        statusDot: const Color(0xFF2563EB),
        statusText: const Color(0xFF1E40AF),
      ),
      HoursLogEntry(
        id: '4',
        date: 'Today, 24 Oct',
        designerInitials: 'LV',
        initialsBg: const Color(0xFFBAE6FD),
        designerName: 'Liam Vance',
        deliverable: 'Art Gallery Lookbook Layout & Pre-press',
        typeTag: 'Editorial',
        timeSlot: '13:00 - 17:30',
        totalHours: 4.5,
        status: 'In Review',
        statusBg: const Color(0xFFEEF2FF),
        statusDot: const Color(0xFF6366F1),
        statusText: const Color(0xFF4338CA),
      ),
      HoursLogEntry(
        id: '5',
        date: 'Yesterday, 23 Oct',
        designerInitials: 'ER',
        initialsBg: const Color(0xFFC7D2FE),
        designerName: 'Elena Rostova',
        deliverable: 'Foundry Type Specimen & Glyph Revisions',
        typeTag: 'Editing',
        timeSlot: '08:45 - 15:45',
        totalHours: 6.5,
        status: 'Completed',
        statusBg: const Color(0xFFEFF6FF),
        statusDot: const Color(0xFF2563EB),
        statusText: const Color(0xFF1E40AF),
      ),
      HoursLogEntry(
        id: '6',
        date: 'Yesterday, 23 Oct',
        designerInitials: 'MC',
        initialsBg: const Color(0xFFDDD6FE),
        designerName: 'Marcus Chen',
        deliverable: 'Product Rendering Studio Lighting Setup',
        typeTag: 'Video Motion',
        timeSlot: '09:30 - 17:00',
        totalHours: 7.0,
        status: 'Completed',
        statusBg: const Color(0xFFEFF6FF),
        statusDot: const Color(0xFF2563EB),
        statusText: const Color(0xFF1E40AF),
      ),
    ];
  }

  List<HoursLogEntry> get _filteredHoursLogs {
    if (_selectedDesignerFilter == 'All Designers') {
      return _hoursLogs;
    }
    return _hoursLogs.where((log) => log.designerName.contains(_selectedDesignerFilter)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopNavbar(),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 1120;
                final horizontalPadding = constraints.maxWidth < 700 ? 16.0 : 40.0;
                final contentWidth = constraints.maxWidth < 1120 ? 1120.0 : (constraints.maxWidth - horizontalPadding * 2);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(isNarrow: isNarrow),
                      const SizedBox(height: 24),
                      _buildMetricsCards(isNarrow: isNarrow),
                      const SizedBox(height: 28),
                      _buildMiddleSection(isNarrow: isNarrow),
                      const SizedBox(height: 28),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: contentWidth,
                          child: _buildDetailedHoursLogCard(),
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildFooter(isNarrow: isNarrow),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- TOP NAVBAR ---
  Widget _buildTopNavbar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEBEFF5), width: 1),
        ),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF16152B),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Center(
                  child: Icon(
                    Icons.layers_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'StudioTrack',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          _buildNavTab('Workboard', isActive: false, onTap: widget.onNavigateToWorkboard),
          const SizedBox(width: 8),
          _buildNavTab('Hours Report', isActive: true, onTap: () {}),
          const Spacer(),
          Container(
            width: 240,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E9F2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Search tasks or hours..',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF94A3B8),
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 20,
            width: 1,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '4 Active',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF312E81),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 32,
                height: 32,
                color: const Color(0xFF3B82F6),
                child: const Center(
                  child: Text('ER', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF4F46E5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'ATELIER CORE • STUDIO PRODUCTIVITY ANALYTICS',
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
        Text(
          'Hours & Output Report',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Verified billable tracking, design workload throughput, and individual allocation logs for the active visual design team.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );

    final timeframeControls = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeframePill('This Week'),
          _buildTimeframePill('This Month'),
          _buildTimeframePill('Last Month'),
          _buildTimeframePill('Custom'),
        ],
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 16),
          timeframeControls,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 20),
        timeframeControls,
      ],
    );
  }

  Widget _buildTimeframePill(String title) {
    final isSelected = _selectedTimeframe == title;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        setState(() {
          _selectedTimeframe = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    offset: Offset(0, 1),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // --- 4 METRICS CARDS ---
  Widget _buildMetricsCards({required bool isNarrow}) {
    final c1 = _buildMetricCard(
      title: 'TOTAL LOGGED',
      icon: Icons.access_time_rounded,
      iconColor: const Color(0xFF2563EB),
      mainNumber: '148',
      unit: 'hrs',
      customBottom: Row(
        children: [
          const Icon(Icons.arrow_upward_rounded, size: 13, color: Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Text(
            '+6.2% vs last cycle',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );

    final c2 = _buildMetricCard(
      title: 'BILLABLE HOURS',
      icon: Icons.verified_outlined,
      iconColor: const Color(0xFF2563EB),
      mainNumber: '126',
      unit: 'hrs',
      customBottom: Row(
        children: [
          Text(
            '85.1% utilization',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.85,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF25206A),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final c3 = _buildMetricCard(
      title: 'ACTIVE DELIVERABLES',
      icon: Icons.inventory_2_outlined,
      iconColor: const Color(0xFFB45309),
      mainNumber: '16',
      unit: 'completed',
      customBottom: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '7 queued for review',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );

    final c4 = _buildMetricCard(
      title: 'AVG DAILY / DESIGNER',
      icon: Icons.group_outlined,
      iconColor: const Color(0xFF475569),
      mainNumber: '7.4',
      unit: 'hrs/day',
      customBottom: Text(
        'Nominal base: 8.0 hrs',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10.5,
          color: const Color(0xFF64748B),
        ),
      ),
    );

    if (isNarrow) {
      return Column(
        children: [
          Row(children: [Expanded(child: c1), const SizedBox(width: 14), Expanded(child: c2)]),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: c3), const SizedBox(width: 14), Expanded(child: c4)]),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: c1),
        const SizedBox(width: 16),
        Expanded(child: c2),
        const SizedBox(width: 16),
        Expanded(child: c3),
        const SizedBox(width: 16),
        Expanded(child: c4),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String mainNumber,
    required String unit,
    required Widget customBottom,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAEFF5)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: const Color(0xFF8E9BAE),
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: mainNumber,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -1,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          customBottom,
        ],
      ),
    );
  }

  // --- MIDDLE SECTION ---
  Widget _buildMiddleSection({required bool isNarrow}) {
    final teamSection = _buildTeamAllocationSection();
    final workTypeSection = _buildWorkTypeDistributionSection();

    if (isNarrow) {
      return Column(
        children: [
          teamSection,
          const SizedBox(height: 20),
          workTypeSection,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: teamSection),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: workTypeSection),
      ],
    );
  }

  // Team Allocation & Capacity
  Widget _buildTeamAllocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Allocation & Capacity',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hours logged, commercial billability, and live pipeline status per designer.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '4 Designers',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF312E81),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDesignerCard(_designers[0])),
            const SizedBox(width: 14),
            Expanded(child: _buildDesignerCard(_designers[1])),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildDesignerCard(_designers[2])),
            const SizedBox(width: 14),
            Expanded(child: _buildDesignerCard(_designers[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildDesignerCard(DesignerReport d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAEFF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  d.avatarUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 32,
                    height: 32,
                    color: const Color(0xFF3B82F6),
                    child: Center(
                      child: Text(d.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      d.role,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        color: const Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  d.billablePercent,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stat boxes row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOGGED',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.loggedHours}h',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BILLABLE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.billableHours}h',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TASKS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.activeTasks} Active',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Quota & Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly quota (${d.quotaHours.toInt()}h)',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  color: const Color(0xFF8E9BAE),
                ),
              ),
              Text(
                '${(d.progressPercent * 100).toInt()}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: d.progressPercent.clamp(0.0, 1.0),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3730A3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Hours by Work Type
  Widget _buildWorkTypeDistributionSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAEFF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hours by Work Type',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Discipline distribution for the active interval.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Distribution List Items
          ..._workTypes.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: item.barColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${item.hours.toStringAsFixed(1)} hrs (${item.percentage}%)',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: (item.percentage / 100).clamp(0.0, 1.0),
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: item.barColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // Productivity Index Pill Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.explore_outlined, size: 16, color: Color(0xFF312E81)),
                    const SizedBox(width: 8),
                    Text(
                      'Team Productivity Index',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                  ],
                ),
                Text(
                  '94.8 / 100',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF312E81),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DETAILED DAILY HOURS LOG TABLE ---
  Widget _buildDetailedHoursLogCard() {
    final logs = _filteredHoursLogs;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAEFF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detailed Daily Hours Log',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Itemized work sessions, deliverables, and approval states.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDesignerFilter,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                          style: GoogleFonts.jetBrainsMono(fontSize: 11.5, color: const Color(0xFF1E293B)),
                          items: const [
                            DropdownMenuItem(value: 'All Designers', child: Text('All Designers')),
                            DropdownMenuItem(value: 'Elena', child: Text('Elena Rostova')),
                            DropdownMenuItem(value: 'Marcus', child: Text('Marcus Chen')),
                            DropdownMenuItem(value: 'Maya', child: Text('Maya Patel')),
                            DropdownMenuItem(value: 'Liam', child: Text('Liam Vance')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDesignerFilter = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download_outlined, size: 15, color: Color(0xFF1E293B)),
                      label: Text(
                        'Export CSV',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildLogHeaderCell('DATE', width: 120),
                _buildLogHeaderCell('DESIGNER', width: 160),
                _buildLogHeaderCell('WORK DELIVERABLE', flex: 3),
                _buildLogHeaderCell('TYPE', width: 130),
                _buildLogHeaderCell('TIME SLOT', width: 140),
                _buildLogHeaderCell('TOTAL', width: 90),
                _buildLogHeaderCell('STATUS', width: 120),
              ],
            ),
          ),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Color(0xFFF8FAFC),
              indent: 24,
              endIndent: 24,
            ),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        log.date,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: log.initialsBg,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Center(
                              child: Text(
                                log.designerInitials,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E1B4B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.designerName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        log.deliverable,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.typeTag,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF312E81),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        log.timeSlot,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        '${log.totalHours}h',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: log.statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: log.statusDot,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                log.status,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: log.statusText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Pagination & Summary Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${logs.length} of 38 recorded sessions',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: const Color(0xFF8E9BAE),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Previous',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '1',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF312E81),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Next',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF64748B)),
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

  Widget _buildLogHeaderCell(String text, {double? width, int? flex}) {
    final widget = Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: const Color(0xFF94A3B8),
      ),
    );

    if (flex != null) {
      return Expanded(flex: flex, child: widget);
    }
    return SizedBox(width: width, child: widget);
  }

  // --- FOOTER ---
  Widget _buildFooter({required bool isNarrow}) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'StudioTrack • Atelier Core v1.4',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Architectural Precision • Minimalist Workflow',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'StudioTrack • Atelier Core v1.4',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Text(
          'Architectural Precision • Minimalist Workflow',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
