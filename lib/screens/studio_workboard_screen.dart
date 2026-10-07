import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studio_track/data/dummy_data.dart';

// --- DATA MODELS ---

enum TaskStatus {
  inProgress('In Progress', Color(0xFF3B82F6), Color(0xFFEFF6FF), Color(0xFF2563EB)),
  completed('Completed', Color(0xFF4F46E5), Color(0xFFEEF2FF), Color(0xFF4338CA)),
  inReview('In Review', Color(0xFF6366F1), Color(0xFFEEF2FF), Color(0xFF4F46E5)),
  pending('Pending', Color(0xFF64748B), Color(0xFFF1F5F9), Color(0xFF475569));

  final String label;
  final Color dotColor;
  final Color bgColor;
  final Color textColor;

  const TaskStatus(this.label, this.dotColor, this.bgColor, this.textColor);
}

class TaskAttachment {
  final String id;
  final String name;
  final String imageUrl;
  final String fileSize;
  final String uploadedAt;

  TaskAttachment({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.fileSize,
    required this.uploadedAt,
  });
}

class StudioTask {
  String id;
  String date;
  String designerName;
  String designerRole;
  String avatarUrl;
  String workName;
  String clientName;
  String typeTag;
  String workBrief;
  TaskStatus status;
  String timeWindow;
  String timeLogged;
  List<TaskAttachment> attachments;

  StudioTask({
    required this.id,
    required this.date,
    required this.designerName,
    required this.designerRole,
    required this.avatarUrl,
    required this.workName,
    required this.clientName,
    required this.typeTag,
    required this.workBrief,
    required this.status,
    required this.timeWindow,
    required this.timeLogged,
    List<TaskAttachment>? attachments,
  }) : attachments = attachments ?? [];
}

class DesignerCapacity {
  final String name;
  final double currentHours;
  final double maxHours;

  DesignerCapacity({
    required this.name,
    required this.currentHours,
    required this.maxHours,
  });

  double get percentage => (currentHours / maxHours).clamp(0.0, 1.0);
}

class DailyCadence {
  final String day;
  final double? hours;
  final bool isHighlighted;

  DailyCadence({
    required this.day,
    this.hours,
    this.isHighlighted = false,
  });
}

class ScheduledDrop {
  final String title;
  final String designer;
  final String time;
  final String badge;

  ScheduledDrop({
    required this.title,
    required this.designer,
    required this.time,
    required this.badge,
  });
}

// --- STUDIO WORKBOARD SCREEN ---

class StudioWorkboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHoursReport;
  final VoidCallback? onNavigateToLogin;

  const StudioWorkboardScreen({
    super.key,
    this.onNavigateToHoursReport,
    this.onNavigateToLogin,
  });

  @override
  State<StudioWorkboardScreen> createState() => _StudioWorkboardScreenState();
}

class _StudioWorkboardScreenState extends State<StudioWorkboardScreen> {
  String _selectedDateFilter = 'Today'; // 'Today', 'Yesterday', 'Custom'
  DateTime _selectedCustomDate = DateTime(2024, 10, 22);

  static const String kTodayDateStr = 'Oct 24, 2024';
  static const String kYesterdayDateStr = 'Oct 23, 2024';

  String _selectedDesigner = 'All 4';
  String _selectedStatus = 'All';
  String _searchQuery = '';
  bool _sortAscending = false;

  late Timer _timer;
  int _secondsElapsed = 6142; // Starts at 01:42:22

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tableSearchController = TextEditingController();

  late List<StudioTask> _tasks;
  late List<DesignerCapacity> _capacities;
  late List<DailyCadence> _cadenceData;
  late List<ScheduledDrop> _scheduledDrops;

  @override
  void initState() {
    super.initState();
    _selectedDateFilter = 'Today';
    _selectedCustomDate = DateTime(2024, 10, 22);
    _startTimer();
    _initData();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Oct 22, 2024';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final mIndex = (dt.month - 1).clamp(0, 11);
    return '${months[mIndex]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  String _getActiveDateString() {
    if (_selectedDateFilter == 'Yesterday') return kYesterdayDateStr;
    if (_selectedDateFilter == 'Last 7 Days') return 'Last 7 Days (Oct 18 - 24)';
    if (_selectedDateFilter == 'Last 14 Days') return 'Last 14 Days (Oct 11 - 24)';
    if (_selectedDateFilter == 'Custom') {
      return _formatDate(_selectedCustomDate);
    }
    return kTodayDateStr;
  }

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

