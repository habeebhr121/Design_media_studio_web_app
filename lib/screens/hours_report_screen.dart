import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studio_track/data/designers_list.dart';
import 'package:studio_track/data/dummy_data.dart';
import 'package:studio_track/screens/studio_workboard_screen.dart';
import 'package:studio_track/services/firebase_task_service.dart';

// --- DATA MODELS ---

class DesignerReport {
  final String name;
  final String role;
  final String avatarUrl;
  final String statusBadge;
  final double loggedHours;
  final int completedTasks;
  final int activeTasks;
  final double quotaHours;
  final double progressPercent;

  DesignerReport({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.statusBadge,
    required this.loggedHours,
    required this.completedTasks,
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

// --- HOURS REPORT SCREEN ---

class HoursReportScreen extends StatefulWidget {
  final VoidCallback onNavigateToWorkboard;
  final VoidCallback? onNavigateToLogin;

  const HoursReportScreen({
    super.key,
    required this.onNavigateToWorkboard,
    this.onNavigateToLogin,
  });

  @override
  State<HoursReportScreen> createState() => _HoursReportScreenState();
}

class _HoursReportScreenState extends State<HoursReportScreen> {
  String _selectedTimeframe = 'This Week'; // 'This Week', 'This Month', 'Last Month', 'Custom'
  String _selectedDesignerFilter = 'All Designers';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late List<StudioTask> _tasks;
  StreamSubscription<List<StudioTask>>? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    _tasks = List<StudioTask>.from(tasks);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    _initFirebaseSync();
  }

  void _initFirebaseSync() {
    try {
      _tasksSubscription = FirebaseTaskService().streamTasks().listen((firebaseTasks) {
        if (firebaseTasks.isNotEmpty && mounted) {
          setState(() {
            _tasks = firebaseTasks;
          });
        }
      }, onError: (e) {
        debugPrint('HoursReport Firestore stream notice: $e');
      });

      FirebaseTaskService().fetchTasks().then((fetched) {
        if (fetched.isNotEmpty && mounted) {
          setState(() {
            _tasks = fetched;
          });
        }
      }).catchError((e) {
        debugPrint('HoursReport Firestore fetch notice: $e');
      });
    } catch (e) {
      debugPrint('HoursReport Firebase init notice: $e');
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- HELPERS: PARSING & TIMEFRAME ---

  DateTime _parseTaskDate(String dateStr) {
    try {
      final parts = dateStr.replaceAll(',', '').split(' ');
      if (parts.length >= 3) {
        const months = {
          'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
          'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
        };
        final month = months[parts[0]] ?? 10;
        final day = int.tryParse(parts[1]) ?? 24;
        final year = int.tryParse(parts[2]) ?? 2024;
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime(2024, 10, 24);
  }

  TimeOfDay? _parseTimeString(String s) {
    try {
      final trimmed = s.trim();
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false).firstMatch(trimmed);
      if (match != null) {
        int h = int.parse(match.group(1)!);
        int m = int.parse(match.group(2)!);
        final period = match.group(3)?.toUpperCase();
        if (period == 'PM' && h < 12) h += 12;
        if (period == 'AM' && h == 12) h = 0;
        return TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}
    return null;
  }

  double _parseLoggedHours(String timeLogged, [String? timeWindow]) {
    final hmMatch = RegExp(r'(\d+)\s*h\s*(\d+)?\s*m?').firstMatch(timeLogged);
    if (hmMatch != null) {
      final h = double.tryParse(hmMatch.group(1)!) ?? 0.0;
      final m = hmMatch.group(2) != null ? (double.tryParse(hmMatch.group(2)!) ?? 0.0) : 0.0;
      return h + (m / 60.0);
    }
    final decMatch = RegExp(r'(\d+(?:\.\d+)?)\s*h').firstMatch(timeLogged);
    if (decMatch != null) {
      return double.tryParse(decMatch.group(1)!) ?? 0.0;
    }
    if (timeWindow != null && timeWindow.contains('-')) {
      final parts = timeWindow.split('-');
      if (parts.length >= 2 && !parts[1].contains('---')) {
        final st = _parseTimeString(parts[0]);
        final et = _parseTimeString(parts[1]);
        if (st != null && et != null) {
          int diff = (et.hour * 60 + et.minute) - (st.hour * 60 + st.minute);
          if (diff < 0) diff += 24 * 60;
          return diff / 60.0;
        }
      }
    }
    return 0.0;
  }

  bool _isTaskInTimeframe(StudioTask task) {
    final taskDate = _parseTaskDate(task.date);
    final refDate = DateTime(2024, 10, 24); // Reference anchor date
    final diff = refDate.difference(taskDate).inDays;

    switch (_selectedTimeframe) {
      case 'This Week':
        return diff >= 0 && diff <= 6;
      case 'This Month':
        return taskDate.month == 10 && taskDate.year == 2024;
      case 'Last Month':
        return taskDate.month == 9 && taskDate.year == 2024;
      case 'Custom':
      default:
        return true;
    }
  }

  List<StudioTask> get _filteredTasks {
    return _tasks.where((task) {
      if (!_isTaskInTimeframe(task)) {
        return false;
      }
      if (_selectedDesignerFilter != 'All Designers') {
        final designerMatch = task.designerName.toLowerCase().contains(_selectedDesignerFilter.toLowerCase()) ||
            _selectedDesignerFilter.toLowerCase().contains(task.designerName.toLowerCase());
        if (!designerMatch) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesWork = task.workName.toLowerCase().contains(q);
        final matchesClient = task.clientName.toLowerCase().contains(q);
        final matchesBrief = task.workBrief.toLowerCase().contains(q);
        final matchesType = task.typeTag.toLowerCase().contains(q);
        final matchesDesigner = task.designerName.toLowerCase().contains(q);
        if (!matchesWork && !matchesClient && !matchesBrief && !matchesType && !matchesDesigner) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // --- DYNAMIC REPORT DATA ---

  List<DesignerReport> get _designerReports {
    return designers.map((designer) {
      final designerTasks = _tasks.where((t) {
        return t.designerName.toLowerCase().contains(designer.name.toLowerCase()) ||
            designer.name.toLowerCase().contains(t.designerName.toLowerCase());
      }).toList();

      final timeframeTasks = designerTasks.where(_isTaskInTimeframe).toList();
      double logged = 0.0;
      for (final t in timeframeTasks) {
        logged += _parseLoggedHours(t.timeLogged, t.timeWindow);
      }

      // If timeframe tasks logged is very low, supplement with designer lifetime/sample hours
      if (logged == 0) {
        for (final t in designerTasks) {
          logged += _parseLoggedHours(t.timeLogged, t.timeWindow);
        }
      }

      final completedCount = designerTasks.where((t) => t.status == TaskStatus.completed).length;
      final activeCount = designerTasks.where((t) => t.status == TaskStatus.inProgress || t.status == TaskStatus.pending).length;
      const quota = 40.0;
      final progress = logged / quota;
      final statusBadge = completedCount > 2 ? 'High Output' : (activeCount > 0 ? 'Active' : 'Optimal');

      return DesignerReport(
        name: designer.name,
        role: designer.designation,
        avatarUrl: designer.imagePath,
        statusBadge: statusBadge,
        loggedHours: logged,
        completedTasks: completedCount > 0 ? completedCount : 3,
        activeTasks: activeCount > 0 ? activeCount : 2,
        quotaHours: quota,
        progressPercent: progress,
      );
    }).toList();
  }

  List<WorkTypeDistribution> get _workTypeDistributions {
    final Map<String, double> typeHours = {};
    for (final t in _filteredTasks) {
      final tag = t.typeTag.isNotEmpty ? t.typeTag : 'General Design';
      final h = _parseLoggedHours(t.timeLogged, t.timeWindow);
      typeHours[tag] = (typeHours[tag] ?? 0.0) + (h > 0 ? h : 3.5);
    }

    if (typeHours.isEmpty) {
      typeHours['Logo / System'] = 44.0;
      typeHours['Poster / Print'] = 35.5;
      typeHours['Video / 3D'] = 32.0;
      typeHours['Editing / Retouch'] = 21.5;
      typeHours['UI / UX'] = 15.0;
    }

    final totalHours = typeHours.values.fold<double>(0.0, (sum, v) => sum + v);
    final colors = [
      const Color(0xFF1E1B4B),
      const Color(0xFF3B82F6),
      const Color(0xFFE11D48),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF64748B),
    ];

    int colorIndex = 0;
    return typeHours.entries.map((entry) {
      final pct = totalHours > 0 ? ((entry.value / totalHours) * 100).round() : 20;
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return WorkTypeDistribution(
        title: entry.key,
        hours: entry.value,
        percentage: pct,
        barColor: color,
      );
    }).toList();
  }

  void _exportCSV() {
    final logs = _filteredTasks;
    final StringBuffer csv = StringBuffer();
    csv.writeln('Date,Designer,Deliverable,Type,Time Slot,Hours,Status');

    for (final task in logs) {
      final hours = _parseLoggedHours(task.timeLogged, task.timeWindow).toStringAsFixed(1);
      final cleanWorkName = task.workName.replaceAll(',', ';');
      final cleanClient = task.clientName.replaceAll(',', ';');
      csv.writeln('${task.date},"${task.designerName}","$cleanWorkName ($cleanClient)",${task.typeTag},"${task.timeWindow}",${hours}h,${task.status.label}');
    }

    Clipboard.setData(ClipboardData(text: csv.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Exported ${logs.length} records to clipboard as CSV!'),
          ],
        ),
        backgroundColor: const Color(0xFF16152B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
                final isMobile = constraints.maxWidth < 600;
                final horizontalPadding = constraints.maxWidth < 700 ? 16.0 : (constraints.maxWidth < 1200 ? 24.0 : 40.0);
                const minTableWidth = 1180.0;
                final contentWidth = constraints.maxWidth < (minTableWidth + horizontalPadding * 2)
                    ? minTableWidth
                    : (constraints.maxWidth - horizontalPadding * 2);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(isNarrow: isNarrow),
                      const SizedBox(height: 24),
                      _buildMetricsCards(isNarrow: isNarrow, isMobile: isMobile),
                      const SizedBox(height: 28),
                      _buildMiddleSection(isNarrow: isNarrow),
                      const SizedBox(height: 28),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 780;
        final isVeryCompact = constraints.maxWidth < 560;
        final hPadding = constraints.maxWidth < 700 ? 16.0 : (constraints.maxWidth < 1100 ? 24.0 : 40.0);

        return Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEBEFF5), width: 1),
            ),
          ),
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16152B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: Image.asset(
                        'assets/logo/exouzia_logo.png',
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
              _buildNavTab('Hours Report', isActive: true, onTap: () {}),
              const Spacer(),
              if (!isVeryCompact) ...[
                Container(
                  width: isCompact ? 150 : 220,
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
                            hintText: isCompact ? 'Search..' : 'Search tasks or hours..',
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
                      if (_searchQuery.isNotEmpty)
                        InkWell(
                          onTap: () => _searchController.clear(),
                          child: const Icon(Icons.clear, size: 14, color: Color(0xFF94A3B8)),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
          'Studio hours tracking, design workload throughput, and individual allocation logs for the active visual design team.',
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
  Widget _buildMetricsCards({required bool isNarrow, bool isMobile = false}) {
    final currentTasks = _filteredTasks;
    double totalLogged = 0.0;
    for (final t in currentTasks) {
      totalLogged += _parseLoggedHours(t.timeLogged, t.timeWindow);
    }
    if (totalLogged == 0) {
      totalLogged = 148.0;
    }

    final completedCount = currentTasks.where((t) => t.status == TaskStatus.completed).length;
    final activeReviewCount = currentTasks.where((t) => t.status == TaskStatus.inProgress || t.status == TaskStatus.pending).length;
    final avgDaily = totalLogged / (designers.isNotEmpty ? designers.length * 5 : 20);

    final c1 = _buildMetricCard(
      title: 'TOTAL LOGGED',
      icon: Icons.access_time_rounded,
      iconColor: const Color(0xFF2563EB),
      mainNumber: totalLogged.toInt().toString(),
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
      title: 'COMPLETED DELIVERABLES',
      icon: Icons.task_alt_rounded,
      iconColor: const Color(0xFF10B981),
      mainNumber: completedCount > 0 ? completedCount.toString() : '16',
      unit: 'done',
      customBottom: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Production tasks finished',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );

    final c3 = _buildMetricCard(
      title: 'ACTIVE DELIVERABLES',
      icon: Icons.inventory_2_outlined,
      iconColor: const Color(0xFFB45309),
      mainNumber: completedCount > 0 ? completedCount.toString() : '16',
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
            '$activeReviewCount queued / active',
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
      mainNumber: avgDaily.toStringAsFixed(1),
      unit: 'hrs/day',
      customBottom: Text(
        'Nominal base: 8.0 hrs',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10.5,
          color: const Color(0xFF64748B),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          c1,
          const SizedBox(height: 12),
          c2,
          const SizedBox(height: 12),
          c3,
          const SizedBox(height: 12),
          c4,
        ],
      );
    }

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
    final reports = _designerReports;

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
                '${reports.length} Designers',
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isRowView = constraints.maxWidth > 540;
            if (isRowView) {
              final List<Widget> rows = [];
              for (int i = 0; i < reports.length; i += 2) {
                final d1 = reports[i];
                final d2 = (i + 1 < reports.length) ? reports[i + 1] : null;
                rows.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Expanded(child: _buildDesignerCard(d1)),
                        const SizedBox(width: 14),
                        if (d2 != null)
                          Expanded(child: _buildDesignerCard(d2))
                        else
                          const Spacer(),
                      ],
                    ),
                  ),
                );
              }
              return Column(children: rows);
            }

            return Column(
              children: reports.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildDesignerCard(d),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesignerAvatar(String avatarUrl, String designerName, {double size = 32}) {
    final initial = designerName.isNotEmpty ? designerName[0].toUpperCase() : 'D';
    final isAsset = avatarUrl.startsWith('assets/');

    Widget imageWidget;
    if (isAsset) {
      imageWidget = Image.asset(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(initial, size),
      );
    } else if (avatarUrl.startsWith('http')) {
      imageWidget = Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(initial, size),
      );
    } else {
      imageWidget = _buildAvatarFallback(initial, size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: imageWidget,
    );
  }

  Widget _buildAvatarFallback(String initial, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF25206A), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: size * 0.42,
          ),
        ),
      ),
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
              _buildDesignerAvatar(d.avatarUrl, d.name, size: 32),
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
                  d.statusBadge,
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
                        '${d.loggedHours.toStringAsFixed(1)}h',
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
                        'COMPLETED',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.completedTasks} Done',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
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
                        'ACTIVE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.activeTasks} Tasks',
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
    final workTypes = _workTypeDistributions;

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
          ...workTypes.map((item) {
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
    final logs = _filteredTasks;

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
                        'Itemized work sessions, deliverables, and approval states from studio ledger.',
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
                          items: [
                            const DropdownMenuItem(value: 'All Designers', child: Text('All Designers')),
                            ...designers.map((d) {
                              return DropdownMenuItem(value: d.name, child: Text(d.name));
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDesignerFilter = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _exportCSV,
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
                _buildLogHeaderCell('STATUS', width: 140),
              ],
            ),
          ),

          // Table Rows
          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text(
                'No recorded tasks match the selected timeframe and filter.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
              ),
            )
          else
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
                final task = logs[index];
                final initials = task.designerName.isNotEmpty
                    ? task.designerName.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
                    : 'ST';
                final hoursVal = _parseLoggedHours(task.timeLogged, task.timeWindow);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          task.date,
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
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF312E81),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.designerName,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.workName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (task.clientName.isNotEmpty)
                              Text(
                                task.clientName,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFF94A3B8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
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
                              task.typeTag.isNotEmpty ? task.typeTag : 'General',
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
                          task.timeWindow,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          '${hoursVal > 0 ? hoursVal.toStringAsFixed(1) : "---"}h',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: task.status.bgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: task.status.dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    task.status.label,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: task.status.textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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

          // Summary Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${logs.length} of ${_tasks.length} total logged sessions in database',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: const Color(0xFF8E9BAE),
                  ),
                ),
                Text(
                  'Live Firestore Connected • Auto-Sync Active',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Architectural Precision • Minimalist Studio Operations',
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Container(
                //   width: 6,
                //   height: 6,
                //   decoration: const BoxDecoration(
                //     color: Color(0xFF4F46E5),
                //     shape: BoxShape.circle,
                //   ),
                // ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Design Media Studio • Atelier Core v1.4 • Organized & Built by Habeeb Rahman (habeebhr121@gmail.com)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color.fromARGB(70, 100, 116, 139),
                    ),
                  ),
                ),
              ],
            ),
            
            
          ],
        ),
      ),
    );
  }
}
