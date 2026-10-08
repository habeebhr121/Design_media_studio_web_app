import 'dart:async';
import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studio_track/data/designers_list.dart';
import 'package:studio_track/data/dummy_data.dart';
import 'package:studio_track/services/firebase_task_service.dart';

// --- DATA MODELS ---

enum TaskStatus {
  inProgress('In Progress', Color(0xFF3B82F6), Color(0xFFEFF6FF), Color(0xFF2563EB)),
  completed('Completed', Color(0xFF10B981), Color(0xFFECFDF5), Color(0xFF047857)),
  pending('Pending', Color(0xFFEF4444), Color(0xFFFEF2F2), Color(0xFFB91C1C)),
  progressed('Progressed', Color(0xFFF59E0B), Color(0xFFFFFBEB), Color(0xFFB45309));

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
  final String? localPath;
  final Uint8List? bytes;

  TaskAttachment({
    required this.id,
    required this.name,
    this.imageUrl = '',
    required this.fileSize,
    required this.uploadedAt,
    this.localPath,
    this.bytes,
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
  bool isPriority;

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
    this.isPriority = false,
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
  DateTime _currentIstTime = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tableSearchController = TextEditingController();

  late List<StudioTask> _tasks;

  @override
  void initState() {
    super.initState();
    _selectedDateFilter = 'Today';
    _selectedCustomDate = DateTime(2024, 10, 22);
    _startTimer();
    _initData();
  }

  void _startTimer() {
    _updateIstTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateIstTime();
      }
    });
  }

  void _updateIstTime() {
    final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    setState(() {
      _currentIstTime = ist;
    });
  }

  String _formatCurrentIstTime() {
    final now = _currentIstTime;
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final hourStr = hour12.toString().padLeft(2, '0');
    return '$hourStr:$minute:$second $period';
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

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final minuteStr = tod.minute.toString().padLeft(2, '0');
    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr $period';
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

  ({String startTime, String endTime}) _parseTimeWindow(String timeWindow) {
    final parts = timeWindow.split('-');
    if (parts.length >= 2) {
      return (startTime: parts[0].trim(), endTime: parts[1].trim());
    }
    return (startTime: timeWindow.trim(), endTime: '---');
  }

  ({int hours, int minutes, double totalDecimalHours, String formattedLogged}) _calculateTimeLogged(TimeOfDay start, TimeOfDay end) {
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;
    int diffMinutes = endMinutes - startMinutes;
    if (diffMinutes < 0) {
      diffMinutes += 24 * 60;
    }
    int h = diffMinutes ~/ 60;
    int m = diffMinutes % 60;
    double totalDec = h + (m / 60.0);
    String formatted = '${h}h ${m.toString().padLeft(2, '0')}m logged';
    return (hours: h, minutes: m, totalDecimalHours: totalDec, formattedLogged: formatted);
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
          return _calculateTimeLogged(st, et).totalDecimalHours;
        }
      }
    }
    return 0.0;
  }

  Widget _buildTimePresetChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  int _markPreviousPendingTasksAsProgressed(String workName, {String? excludeTaskId}) {
    final targetName = workName.trim().toLowerCase();
    if (targetName.isEmpty) return 0;
    int count = 0;
    for (final t in _tasks) {
      if (t.id != excludeTaskId &&
          t.workName.trim().toLowerCase() == targetName &&
          t.status == TaskStatus.pending) {
        t.status = TaskStatus.progressed;
        count++;
      }
    }
    return count;
  }

  bool _isTaskInActiveTimeframe(StudioTask task) {
    final isGlobalStatusFilter = _selectedStatus == 'In Progress' ||
        _selectedStatus == 'Pending';

    final taskDate = _parseTaskDate(task.date);
    final refDate = DateTime(2024, 10, 24); // Reference "Today" date
    final diff = refDate.difference(taskDate).inDays;

    if (isGlobalStatusFilter) {
      // When In Progress or Pending is active:
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

  StreamSubscription<List<StudioTask>>? _tasksSubscription;

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _timer.cancel();
    _searchController.dispose();
    _tableSearchController.dispose();
    super.dispose();
  }

  void _initData() {
    _tasks = List<StudioTask>.from(tasks);
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
        debugPrint('Firestore tasks stream notice: $e');
      });

      FirebaseTaskService().fetchTasks().then((fetched) {
        if (fetched.isNotEmpty && mounted) {
          setState(() {
            _tasks = fetched;
          });
        }
      }).catchError((e) {
        debugPrint('Firestore initial fetch notice: $e');
      });
    } catch (e) {
      debugPrint('Firebase sync error: $e');
    }
  }

  List<DesignerCapacity> get _capacities {
    return designers.map((designer) {
      double loggedHours = 0.0;
      for (final t in _tasks) {
        final matches = t.designerName.trim().toLowerCase() == designer.name.trim().toLowerCase() ||
            t.designerName.toLowerCase().contains(designer.name.toLowerCase()) ||
            designer.name.toLowerCase().contains(t.designerName.toLowerCase());
        if (matches) {
          loggedHours += _parseLoggedHours(t.timeLogged, t.timeWindow);
        }
      }

      return DesignerCapacity(
        name: designer.name,
        currentHours: loggedHours,
        maxHours: 40.0,
      );
    }).toList();
  }

  List<DailyCadence> get _cadenceData {
    double calculateHoursForDates(List<String> matchingDates) {
      double total = 0.0;
      for (final t in _tasks) {
        if (matchingDates.contains(t.date)) {
          total += _parseLoggedHours(t.timeLogged, t.timeWindow);
        }
      }
      return total;
    }

    final monHours = calculateHoursForDates(['Oct 21, 2024', 'Oct 20, 2024', 'Oct 18, 2024']);
    final tueHours = calculateHoursForDates(['Oct 22, 2024']);
    final wedHours = calculateHoursForDates(['Oct 23, 2024']);
    final thuHours = calculateHoursForDates(['Oct 24, 2024']);
    final friTasks = _tasks.where((t) => t.date == 'Oct 25, 2024').toList();
    final friHours = friTasks.isNotEmpty ? calculateHoursForDates(['Oct 25, 2024']) : null;

    return [
      DailyCadence(day: 'Mon', hours: monHours > 0 ? monHours : 31),
      DailyCadence(day: 'Tue', hours: tueHours > 0 ? tueHours : 28),
      DailyCadence(day: 'Wed', hours: wedHours > 0 ? wedHours : 35),
      DailyCadence(day: 'Thu', hours: thuHours > 0 ? (thuHours < 20 ? 16 + thuHours : thuHours) : 32, isHighlighted: true),
      DailyCadence(day: 'Fri', hours: friHours),
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

  // --- ACTIONS: WORK BRIEF POPUP, UPDATE STATUS, EDIT, ATTACH, DELETE ---

  void _openWorkBriefDialog(StudioTask task) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: 580,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                          child: const Icon(Icons.description_outlined, size: 20, color: Color(0xFF25206A)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Work Brief & Details',
                          style: GoogleFonts.inter(
                            fontSize: 18,
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
                const SizedBox(height: 18),

                // Main Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task & Client Banner
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.isPriority) ...[
                                    Container(
                                      margin: const EdgeInsets.only(right: 8, top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFFECDD3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFE11D48)),
                                          const SizedBox(width: 2),
                                          Text(
                                            'HIGH',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFE11D48),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  Expanded(
                                    child: Text(
                                      task.workName,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      task.typeTag,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF312E81),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildDesignerAvatar(task.avatarUrl, task.designerName, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    task.designerName,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    ' (${task.designerRole})',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Client: ${task.clientName}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section Header: Work Brief & Content
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'WORK BRIEF & CONTENT',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: task.workBrief));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Brief copied to clipboard'),
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF25206A)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF25206A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Full Work Brief Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: SelectableText(
                            task.workBrief.isEmpty ? 'No additional brief details provided.' : task.workBrief,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13.5,
                              height: 1.6,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Time & Status Info Bar
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TIME WINDOW',
                                      style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${task.date} • ${task.timeWindow}',
                                      style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: task.status.bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CURRENT STATUS',
                                      style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.w700, color: task.status.textColor),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: task.status.dotColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          task.status.label,
                                          style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: task.status.textColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Attachments Preview if any
                        if (task.attachments.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'ATTACHMENTS (${task.attachments.length})',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: task.attachments.map((att) {
                              return InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _openAttachmentPreviewDialog(att),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.image_outlined, size: 14, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 6),
                                      Text(
                                        att.name,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.zoom_in_rounded, size: 13, color: Color(0xFF3B82F6)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Footer Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openEditTaskDialog(task);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF25206A)),
                      label: Text(
                        'Edit Task',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF25206A)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  }

  void _openUpdateStatusDialog(StudioTask task) {
    TaskStatus currentStatus = task.status;
    final parsedTimes = _parseTimeWindow(task.timeWindow);
    TimeOfDay startTime = _parseTimeString(parsedTimes.startTime) ?? const TimeOfDay(hour: 9, minute: 30);
    TimeOfDay endTime = (parsedTimes.endTime != '---' && _parseTimeString(parsedTimes.endTime) != null)
        ? _parseTimeString(parsedTimes.endTime)!
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final calculated = _calculateTimeLogged(startTime, endTime);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
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
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                      const SizedBox(height: 18),

                      // Status Selection Options
                      Text(
                        'SELECT STATUS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...TaskStatus.values.map((s) {
                        final isSelected = currentStatus == s;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setDialogState(() {
                              currentStatus = s;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: s.dotColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    s.label,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12.5,
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

                      const SizedBox(height: 12),

                      // TIME LOGGING SECTION
                      if (currentStatus == TaskStatus.inProgress) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timelapse_rounded, size: 18, color: Color(0xFF2563EB)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Active In Progress Session',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Started at ${_formatTimeOfDay(startTime)} • End time: --- (Will calculate total hours when finished/pending)',
                                      style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: const Color(0xFF3B82F6)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Option to enter/pick End Time and Start Time for Pending or Completed
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF25206A)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'WORK TIME & END TIME ENTRY',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.9,
                                      color: const Color(0xFF25206A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Start Time and End Time Row
                              Row(
                                children: [
                                  // Start Time Picker
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'START TIME',
                                          style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: () async {
                                            final picked = await showTimePicker(
                                              context: context,
                                              initialTime: startTime,
                                            );
                                            if (picked != null) {
                                              setDialogState(() => startTime = picked);
                                            }
                                          },
                                          child: Container(
                                            height: 38,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFCBD5E1)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _formatTimeOfDay(startTime),
                                                  style: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                                                ),
                                                const Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF64748B)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // End Time Picker
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'END TIME',
                                          style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                                        ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: () async {
                                            final picked = await showTimePicker(
                                              context: context,
                                              initialTime: endTime,
                                            );
                                            if (picked != null) {
                                              setDialogState(() => endTime = picked);
                                            }
                                          },
                                          child: Container(
                                            height: 38,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEF2FF),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFF818CF8)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _formatTimeOfDay(endTime),
                                                  style: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF312E81)),
                                                ),
                                                const Icon(Icons.edit_calendar_rounded, size: 15, color: Color(0xFF4F46E5)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Quick End Time presets
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Text('Presets: ', style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: const Color(0xFF94A3B8))),
                                    _buildTimePresetChip('Now', () {
                                      setDialogState(() => endTime = TimeOfDay.now());
                                    }),
                                    _buildTimePresetChip('+1h', () {
                                      setDialogState(() => endTime = TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute));
                                    }),
                                    _buildTimePresetChip('+2h', () {
                                      setDialogState(() => endTime = TimeOfDay(hour: (startTime.hour + 2) % 24, minute: startTime.minute));
                                    }),
                                    _buildTimePresetChip('+3.5h', () {
                                      final totalM = startTime.hour * 60 + startTime.minute + 210;
                                      setDialogState(() => endTime = TimeOfDay(hour: (totalM ~/ 60) % 24, minute: totalM % 60));
                                    }),
                                    _buildTimePresetChip('+4h', () {
                                      setDialogState(() => endTime = TimeOfDay(hour: (startTime.hour + 4) % 24, minute: startTime.minute));
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Live Automatic Total Hours Calculation Display
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF16A34A)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Total Logged: ${calculated.formattedLogged} (${calculated.totalDecimalHours.toStringAsFixed(1)} hrs)',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF15803D),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

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
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              int progressedCount = 0;
                              setState(() {
                                task.status = currentStatus;
                                if (currentStatus == TaskStatus.inProgress) {
                                  task.timeWindow = '${_formatTimeOfDay(startTime)} - ---';
                                  task.timeLogged = 'In progress';
                                } else {
                                  task.timeWindow = '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}';
                                  task.timeLogged = calculated.formattedLogged;
                                }

                                if (currentStatus == TaskStatus.completed) {
                                  progressedCount = _markPreviousPendingTasksAsProgressed(task.workName, excludeTaskId: task.id);
                                  FirebaseTaskService().cascadeProgressForWork(task.workName, task.id);
                                }
                              });
                              FirebaseTaskService().updateTask(task);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    currentStatus == TaskStatus.inProgress
                                        ? 'Status set to In Progress for "${task.workName}"'
                                        : progressedCount > 0
                                            ? 'Completed "${task.workName}" • $progressedCount previous pending task(s) updated to Progressed'
                                            : 'Updated "${task.workName}" to ${currentStatus.label} • Logged: ${calculated.formattedLogged}',
                                  ),
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
    final parsedTimes = _parseTimeWindow(task.timeWindow);
    TimeOfDay selectedStartTime = _parseTimeString(parsedTimes.startTime) ?? const TimeOfDay(hour: 9, minute: 30);
    TimeOfDay? selectedEndTime = (parsedTimes.endTime != '---' && _parseTimeString(parsedTimes.endTime) != null)
        ? _parseTimeString(parsedTimes.endTime)
        : null;
    String selectedDateStr = task.date;
    String selectedDesignerName = task.designerName;
    String selectedType = task.typeTag;
    TaskStatus selectedStatus = task.status;
    bool isPriority = task.isPriority;

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
                        Expanded(
                          child: Column(
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
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  isPriority = !isPriority;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isPriority ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isPriority ? const Color(0xFFF43F5E) : const Color(0xFFCBD5E1),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPriority ? Icons.bolt_rounded : Icons.bolt_outlined,
                                      size: 15,
                                      color: isPriority ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isPriority ? 'High Priority' : 'Mark Priority',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: isPriority ? FontWeight.w700 : FontWeight.w500,
                                        color: isPriority ? const Color(0xFFE11D48) : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
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
                                    value: designers.any((d) => d.name == selectedDesignerName)
                                        ? selectedDesignerName
                                        : designers.first.name,
                                    isExpanded: true,
                                    icon: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF475569)),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    items: designers.map((d) {
                                      return DropdownMenuItem(
                                        value: d.name,
                                        child: Text(d.name),
                                      );
                                    }).toList(),
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
                                      DropdownMenuItem(value: TaskStatus.pending, child: Text('Pending')),
                                      DropdownMenuItem(value: TaskStatus.completed, child: Text('Completed')),
                                      DropdownMenuItem(value: TaskStatus.progressed, child: Text('Progressed')),
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
                        // START TIME
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'START TIME',
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
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedStartTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() => selectedStartTime = picked);
                                  }
                                },
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F4FA),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatTimeOfDay(selectedStartTime),
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF4F46E5)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // END TIME
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'END TIME',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.9,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  if (selectedEndTime != null)
                                    InkWell(
                                      onTap: () => setDialogState(() => selectedEndTime = null),
                                      child: Text(
                                        'Clear (---)',
                                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFDC2626), fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedEndTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => selectedEndTime = picked);
                                  }
                                },
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: selectedEndTime != null ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: selectedEndTime != null ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedEndTime != null ? _formatTimeOfDay(selectedEndTime!) : '---',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12,
                                          fontWeight: selectedEndTime != null ? FontWeight.w700 : FontWeight.w500,
                                          color: selectedEndTime != null ? const Color(0xFF312E81) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit_calendar_rounded,
                                        size: 16,
                                        color: selectedEndTime != null ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Automatic calculation summary in Edit Dialog
                    if (selectedEndTime != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Calculated: ${_calculateTimeLogged(selectedStartTime, selectedEndTime!).formattedLogged}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
                            final found = designers.firstWhere(
                              (d) => d.name.toLowerCase() == selectedDesignerName.toLowerCase(),
                              orElse: () => designers.first,
                            );
                            String role = found.designation;
                            String avatar = found.imagePath;

                            String finalWindow;
                            String finalLogged;
                            if (selectedEndTime != null && selectedStatus != TaskStatus.inProgress) {
                              final calc = _calculateTimeLogged(selectedStartTime, selectedEndTime!);
                              finalWindow = '${_formatTimeOfDay(selectedStartTime)} - ${_formatTimeOfDay(selectedEndTime!)}';
                              finalLogged = calc.formattedLogged;
                            } else if (selectedStatus == TaskStatus.inProgress) {
                              finalWindow = '${_formatTimeOfDay(selectedStartTime)} - ---';
                              finalLogged = 'In progress';
                            } else {
                              finalWindow = '${_formatTimeOfDay(selectedStartTime)} - ---';
                              finalLogged = '---';
                            }

                            int progressedCount = 0;
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
                              task.timeWindow = finalWindow;
                              task.timeLogged = finalLogged;
                              task.isPriority = isPriority;

                              if (selectedStatus == TaskStatus.completed) {
                                progressedCount = _markPreviousPendingTasksAsProgressed(task.workName, excludeTaskId: task.id);
                                FirebaseTaskService().cascadeProgressForWork(task.workName, task.id);
                              }
                            });
                            FirebaseTaskService().updateTask(task);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  progressedCount > 0
                                      ? 'Updated "${task.workName}" • $progressedCount previous pending task(s) updated to Progressed'
                                      : 'Updated "${task.workName}"',
                                ),
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

  Widget _buildAttachmentThumbnail(TaskAttachment att) {
    if (att.bytes != null && att.bytes!.isNotEmpty) {
      return Image.memory(
        att.bytes!,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAttachmentIcon(att.name),
      );
    }
    if (!kIsWeb && att.localPath != null && att.localPath!.isNotEmpty) {
      return Image.file(
        File(att.localPath!),
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAttachmentIcon(att.name),
      );
    }
    if (att.imageUrl.isNotEmpty) {
      return Image.network(
        att.imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAttachmentIcon(att.name),
      );
    }
    return _buildFallbackAttachmentIcon(att.name);
  }

  Widget _buildFallbackAttachmentIcon(String fileName) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : 'FILE';
    final isImageExt = ['PNG', 'JPG', 'JPEG', 'WEBP', 'GIF', 'SVG'].contains(ext);

    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isImageExt ? Icons.image_outlined : Icons.insert_drive_file_outlined,
              size: 28,
              color: const Color(0xFF64748B),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ext,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FULLSCREEN ATTACHMENT / IMAGE PREVIEW MODAL ---
  void _openAttachmentPreviewDialog(TaskAttachment att) {
    final ext = att.name.contains('.') ? att.name.split('.').last.toUpperCase() : 'FILE';
    final isImage = ['PNG', 'JPG', 'JPEG', 'WEBP', 'GIF', 'SVG', 'BMP', 'ICO'].contains(ext) || att.imageUrl.isNotEmpty || (att.bytes != null && att.bytes!.isNotEmpty);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 950, maxHeight: 750),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  color: const Color(0xFF1E293B),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                          size: 18,
                          color: const Color(0xFF93C5FD),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              att.name,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${att.fileSize} • Uploaded ${att.uploadedAt}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ext,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFFCBD5E1)),
                        splashRadius: 20,
                        tooltip: 'Close Preview',
                      ),
                    ],
                  ),
                ),

                // Main Content View Area
                Expanded(
                  child: Container(
                    color: const Color(0xFF020617),
                    alignment: Alignment.center,
                    child: isImage
                        ? InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Center(
                              child: _buildFullAttachmentImage(att),
                            ),
                          )
                        : _buildNonImageFilePreview(att, ext),
                  ),
                ),

                // Footer Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: const Color(0xFF1E293B),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isImage ? 'Pinch or scroll to zoom • Drag to pan' : 'Document deliverable',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.check_rounded, size: 15),
                        label: Text(
                          'Close',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullAttachmentImage(TaskAttachment att) {
    if (att.bytes != null && att.bytes!.isNotEmpty) {
      return Image.memory(
        att.bytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAttachmentIcon(att.name),
      );
    }
    if (!kIsWeb && att.localPath != null && att.localPath!.isNotEmpty) {
      return Image.file(
        File(att.localPath!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAttachmentIcon(att.name),
      );
    }
    if (att.imageUrl.isNotEmpty) {
      return Image.network(
        att.imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallbackAttachmentIcon(att.name),
      );
    }
    return _buildFallbackAttachmentIcon(att.name);
  }

  Widget _buildNonImageFilePreview(TaskAttachment att, String ext) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Icon(
            Icons.insert_drive_file_outlined,
            size: 56,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          att.name,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$ext Document • ${att.fileSize}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  void _openAttachDialog(StudioTask task) {
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

    Future<void> pickFilesFromDevice(void Function(void Function()) setDialogState) async {
      try {
        const int maxAttachmentBytes = 10 * 1024 * 1024; // 10 MB Limit

        final result = await FilePickerPlatform.instance.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'svg', 'pdf', 'mp4', 'mov', 'zip', 'psd', 'ai', 'fig'],
        );

        if (result.isNotEmpty) {
          for (final file in result) {
            Uint8List? fileBytes;
            int fileSize = 0;
            try {
              fileBytes = await file.readAsBytes();
              fileSize = (await file.length()) ?? 0;
            } catch (_) {
              if (file.path != null && !kIsWeb) {
                final ioFile = File(file.path!);
                if (ioFile.existsSync()) {
                  fileSize = ioFile.lengthSync();
                  fileBytes = ioFile.readAsBytesSync();
                }
              }
            }

            if (fileSize > maxAttachmentBytes) {
              if (mounted) {
                final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'File "${file.name}" exceeds the 10 MB limit ($sizeMb MB).',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFE11D48),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
              continue; // Skip oversized file
            }

            final sizeInKb = (fileSize / 1024);
            final formattedSize = sizeInKb > 1024
                ? '${(sizeInKb / 1024).toStringAsFixed(1)} MB'
                : (sizeInKb > 0 ? '${sizeInKb.toStringAsFixed(0)} KB' : '350 KB');

            final now = DateTime.now();
            final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
            final ampm = now.hour >= 12 ? 'PM' : 'AM';
            final minute = now.minute.toString().padLeft(2, '0');
            final timeStr = '$hour:$minute $ampm';

            setDialogState(() {
              task.attachments.add(
                TaskAttachment(
                  id: '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
                  name: file.name,
                  imageUrl: '',
                  localPath: file.path,
                  bytes: fileBytes,
                  fileSize: formattedSize,
                  uploadedAt: timeStr,
                ),
              );
            });
          }
          setState(() {});
        }
      } catch (e) {
        debugPrint('Error picking file: $e');
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              child: Container(
                width: 620,
                padding: const EdgeInsets.all(26),
                child: SingleChildScrollView(
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

                      // Desktop / Device File Picker Drag-and-Drop Area
                      InkWell(
                        onTap: () => pickFilesFromDevice(setDialogState),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.desktop_mac_rounded, size: 28, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Browse Files from Desktop / Device',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Click anywhere here to open Finder / File Explorer',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Supports PNG, JPG, JPEG, SVG, PDF, PSD, AI, FIG, MP4 up to 10 MB',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () => pickFilesFromDevice(setDialogState),
                                icon: const Icon(Icons.folder_open_rounded, size: 16),
                                label: Text(
                                  'Browse Desktop',
                                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25206A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      if (task.attachments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 8),
                                Text(
                                  'No files attached yet. Browse from your device above.',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Attached Deliverables (${task.attachments.length})',
                                  style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                                ),
                                TextButton.icon(
                                  onPressed: () => pickFilesFromDevice(setDialogState),
                                  icon: const Icon(Icons.add_rounded, size: 14, color: Color(0xFF2563EB)),
                                  label: Text(
                                    'Add More Files',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 130,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: task.attachments.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final att = task.attachments[index];
                                  return Stack(
                                    children: [
                                      InkWell(
                                        onTap: () => _openAttachmentPreviewDialog(att),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Tooltip(
                                          message: 'Click to view / inspect full image',
                                          child: Container(
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
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      _buildAttachmentThumbnail(att),
                                                      Positioned(
                                                        bottom: 5,
                                                        left: 5,
                                                        child: Container(
                                                          padding: const EdgeInsets.all(3),
                                                          decoration: BoxDecoration(
                                                            color: Colors.black.withValues(alpha: 0.6),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: const Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.zoom_in_rounded, size: 12, color: Colors.white),
                                                              SizedBox(width: 2),
                                                              Text(
                                                                'View',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
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

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25206A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              FirebaseTaskService().updateTask(task);
                              Navigator.pop(ctx);
                            },
                            child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                FirebaseTaskService().deleteTask(task.id);
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

  String _mapDesignerName(String name) {
    for (final d in designers) {
      if (name.toLowerCase().contains(d.name.toLowerCase()) || d.name.toLowerCase().contains(name.toLowerCase())) {
        return d.name;
      }
    }
    return designers.isNotEmpty ? designers.first.name : 'Jawad';
  }

  String _mapTypeTag(String tag) {
    if (['Logo', 'UI / UX', 'Poster / Print', 'Video / 3D', 'Editing / Retouch'].contains(tag)) {
      return tag;
    }
    final lower = tag.toLowerCase();
    if (lower.contains('ui') || lower.contains('ux')) return 'UI / UX';
    if (lower.contains('poster') || lower.contains('print')) return 'Poster / Print';
    if (lower.contains('video') || lower.contains('3d') || lower.contains('motion')) return 'Video / 3D';
    if (lower.contains('edit') || lower.contains('retouch')) return 'Editing / Retouch';
    return 'Logo';
  }

  void _openAddNewWorkDialog({StudioTask? initialPendingTask}) {
    // Deduplicate pending tasks by workName (case-insensitive)
    final uniquePendingTasks = <StudioTask>[];
    final seenWorkNames = <String>{};
    for (final t in _tasks) {
      if (t.status == TaskStatus.pending) {
        final key = t.workName.trim().toLowerCase();
        if (key.isNotEmpty && !seenWorkNames.contains(key)) {
          seenWorkNames.add(key);
          uniquePendingTasks.add(t);
        }
      }
    }

    StudioTask? selectedPendingTask = initialPendingTask;
    final workNameCtrl = TextEditingController(text: initialPendingTask?.workName ?? '');
    final clientCtrl = TextEditingController(text: initialPendingTask?.clientName ?? '');
    final briefCtrl = TextEditingController(text: initialPendingTask?.workBrief ?? '');
    TimeOfDay selectedStartTime = TimeOfDay.now();
    String selectedDateStr = _getActiveDateString();
    String selectedDesignerName = initialPendingTask != null
        ? _mapDesignerName(initialPendingTask.designerName)
        : designers.first.name;
    String selectedType = initialPendingTask != null
        ? _mapTypeTag(initialPendingTask.typeTag)
        : 'Logo';
    TaskStatus selectedStatus = TaskStatus.inProgress;
    bool isPriority = initialPendingTask?.isPriority ?? false;

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
                width: 580,
                padding: const EdgeInsets.all(32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Eyebrow and Close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
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
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    isPriority = !isPriority;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isPriority ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isPriority ? const Color(0xFFF43F5E) : const Color(0xFFCBD5E1),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPriority ? Icons.bolt_rounded : Icons.bolt_outlined,
                                        size: 15,
                                        color: isPriority ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPriority ? 'High Priority' : 'Mark Priority',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: isPriority ? FontWeight.w700 : FontWeight.w500,
                                          color: isPriority ? const Color(0xFFE11D48) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                                splashRadius: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // SECTION: SELECT PENDING TASK FOR TODAY (Deduplicated)
                      if (uniquePendingTasks.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedPendingTask != null ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                              width: selectedPendingTask != null ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.playlist_add_check_circle_rounded,
                                            size: 16,
                                            color: Color(0xFF322A86),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'SELECT PENDING TASK FOR TODAY',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.0,
                                              color: const Color(0xFF322A86),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: Text(
                                      '${uniquePendingTasks.length} Pending (Unique)',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Dropdown Selector for all pending tasks
                              Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedPendingTask?.workName,
                                    hint: Text(
                                      'Choose a pending task to import as new work...',
                                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                                    ),
                                    isExpanded: true,
                                    icon: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF475569)),
                                    items: [
                                      for (final pt in uniquePendingTasks)
                                        DropdownMenuItem(
                                          value: pt.workName,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFFF59E0B),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  pt.workName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${pt.typeTag} • ${pt.designerName}',
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 11,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) return;
                                      final match = uniquePendingTasks.firstWhere((p) => p.workName == val);
                                      setDialogState(() {
                                        selectedPendingTask = match;
                                        workNameCtrl.text = match.workName;
                                        clientCtrl.text = match.clientName;
                                        briefCtrl.text = match.workBrief;
                                        selectedDesignerName = _mapDesignerName(match.designerName);
                                        selectedType = _mapTypeTag(match.typeTag);
                                        selectedStatus = TaskStatus.inProgress;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Quick Clickable Horizontal Chips
                              // SingleChildScrollView(
                              //   scrollDirection: Axis.horizontal,
                              //   child: Row(
                              //     children: [
                              //       for (final pt in uniquePendingTasks) ...[
                              //         Padding(
                              //           padding: const EdgeInsets.only(right: 8),
                              //           child: InkWell(
                              //             borderRadius: BorderRadius.circular(6),
                              //             onTap: () {
                              //               setDialogState(() {
                              //                 selectedPendingTask = pt;
                              //                 workNameCtrl.text = pt.workName;
                              //                 clientCtrl.text = pt.clientName;
                              //                 briefCtrl.text = pt.workBrief;
                              //                 selectedDesignerName = _mapDesignerName(pt.designerName);
                              //                 selectedType = _mapTypeTag(pt.typeTag);
                              //                 selectedStatus = TaskStatus.inProgress;
                              //               });
                              //             },
                              //             child: Container(
                              //               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              //               decoration: BoxDecoration(
                              //                 color: selectedPendingTask?.workName == pt.workName
                              //                     ? const Color(0xFF322A86)
                              //                     : Colors.white,
                              //                 borderRadius: BorderRadius.circular(6),
                              //                 border: Border.all(
                              //                   color: selectedPendingTask?.workName == pt.workName
                              //                       ? const Color(0xFF322A86)
                              //                       : const Color(0xFFE2E8F0),
                              //                 ),
                              //               ),
                              //               child: Row(
                              //                 mainAxisSize: MainAxisSize.min,
                              //                 children: [
                              //                   Icon(
                              //                     selectedPendingTask?.workName == pt.workName
                              //                         ? Icons.check_circle_rounded
                              //                         : Icons.pending_actions_rounded,
                              //                     size: 13,
                              //                     color: selectedPendingTask?.workName == pt.workName
                              //                         ? Colors.white
                              //                         : const Color(0xFFF59E0B),
                              //                   ),
                              //                   const SizedBox(width: 6),
                              //                   Text(
                              //                     pt.workName,
                              //                     style: GoogleFonts.inter(
                              //                       fontSize: 11.5,
                              //                       fontWeight: selectedPendingTask?.workName == pt.workName
                              //                           ? FontWeight.w700
                              //                           : FontWeight.w500,
                              //                       color: selectedPendingTask?.workName == pt.workName
                              //                           ? Colors.white
                              //                           : const Color(0xFF334155),
                              //                     ),
                              //                   ),
                              //                 ],
                              //               ),
                              //             ),
                              //           ),
                              //         ),
                              //       ],
                              //     ],
                              //   ),
                              // ),

                              if (selectedPendingTask != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Prefilled from pending queue. Adjust details if needed.',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF16A34A),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          selectedPendingTask = null;
                                          workNameCtrl.clear();
                                          clientCtrl.clear();
                                          briefCtrl.clear();
                                          selectedType = 'Logo';
                                          selectedDesignerName = designers.first.name;
                                          selectedStatus = TaskStatus.inProgress;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Text(
                                          'Clear / New Work',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

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
                                      value: designers.any((d) => d.name == selectedDesignerName)
                                          ? selectedDesignerName
                                          : designers.first.name,
                                      isExpanded: true,
                                      icon: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF475569)),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF0F172A),
                                      ),
                                      items: designers.map((d) {
                                        return DropdownMenuItem(
                                          value: d.name,
                                          child: Text(d.name),
                                        );
                                      }).toList(),
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

                      // ROW 4: STATUS, START TIME & END TIME
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // STATUS DROPDOWN
                          Expanded(
                            flex: 2,
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
                                        DropdownMenuItem(value: TaskStatus.pending, child: Text('Pending')),
                                        DropdownMenuItem(value: TaskStatus.completed, child: Text('Completed')),
                                        DropdownMenuItem(value: TaskStatus.progressed, child: Text('Progressed')),
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

                          // START TIME (Fetched accordingly)
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'START TIME',
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
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: selectedStartTime,
                                    );
                                    if (picked != null) {
                                      setDialogState(() => selectedStartTime = picked);
                                    }
                                  },
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F4FA),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatTimeOfDay(selectedStartTime),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF4F46E5)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // END TIME (Empty / ---)
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'END TIME',
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Text(
                                        '---',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '(In Progress)',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                              final found = designers.firstWhere(
                                (d) => d.name.toLowerCase() == selectedDesignerName.toLowerCase(),
                                orElse: () => designers.first,
                              );
                              String role = found.designation;
                              String avatar = found.imagePath;

                              final startTimeStr = _formatTimeOfDay(selectedStartTime);
                              String finalWindow;
                              String finalLogged;
                              if (selectedStatus == TaskStatus.inProgress) {
                                finalWindow = '$startTimeStr - ---';
                                finalLogged = 'In progress';
                              } else if (selectedStatus == TaskStatus.pending) {
                                finalWindow = '$startTimeStr - ---';
                                finalLogged = '---';
                              } else {
                                final endNow = TimeOfDay.now();
                                final calc = _calculateTimeLogged(selectedStartTime, endNow);
                                finalWindow = '$startTimeStr - ${_formatTimeOfDay(endNow)}';
                                finalLogged = calc.formattedLogged;
                              }

                              final newTask = StudioTask(
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
                                timeWindow: finalWindow,
                                timeLogged: finalLogged,
                                isPriority: isPriority,
                              );

                              int progressedCount = 0;
                              setState(() {
                                _tasks.insert(0, newTask);

                                if (selectedStatus == TaskStatus.completed) {
                                  progressedCount = _markPreviousPendingTasksAsProgressed(workNameCtrl.text.trim(), excludeTaskId: newTask.id);
                                  FirebaseTaskService().cascadeProgressForWork(workNameCtrl.text.trim(), newTask.id);
                                }
                              });
                              FirebaseTaskService().addTask(newTask);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    progressedCount > 0
                                        ? 'Created "${workNameCtrl.text.trim()}" • $progressedCount previous pending task(s) updated to Progressed'
                                        : 'Created entry "${workNameCtrl.text.trim()}" for $selectedDateStr',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
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
                final isMobile = constraints.maxWidth < 600;
                final horizontalPadding = constraints.maxWidth < 700 ? 16.0 : (constraints.maxWidth < 1200 ? 24.0 : 40.0);
                const minTableWidth = 1320.0;
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
                      _buildMetricsRow(isNarrow: isNarrow, isMobile: isMobile),
                      const SizedBox(height: 28),
                      _buildFiltersBar(isNarrow: isNarrow),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: contentWidth,
                          child: _buildDataTableCard(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildBottomAnalyticsRow(isNarrow: isNarrow),
                      const SizedBox(height: 48),
                      // _buildFooter(isNarrow: isNarrow),
                      // const SizedBox(height: 24),
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
              _buildNavTab('Workboard', isActive: true, onTap: () {}),
              const SizedBox(width: 6),
              _buildNavTab('Hours Report', isActive: false, onTap: () {
                widget.onNavigateToHoursReport?.call();
              }),
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
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
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
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (!isCompact) ...[
                Container(
                  height: 20,
                  width: 1,
                  color: const Color(0xFFE2E8F0),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
          'Media Workboard',
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
                'Live: ${_formatCurrentIstTime()}',
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
  Widget _buildMetricsRow({required bool isNarrow, bool isMobile = false}) {
    final dayTasks = _tasks.where((t) => _isTaskInActiveTimeframe(t)).toList();
    final activeCount = dayTasks.where((t) => t.status == TaskStatus.inProgress || t.status == TaskStatus.pending).length;
    final completedCount = dayTasks.where((t) => t.status == TaskStatus.completed).length;
    final activeStaffCount = dayTasks.map((t) => t.designerName).toSet().length;

    double totalHours = 0.0;
    for (final t in dayTasks) {
      totalHours += _parseLoggedHours(t.timeLogged, t.timeWindow);
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
                'STAFF:',
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
              ...designers.map((d) {
                final shortName = d.name.split(' ').first;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _buildFilterChip(shortName, isSelected: _selectedDesigner == shortName, onSelected: () {
                    setState(() => _selectedDesigner = shortName);
                  }),
                );
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
              const SizedBox(width: 6),
              // _buildFilterChip('Progressed', isSelected: _selectedStatus == 'Progressed', onSelected: () {
              //   setState(() => _selectedStatus = 'Progressed');
              // }),
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
                const SizedBox(width: 14),
                _buildTableHeaderCell('ASSIGNED TO', width: 175),
                const SizedBox(width: 16),
                _buildTableHeaderCell('WORK NAME', width: 195),
                const SizedBox(width: 16),
                _buildTableHeaderCell('TYPE', width: 130),
                const SizedBox(width: 16),
                _buildTableHeaderCell('WORK BRIEF & CONTENT', flex: 2),
                const SizedBox(width: 16),
                _buildTableHeaderCell('ATTACHMENTS', width: 120),
                const SizedBox(width: 12),
                _buildTableHeaderCell('STATUS', width: 135),
                const SizedBox(width: 12),
                _buildTableHeaderCell('TIME WINDOW / TOTAL', width: 165),
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
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGlobalStatusFilter
                          ? 'Active tasks in the selected timeframe will appear here.'
                          : 'Select Today, Yesterday, or click "+ Add New Work" above to log hours for this day.',
                      style: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF94A3B8)),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.swap_vert_rounded, size: 16, color: Color(0xFF475569)),
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: const Color(0xFF64748B),
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // ASSIGNED TO
          SizedBox(
            width: 175,
            child: Row(
              children: [
                _buildDesignerAvatar(task.avatarUrl, task.designerName, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.designerName,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        task.designerRole,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // WORK NAME
          SizedBox(
            width: 195,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.isPriority) ...[
                      Tooltip(
                        message: 'High Priority Task',
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFE11D48)),
                              const SizedBox(width: 2),
                              Text(
                                'HIGH',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        task.workName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // TYPE (Pill)
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  task.typeTag,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF312E81),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // WORK BRIEF & CONTENT (Clickable to open full popup modal)
          Expanded(
            flex: 2,
            child: Tooltip(
              message: 'Click to view entire work brief',
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _openWorkBriefDialog(task),
                hoverColor: const Color(0xFFF1F5F9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.workBrief,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.5,
                            color: const Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ATTACHMENTS BUTTON
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _openAttachDialog(task),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        size: 15,
                        color: task.attachments.isNotEmpty ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        task.attachments.isNotEmpty ? '${task.attachments.length} files' : '+ Attach',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5,
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
          const SizedBox(width: 12),

          // STATUS PILL
          SizedBox(
            width: 135,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _openUpdateStatusDialog(task),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: task.status.bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: task.status.dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          task.status.label,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11.5,
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
          const SizedBox(width: 12),

          // TIME WINDOW / TOTAL
          SizedBox(
            width: 165,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  task.timeWindow,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.timeLogged,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
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
                icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Task Actions',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 4,
                onSelected: (action) {
                  if (action == 'assign_today') {
                    _openAddNewWorkDialog(initialPendingTask: task);
                  } else if (action == 'status') {
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
                  if (task.status == TaskStatus.pending)
                    PopupMenuItem(
                      value: 'assign_today',
                      child: Row(
                        children: [
                          const Icon(Icons.today_rounded, size: 16, color: Color(0xFF322A86)),
                          const SizedBox(width: 10),
                          Text(
                            'Assign as Today\'s Work',
                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF322A86)),
                          ),
                        ],
                      ),
                    ),
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
    final capacities = _capacities;
    final totalLogged = capacities.fold<double>(0.0, (sum, c) => sum + c.currentHours);
    final totalMax = capacities.fold<double>(0.0, (sum, c) => sum + c.maxHours);
    final targetPercentage = totalMax > 0 ? ((totalLogged / totalMax) * 100).round() : 0;

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
                '$targetPercentage% Target',
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
            'Studio target is ${totalMax.toInt()} weekly hours across the ${designers.length} core creative leads.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          ...capacities.map((item) {
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
                            color: const Color(0xFF3730A3),
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
    final cadenceData = _cadenceData;

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
              children: cadenceData.map((item) {
                const double maxVal = 40.0;
                final double heightFactor = ((item.hours ?? 0) / maxVal).clamp(0.0, 1.0);

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

  // Card 3: Next Scheduled Drop / Fast Dispatch
  Widget _buildNextScheduledDropCard() {
    final uncompletedPriorityTasks = _tasks.where((t) => t.isPriority && t.status != TaskStatus.completed).toList();

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
              // Text(
              //   'Keyboard: [N]',
              //   style: GoogleFonts.jetBrainsMono(
              //     fontSize: 10.5,
              //     fontWeight: FontWeight.w600,
              //     color: const Color(0xFF2563EB),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Next Scheduled Drop',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (uncompletedPriorityTasks.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Text(
                    '${uncompletedPriorityTasks.length} PRIORITY',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            uncompletedPriorityTasks.isNotEmpty
                ? 'Active high-priority deliverables pending completion.'
                : 'No pending priority deliverables for today.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          if (uncompletedPriorityTasks.isNotEmpty)
            ...uncompletedPriorityTasks.map((task) {
              return InkWell(
                onTap: () => _openUpdateStatusDialog(task),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE4E6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFE11D48)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    task.workName,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${task.designerName} • ${task.timeWindow}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.typeTag.isNotEmpty ? task.typeTag : 'PDF / SVG',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF312E81),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No pending priority drops scheduled.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