  bool _isTaskInActiveTimeframe(StudioTask task) {
    final isGlobalStatusFilter = _selectedStatus == 'In Progress' ||
        _selectedStatus == 'In Review' ||
        _selectedStatus == 'Pending';

    final taskDate = _parseTaskDate(task.date);
    final refDate = DateTime(2024, 10, 24); // Reference "Today" date
    final diff = refDate.difference(taskDate).inDays;

    if (isGlobalStatusFilter) {
      // When In Progress, In Review, or Pending is active:
      // If user selected Last 7 Days, check within 7 days.
      // Otherwise default to the 14 days active timeframe window.
      if (_selectedDateFilter == 'Last 7 Days') {
        return diff >= 0 && diff <= 7;
      }
      return diff >= 0 && diff <= 14;
    }

    if (_selectedDateFilter == 'Today') {
      return task.date == kTodayDateStr;
    } else if (_selectedDateFilter == 'Yesterday') {
      return task.date == kYesterdayDateStr;
    } else if (_selectedDateFilter == 'Last 7 Days') {
      return diff >= 0 && diff <= 7;
    } else if (_selectedDateFilter == 'Last 14 Days') {
      return diff >= 0 && diff <= 14;
    } else if (_selectedDateFilter == 'Custom') {
      return task.date == _formatDate(_selectedCustomDate);
    }
    return true;
  }

  @override
  void dispose() {
    _timer.cancel();
    _searchController.dispose();
    _tableSearchController.dispose();
    super.dispose();
  }

  void _initData() {
    _tasks = tasks;

    _capacities = [
      DesignerCapacity(name: 'Elena Rostova', currentHours: 34, maxHours: 40),
      DesignerCapacity(name: 'Marcus Chen', currentHours: 38, maxHours: 40),
      DesignerCapacity(name: 'Maya Patel', currentHours: 29, maxHours: 40),
      DesignerCapacity(name: 'Liam Vance', currentHours: 24, maxHours: 40),
    ];

    _cadenceData = [
      DailyCadence(day: 'Mon', hours: 31),
      DailyCadence(day: 'Tue', hours: 28),
      DailyCadence(day: 'Wed', hours: 35),
      DailyCadence(day: 'Thu', hours: 32, isHighlighted: true),
      DailyCadence(day: 'Fri', hours: null),
    ];

    _scheduledDrops = [
      ScheduledDrop(
        title: 'Veloce Brand Vector Pack',
        designer: 'Elena R.',
        time: '05:00 PM',
        badge: 'PDF / SVG',
      ),
      ScheduledDrop(
        title: 'Sona 3D Spin Draft 2',
        designer: 'Maya P.',
        time: '05:30 PM',
        badge: 'ProRes 4444',
      ),
    ];
  }

  List<StudioTask> get _filteredTasks {
    return _tasks.where((task) {
      if (!_isTaskInActiveTimeframe(task)) {
        return false;
      }
      if (_selectedDesigner != 'All 4') {
        if (!task.designerName.toLowerCase().contains(_selectedDesigner.toLowerCase())) {
          return false;
        }
      }
      if (_selectedStatus != 'All') {
        if (task.status.label.toLowerCase() != _selectedStatus.toLowerCase()) {
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

  // --- ACTIONS: UPDATE STATUS, EDIT, ATTACH, DELETE ---

  void _openUpdateStatusDialog(StudioTask task) {
    TaskStatus currentStatus = task.status;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.published_with_changes_rounded, size: 20, color: Color(0xFF25206A)),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Update Task Status',
                              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Task: ${task.workName}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                    Text(
                      'Assigned to ${task.designerName} • ${task.clientName}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),

                    ...TaskStatus.values.map((s) {
                      final isSelected = currentStatus == s;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setDialogState(() => currentStatus = s);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? s.bgColor : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? s.dotColor : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: s.dotColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s.label,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? s.textColor : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, size: 18, color: s.dotColor),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25206A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              task.status = currentStatus;
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Status updated to "${currentStatus.label}" for "${task.workName}"'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Text('Save Status', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEditTaskDialog(StudioTask task) {
    final workNameCtrl = TextEditingController(text: task.workName);
    final clientCtrl = TextEditingController(text: task.clientName);
    final briefCtrl = TextEditingController(text: task.workBrief);
    final timeWindowCtrl = TextEditingController(text: task.timeWindow);
    String selectedDateStr = task.date;
    String selectedDesignerName = task.designerName;
    String selectedType = task.typeTag;
    TaskStatus selectedStatus = task.status;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: 560,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eyebrow and Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UPDATE PRODUCTION ENTRY',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: const Color(0xFF8E9BAE),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Edit Work Task',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ROW 1: DATE & ASSIGNED DESIGNER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DATE FIELD
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DATE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _parseTaskDate(selectedDateStr),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      selectedDateStr = _formatDate(picked);
                                    });
                                  }
                                },
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F4FA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    selectedDateStr,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // ASSIGNED DESIGNER DROPDOWN
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ASSIGNED DESIGNER',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: ['Elena Rostova', 'Marcus Chen', 'Maya Patel', 'Liam Vance'].contains(selectedDesignerName)
                                        ? selectedDesignerName
                                        : 'Elena Rostova',
                                    isExpanded: true,
                                    icon: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF475569)),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Elena Rostova', child: Text('Elena Rostova')),
                                      DropdownMenuItem(value: 'Marcus Chen', child: Text('Marcus Chen')),
                                      DropdownMenuItem(value: 'Maya Patel', child: Text('Maya Patel')),
                                      DropdownMenuItem(value: 'Liam Vance', child: Text('Liam Vance')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setDialogState(() => selectedDesignerName = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ROW 2: WORK NAME & TYPE
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // WORK NAME
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WORK NAME',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: workNameCtrl,
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Kinetic Typo Teaser',
                                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // TYPE DROPDOWN
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TYPE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: ['Logo', 'UI / UX', 'Poster / Print', 'Video / 3D', 'Editing / Retouch'].contains(selectedType)
                                        ? selectedType
                                        : 'UI / UX',
                                    isExpanded: true,
                                    icon: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF475569)),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Logo', child: Text('Logo')),
                                      DropdownMenuItem(value: 'UI / UX', child: Text('UI / UX')),
                                      DropdownMenuItem(value: 'Poster / Print', child: Text('Poster / Print')),
                                      DropdownMenuItem(value: 'Video / 3D', child: Text('Video / 3D')),
                                      DropdownMenuItem(value: 'Editing / Retouch', child: Text('Editing / Retouch')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setDialogState(() => selectedType = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ROW 3: WORK BRIEF / CLIENT SCOPE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WORK BRIEF / CLIENT SCOPE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TextField(
                            controller: briefCtrl,
                            maxLines: 3,
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: 'Provide succinct direction, dimensions, formats, and design constraints...',
                              hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ROW 4: STATUS & LOGGED TIME SLOT
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // STATUS DROPDOWN
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<TaskStatus>(
                                    value: selectedStatus,
                                    isExpanded: true,
                                    icon: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF475569)),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: TaskStatus.inProgress, child: Text('In Progress')),
                                      DropdownMenuItem(value: TaskStatus.inReview, child: Text('In Review')),
                                      DropdownMenuItem(value: TaskStatus.pending, child: Text('Pending')),
                                      DropdownMenuItem(value: TaskStatus.completed, child: Text('Completed')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setDialogState(() => selectedStatus = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // LOGGED TIME SLOT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOGGED TIME SLOT',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: timeWindowCtrl,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '09:00 AM - 12:30 PM (3h 30m)',
                                    hintStyle: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF94A3B8)),
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ACTIONS ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF322A86),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (workNameCtrl.text.trim().isEmpty) return;
                            String role = task.designerRole;
                            String avatar = task.avatarUrl;
                            if (selectedDesignerName.contains('Marcus')) {
                              role = 'Graphic Design';
                              avatar = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150';
                            } else if (selectedDesignerName.contains('Maya')) {
                              role = '3D Motion';
                              avatar = 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150';
                            } else if (selectedDesignerName.contains('Liam')) {
                              role = 'Digital Retouch';
                              avatar = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150';
                            } else if (selectedDesignerName.contains('Elena')) {
                              role = 'Lead Visual';
                              avatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
                            }

                            setState(() {
                              task.date = selectedDateStr;
                              task.workName = workNameCtrl.text.trim();
                              task.clientName = clientCtrl.text.trim().isEmpty ? task.clientName : clientCtrl.text.trim();
                              task.designerName = selectedDesignerName;
                              task.designerRole = role;
                              task.avatarUrl = avatar;
                              task.typeTag = selectedType;
                              task.workBrief = briefCtrl.text.trim().isEmpty ? task.workBrief : briefCtrl.text.trim();
                              task.status = selectedStatus;
                              task.timeWindow = timeWindowCtrl.text.trim().isEmpty ? task.timeWindow : timeWindowCtrl.text.trim();
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Updated "${task.workName}"'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAttachDialog(StudioTask task) {
    final fileNameCtrl = TextEditingController(text: 'Deliverable_Screenshot_${task.attachments.length + 1}.png');
    final urlCtrl = TextEditingController(text: 'https://images.unsplash.com/photo-1542744094-3a31f272c490?w=600&auto=format&fit=crop&q=80');

    final samplePresets = [
      {
        'name': 'UI_Flow_Screenshot.png',
        'url': 'https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=600&auto=format&fit=crop&q=80',
        'size': '520 KB',
      },
      {
        'name': 'Brand_Mockup_Export.jpg',
        'url': 'https://images.unsplash.com/photo-1600132806370-bf17e65e942f?w=600&auto=format&fit=crop&q=80',
        'size': '840 KB',
      },
      {
        'name': '3D_Render_Preview.png',
        'url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop&q=80',
        'size': '1.1 MB',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.attach_file_rounded, size: 20, color: Color(0xFF25206A)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Task Attachments & Deliverables',
                                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Task: ${task.workName}',
                                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF64748B)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (task.attachments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.image_outlined, size: 36, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 8),
                              Text(
                                'No screenshots or images attached yet.',
                                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                              ),
                              Text(
                                'Upload completed task previews or select a studio preset below.',
                                style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attached Screenshots (${task.attachments.length})',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: task.attachments.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final att = task.attachments[index];
                                return Stack(
                                  children: [
                                    Container(
                                      width: 160,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Image.network(
                                              att.imageUrl,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: const Color(0xFFE2E8F0),
                                                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            color: Colors.white,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  att.name,
                                                  style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${att.fileSize} • ${att.uploadedAt}',
                                                  style: GoogleFonts.jetBrainsMono(fontSize: 9, color: const Color(0xFF94A3B8)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            task.attachments.removeAt(index);
                                          });
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 14),

                    Text(
                      'Quick Attach Studio Presets:',
                      style: GoogleFonts.jetBrainsMono(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: samplePresets.map((preset) {
                        return ActionChip(
                          avatar: const Icon(Icons.add_photo_alternate_outlined, size: 14, color: Color(0xFF25206A)),
                          label: Text(
                            '+ ${preset['name']}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF1E293B)),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onPressed: () {
                            setDialogState(() {
                              task.attachments.add(
                                TaskAttachment(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  name: preset['name']!,
                                  imageUrl: preset['url']!,
                                  fileSize: preset['size']!,
                                  uploadedAt: 'Just now',
                                ),
                              );
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: fileNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Attachment Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: urlCtrl,
                            decoration: InputDecoration(
                              labelText: 'Image / Screenshot URL',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25206A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (fileNameCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) return;
                            setDialogState(() {
                              task.attachments.add(
                                TaskAttachment(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  name: fileNameCtrl.text.trim(),
                                  imageUrl: urlCtrl.text.trim(),
                                  fileSize: '450 KB',
                                  uploadedAt: 'Just now',
                                ),
                              );
                            });
                            setState(() {});
                            fileNameCtrl.text = 'Deliverable_Screenshot_${task.attachments.length + 1}.png';
                          },
                          icon: const Icon(Icons.upload_file_rounded, size: 15),
                          label: Text('Attach', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25206A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openDeleteConfirmDialog(StudioTask task) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Delete Assignment?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: const Color(0xFF0F172A)),
          ),
          content: Text(
            'Are you sure you want to delete "${task.workName}"? This action cannot be undone.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  _tasks.removeWhere((t) => t.id == task.id);
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${task.workName}"'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _openAddNewWorkDialog() {
    final workNameCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    final briefCtrl = TextEditingController();
    final timeWindowCtrl = TextEditingController(text: '09:00 AM - 12:30 PM (3h 30m)');
    String selectedDateStr = _getActiveDateString();
    String selectedDesignerName = 'Elena Rostova';
    String selectedType = 'Logo';
    TaskStatus selectedStatus = TaskStatus.inProgress;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: 560,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eyebrow and Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEW PRODUCTION ENTRY',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: const Color(0xFF8E9BAE),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Assign Work Task',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ROW 1: DATE & ASSIGNED DESIGNER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DATE FIELD
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DATE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _parseTaskDate(selectedDateStr),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      selectedDateStr = _formatDate(picked);
                                    });
                                  }
                                },
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F4FA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    selectedDateStr,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // ASSIGNED DESIGNER DROPDOWN
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ASSIGNED DESIGNER',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedDesignerName,
                                    isExpanded: true,
                                    icon: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF475569)),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Elena Rostova', child: Text('Elena Rostova')),
                                      DropdownMenuItem(value: 'Marcus Chen', child: Text('Marcus Chen')),
                                      DropdownMenuItem(value: 'Maya Patel', child: Text('Maya Patel')),
                                      DropdownMenuItem(value: 'Liam Vance', child: Text('Liam Vance')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setDialogState(() => selectedDesignerName = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ROW 2: WORK NAME & TYPE
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // WORK NAME
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WORK NAME',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: workNameCtrl,
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Kinetic Typo Teaser',
                                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // TYPE DROPDOWN
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TYPE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedType,
                                    isExpanded: true,
                                    icon: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF475569)),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Logo', child: Text('Logo')),
                                      DropdownMenuItem(value: 'UI / UX', child: Text('UI / UX')),
                                      DropdownMenuItem(value: 'Poster / Print', child: Text('Poster / Print')),
                                      DropdownMenuItem(value: 'Video / 3D', child: Text('Video / 3D')),
                                      DropdownMenuItem(value: 'Editing / Retouch', child: Text('Editing / Retouch')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setDialogState(() => selectedType = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ROW 3: WORK BRIEF / CLIENT SCOPE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WORK BRIEF / CLIENT SCOPE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TextField(
                            controller: briefCtrl,
                            maxLines: 3,
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: 'Provide succinct direction, dimensions, formats, and design constraints...',
                              hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ROW 4: STATUS & LOGGED TIME SLOT
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // STATUS DROPDOWN
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<TaskStatus>(
                                    value: selectedStatus,
                                    isExpanded: true,
                                    icon: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF475569)),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: TaskStatus.inProgress, child: Text('In Progress')),
                                      DropdownMenuItem(value: TaskStatus.inReview, child: Text('In Review')),
                                      DropdownMenuItem(value: TaskStatus.pending, child: Text('Pending')),
                                      DropdownMenuItem(value: TaskStatus.completed, child: Text('Completed')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setDialogState(() => selectedStatus = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // LOGGED TIME SLOT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOGGED TIME SLOT',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: timeWindowCtrl,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '09:00 AM - 12:30 PM (3h 30m)',
                                    hintStyle: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF94A3B8)),
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ACTIONS ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF322A86),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (workNameCtrl.text.trim().isEmpty) return;
                            String role = 'Lead Visual';
                            String avatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
                            if (selectedDesignerName.contains('Marcus')) {
                              role = 'Graphic Design';
                              avatar = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150';
                            } else if (selectedDesignerName.contains('Maya')) {
                              role = '3D Motion';
                              avatar = 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150';
                            } else if (selectedDesignerName.contains('Liam')) {
                              role = 'Digital Retouch';
                              avatar = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150';
                            }

                            setState(() {
                              _tasks.insert(
                                0,
                                StudioTask(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  date: selectedDateStr,
                                  designerName: selectedDesignerName,
                                  designerRole: role,
                                  avatarUrl: avatar,
                                  workName: workNameCtrl.text.trim(),
                                  clientName: clientCtrl.text.trim().isEmpty ? 'Direct Studio' : clientCtrl.text.trim(),
                                  typeTag: selectedType,
                                  workBrief: briefCtrl.text.trim().isEmpty ? 'Initial milestone started' : briefCtrl.text.trim(),
                                  status: selectedStatus,
                                  timeWindow: timeWindowCtrl.text.trim().isEmpty ? '09:00 AM - 12:30 PM' : timeWindowCtrl.text.trim(),
                                  timeLogged: '0h 00m logged',
                                ),
                              );
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'Create Entry',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                final horizontalPadding = constraints.maxWidth < 700 ? 16.0 : 40.0;
                final contentWidth = constraints.maxWidth < 1180 ? 1180.0 : (constraints.maxWidth - horizontalPadding * 2);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(isNarrow: isNarrow),
                      const SizedBox(height: 24),
                      _buildMetricsRow(isNarrow: isNarrow),
                      const SizedBox(height: 28),
                      _buildFiltersBar(isNarrow: isNarrow),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: contentWidth,
                          child: _buildDataTableCard(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildBottomAnalyticsRow(isNarrow: isNarrow),
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
          _buildNavTab('Workboard', isActive: true, onTap: () {}),
          const SizedBox(width: 8),
          _buildNavTab('Hours Report', isActive: false, onTap: () {
            widget.onNavigateToHoursReport?.call();
          }),
          const SizedBox(width: 8),
          _buildNavTab('Login', isActive: false, onTap: () {
            widget.onNavigateToLogin?.call();
          }),
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
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
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
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              widget.onNavigateToLogin?.call();
            },
            child: ClipRRect(
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
              'ATELIER DISPATCH • Q4 ROSTER',
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
          'Studio Workboard',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time allocation, production briefs, and clocked sessions across the design squad.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E7FF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live Session: ${_formatTime(_secondsElapsed)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _openAddNewWorkDialog,
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: Text(
            'Add New Work',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25206A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      ],
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 16),
          actions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        actions,
      ],
    );
  }

  // --- METRICS ROW (4 CARDS) ---
  Widget _buildMetricsRow({required bool isNarrow}) {
    final dayTasks = _tasks.where((t) => _isTaskInActiveTimeframe(t)).toList();
    final activeCount = dayTasks.where((t) => t.status == TaskStatus.inProgress || t.status == TaskStatus.inReview || t.status == TaskStatus.pending).length;
    final completedCount = dayTasks.where((t) => t.status == TaskStatus.completed).length;
    final activeStaffCount = dayTasks.map((t) => t.designerName).toSet().length;

    double totalHours = 0.0;
    for (final t in dayTasks) {
      final match = RegExp(r'(\d+(?:\.\d+)?)\s*h').firstMatch(t.timeLogged);
      if (match != null) {
        totalHours += double.tryParse(match.group(1)!) ?? 0;
      }
    }
    final formattedHours = totalHours.toStringAsFixed(totalHours.truncateToDouble() == totalHours ? 0 : 1);

    String loggedLabel = 'TODAY LOGGED';
    String completedLabel = 'COMPLETED TODAY';
    if (_selectedDateFilter == 'Yesterday') {
      loggedLabel = 'YESTERDAY LOGGED';
      completedLabel = 'COMPLETED YESTERDAY';
    } else if (_selectedDateFilter == 'Last 7 Days') {
      loggedLabel = 'LAST 7 DAYS';
      completedLabel = 'COMPLETED (7D)';
    } else if (_selectedDateFilter == 'Last 14 Days') {
      loggedLabel = 'LAST 14 DAYS';
      completedLabel = 'COMPLETED (14D)';
    } else if (_selectedDateFilter == 'Custom') {
      loggedLabel = 'DAY LOGGED';
      completedLabel = 'COMPLETED OUTPUT';
    }

    final c1 = _buildMetricCard(
      icon: Icons.layers_outlined,
      iconBg: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF2563EB),
      label: 'ACTIVE TASKS',
      boldValue: '$activeCount',
      subText: 'in progress',
    );
    final c2 = _buildMetricCard(
      icon: Icons.access_time_rounded,
      iconBg: const Color(0xFFEEF2FF),
      iconColor: const Color(0xFF4F46E5),
      label: loggedLabel,
      boldValue: formattedHours,
      subText: 'hrs',
    );
    final c3 = _buildMetricCard(
      icon: Icons.verified_outlined,
      iconBg: const Color(0xFFECFDF5),
      iconColor: const Color(0xFF059669),
      label: completedLabel,
      boldValue: '$completedCount',
      subText: 'deliverables',
    );
    final c4 = _buildMetricCard(
      icon: Icons.people_alt_outlined,
      iconBg: const Color(0xFFFDF2F8),
      iconColor: const Color(0xFFDB2777),
      label: 'ACTIVE STAFF',
      boldValue: '$activeStaffCount',
      subText: 'designers',
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
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String boldValue,
    required String subText,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAEFF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: const Color(0xFF8E9BAE),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$boldValue ',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      TextSpan(
                        text: subText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FILTERS TOOLBAR ---
  Widget _buildFiltersBar({required bool isNarrow}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAEFF5)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // 1. Timeframe / Day Selector
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DAY:',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip('Today', isSelected: _selectedDateFilter == 'Today', onSelected: () {
                setState(() => _selectedDateFilter = 'Today');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Yesterday', isSelected: _selectedDateFilter == 'Yesterday', onSelected: () {
                setState(() => _selectedDateFilter = 'Yesterday');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Last 7 Days', isSelected: _selectedDateFilter == 'Last 7 Days', onSelected: () {
                setState(() => _selectedDateFilter = 'Last 7 Days');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Last 14 Days', isSelected: _selectedDateFilter == 'Last 14 Days', onSelected: () {
                setState(() => _selectedDateFilter = 'Last 14 Days');
              }),
              const SizedBox(width: 6),
              _buildCustomDateChip(),
            ],
          ),

          // Divider 1
          if (!isNarrow)
            Container(height: 18, width: 1, color: const Color(0xFFE2E8F0)),

          // 2. Designer / Staff Selector
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DESIGNER:',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip('All 4', isSelected: _selectedDesigner == 'All 4', onSelected: () {
                setState(() => _selectedDesigner = 'All 4');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Elena', isSelected: _selectedDesigner == 'Elena', onSelected: () {
                setState(() => _selectedDesigner = 'Elena');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Marcus', isSelected: _selectedDesigner == 'Marcus', onSelected: () {
                setState(() => _selectedDesigner = 'Marcus');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Maya', isSelected: _selectedDesigner == 'Maya', onSelected: () {
                setState(() => _selectedDesigner = 'Maya');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Liam', isSelected: _selectedDesigner == 'Liam', onSelected: () {
                setState(() => _selectedDesigner = 'Liam');
              }),
            ],
          ),

          // Divider 2
          if (!isNarrow)
            Container(height: 18, width: 1, color: const Color(0xFFE2E8F0)),

          // 3. Status Selector
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'STATUS:',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip('All', isSelected: _selectedStatus == 'All', onSelected: () {
                setState(() => _selectedStatus = 'All');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('In Progress', isSelected: _selectedStatus == 'In Progress', onSelected: () {
                setState(() {
                  _selectedStatus = 'In Progress';
                  if (_selectedDateFilter == 'Today' || _selectedDateFilter == 'Yesterday' || _selectedDateFilter == 'Custom') {
                    _selectedDateFilter = 'Last 14 Days';
                  }
                });
              }),
              const SizedBox(width: 6),
              _buildFilterChip('In Review', isSelected: _selectedStatus == 'In Review', onSelected: () {
                setState(() {
                  _selectedStatus = 'In Review';
                  if (_selectedDateFilter == 'Today' || _selectedDateFilter == 'Yesterday' || _selectedDateFilter == 'Custom') {
                    _selectedDateFilter = 'Last 14 Days';
                  }
                });
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Pending', isSelected: _selectedStatus == 'Pending', onSelected: () {
                setState(() {
                  _selectedStatus = 'Pending';
                  if (_selectedDateFilter == 'Today' || _selectedDateFilter == 'Yesterday' || _selectedDateFilter == 'Custom') {
                    _selectedDateFilter = 'Last 14 Days';
                  }
                });
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Completed', isSelected: _selectedStatus == 'Completed', onSelected: () {
                setState(() => _selectedStatus = 'Completed');
              }),
            ],
          ),

          // Divider 3
          if (!isNarrow)
            Container(height: 18, width: 1, color: const Color(0xFFE2E8F0)),

          // 4. Search Field
          Container(
            width: 210,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(Icons.search, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _tableSearchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Filter brief or client...',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
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
                    onTap: () {
                      _tableSearchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(Icons.close, size: 13, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateChip() {
    final isSelected = _selectedDateFilter == 'Custom';
    final dateLabel = isSelected ? _formatDate(_selectedCustomDate) : 'Custom Date';

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedCustomDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF25206A),
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF0F172A),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedCustomDate = picked;
            _selectedDateFilter = 'Custom';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF25206A) : const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 12,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 5),
            Text(
              dateLabel,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected, required VoidCallback onSelected}) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF25206A) : const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // --- DATA TABLE CARD ---
  Widget _buildDataTableCard() {
    final tasks = _filteredTasks;
    final isGlobalStatusFilter = _selectedStatus == 'In Progress' ||
        _selectedStatus == 'In Review' ||
        _selectedStatus == 'Pending';

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
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              children: [
                _buildTableHeaderCell('DATE', width: 95),
                _buildTableHeaderCell('ASSIGNED TO', width: 165),
                _buildTableHeaderCell('WORK NAME', width: 180),
                _buildTableHeaderCell('TYPE', width: 120),
                _buildTableHeaderCell('WORK BRIEF & CONTENT', flex: 3),
                _buildTableHeaderCell('ATTACHMENTS', width: 120),
                _buildTableHeaderCell('STATUS', width: 130),
                _buildTableHeaderCell('TIME WINDOW / TOTAL', width: 155),
                const SizedBox(width: 36),
              ],
            ),
          ),

          // Table Rows
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_outlined, size: 30, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isGlobalStatusFilter
                          ? 'No $_selectedStatus tasks found in $_selectedDateFilter'
                          : 'No tasks logged for ${_getActiveDateString()}',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGlobalStatusFilter
                          ? 'Active tasks in the selected timeframe will appear here.'
                          : 'Select Today, Yesterday, or click "+ Add New Work" above to log hours for this day.',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFF8FAFC),
                indent: 24,
                endIndent: 24,
              ),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTableRow(task);
              },
            ),

          // Table Footer Summary & Sort
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isGlobalStatusFilter
                      ? 'Showing ${tasks.length} studio assignments ($_selectedStatus • $_selectedDateFilter)'
                      : 'Showing ${tasks.length} studio assignments for ${_getActiveDateString()} ($_selectedDateFilter)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: const Color(0xFF8E9BAE),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _tasks = _tasks.reversed.toList();
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        'Sort: By Recent',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.swap_vert_rounded, size: 14, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {double? width, int? flex}) {
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

  Widget _buildTableRow(StudioTask task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // DATE
          SizedBox(
            width: 95,
            child: Text(
              task.date,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ),

          // ASSIGNED TO
          SizedBox(
            width: 165,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    task.avatarUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 32,
                      height: 32,
                      color: const Color(0xFFCBD5E1),
                      child: Center(
                        child: Text(
                          task.designerName[0],
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.designerName,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        task.designerRole,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // WORK NAME
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.workName,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Text(
                //   task.clientName,
                //   style: GoogleFonts.inter(
                //     fontSize: 11,
                //     fontWeight: FontWeight.w500,
                //     color: const Color(0xFF2563EB),
                //   ),
                //   overflow: TextOverflow.ellipsis,
                // ),
              ],
            ),
          ),

          // TYPE (Pill)
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.typeTag,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF312E81),
                  ),
                ),
              ),
            ),
          ),

          // WORK BRIEF & CONTENT
          Expanded(
            flex: 3,
            child: Text(
              task.workBrief,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ATTACHMENTS BUTTON
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _openAttachDialog(task),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.attachments.isNotEmpty ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: task.attachments.isNotEmpty ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task.attachments.isNotEmpty ? Icons.image_rounded : Icons.attach_file_rounded,
                        size: 13,
                        color: task.attachments.isNotEmpty ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.attachments.isNotEmpty ? '${task.attachments.length} files' : '+ Attach',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: task.attachments.isNotEmpty ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // STATUS PILL
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _openUpdateStatusDialog(task),
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
          ),

          // TIME WINDOW / TOTAL
          SizedBox(
            width: 155,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  task.timeWindow,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.timeLogged,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Context 3-dots action menu with Update Status, Edit, Attach, Delete
          SizedBox(
            width: 36,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF64748B)),
                tooltip: 'Task Actions',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 4,
                onSelected: (action) {
                  if (action == 'status') {
                    _openUpdateStatusDialog(task);
                  } else if (action == 'edit') {
                    _openEditTaskDialog(task);
                  } else if (action == 'attach') {
                    _openAttachDialog(task);
                  } else if (action == 'delete') {
                    _openDeleteConfirmDialog(task);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        const Icon(Icons.published_with_changes_rounded, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        Text(
                          'Update Status',
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 10),
                        Text(
                          'Edit Task',
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'attach',
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file_rounded, size: 16, color: Color(0xFF059669)),
                        const SizedBox(width: 10),
                        Text(
                          'Attach Screenshot',
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 10),
                        Text(
                          'Delete Task',
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM ANALYTICS ROW (3 CARDS) ---
  Widget _buildBottomAnalyticsRow({required bool isNarrow}) {
    final card1 = _buildTeamCapacityCard();
    final card2 = _buildDailyCadenceCard();
    final card3 = _buildNextScheduledDropCard();

    if (isNarrow) {
      return Column(
        children: [
          card1,
          const SizedBox(height: 20),
          card2,
          const SizedBox(height: 20),
          card3,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: card1),
        const SizedBox(width: 20),
        Expanded(child: card2),
        const SizedBox(width: 20),
        Expanded(child: card3),
      ],
    );
  }

  // Card 1: Team Capacity Matrix
  Widget _buildTeamCapacityCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEKLY ALLOCATION',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: const Color(0xFF8E9BAE),
                ),
              ),
              Text(
                '78% Target',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Team Capacity Matrix',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Studio target is 160 weekly hours across the 4 core creative leads.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          ..._capacities.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${item.currentHours.toInt()}h / ${item.maxHours.toInt()}h',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          color: const Color(0xFF8E9BAE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: item.percentage,
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            color: item.name == 'Liam Vance'
                                ? const Color(0xFFC7D2FE)
                                : const Color(0xFF3730A3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Card 2: Daily Logged Cadence
  Widget _buildDailyCadenceCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OUTPUT VELOCITY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: const Color(0xFF8E9BAE),
                ),
              ),
              Text(
                'Last 5 Days',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Daily Logged Cadence',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aggregated production hours tracked in the studio system.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _cadenceData.map((item) {
                const double maxVal = 40.0;
                final double heightFactor = (item.hours ?? 0) / maxVal;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (item.hours != null)
                          Text(
                            '${item.hours!.toInt()}h',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: item.isHighlighted ? FontWeight.w700 : FontWeight.w500,
                              color: item.isHighlighted ? const Color(0xFF25206A) : const Color(0xFF64748B),
                            ),
                          )
                        else
                          Text(
                            '--',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          height: item.hours != null ? (heightFactor * 85) : 4,
                          decoration: BoxDecoration(
                            color: item.isHighlighted
                                ? const Color(0xFF25206A)
                                : item.hours != null
                                    ? const Color(0xFFDBEAFE)
                                    : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.day,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Next Scheduled Drop
  Widget _buildNextScheduledDropCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FAST DISPATCH',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: const Color(0xFF8E9BAE),
                ),
              ),
              Text(
                'Keyboard: [N]',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Next Scheduled Drop',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Client deliverables pending review before 06:00 PM today.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ..._scheduledDrops.map((drop) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drop.title,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${drop.designer} • ${drop.time}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      drop.badge,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF312E81),
                      ),
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
