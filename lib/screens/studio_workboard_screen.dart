import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

class StudioTask {
  final String id;
  final String date;
  final String designerName;
  final String designerRole;
  final String avatarUrl;
  final String workName;
  final String clientName;
  final String typeTag;
  final String workBrief;
  final TaskStatus status;
  final String timeWindow;
  final String timeLogged;

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
  });
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

  const StudioWorkboardScreen({
    super.key,
    this.onNavigateToHoursReport,
  });

  @override
  State<StudioWorkboardScreen> createState() => _StudioWorkboardScreenState();
}

class _StudioWorkboardScreenState extends State<StudioWorkboardScreen> {
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

  @override
  void dispose() {
    _timer.cancel();
    _searchController.dispose();
    _tableSearchController.dispose();
    super.dispose();
  }

  void _initData() {
    _tasks = [
      StudioTask(
        id: '1',
        date: 'Oct 24, 2024',
        designerName: 'Elena Rostova',
        designerRole: 'Lead Visual',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
        workName: 'Brand Identity Overhaul',
        clientName: 'Veloce Mobility',
        typeTag: 'Logo / System',
        workBrief: 'Redefine typographic...',
        status: TaskStatus.inProgress,
        timeWindow: '09:30 AM - 01:30 PM',
        timeLogged: '4h 00m logged',
      ),
      StudioTask(
        id: '2',
        date: 'Oct 24, 2024',
        designerName: 'Marcus Chen',
        designerRole: 'Graphic Design',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
        workName: 'Summer Music Poster',
        clientName: 'Kyoto Soundfest',
        typeTag: 'Poster',
        workBrief: 'Completed dual-run 3-...',
        status: TaskStatus.completed,
        timeWindow: '08:00 AM - 11:30 AM',
        timeLogged: '3h 30m logged',
      ),
      StudioTask(
        id: '3',
        date: 'Oct 24, 2024',
        designerName: 'Maya Patel',
        designerRole: '3D Motion',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
        workName: 'Product Reel 3D',
        clientName: 'Sona Acoustics',
        typeTag: 'Video / 3D',
        workBrief: 'Constructed 15-second flui...',
        status: TaskStatus.inReview,
        timeWindow: '10:00 AM - 03:00 PM',
        timeLogged: '5h 00m logged',
      ),
      StudioTask(
        id: '4',
        date: 'Oct 24, 2024',
        designerName: 'Liam Vance',
        designerRole: 'Digital Retouch',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
        workName: 'Apparel Lookbook Retouch',
        clientName: 'Studio NORD',
        typeTag: 'Editing / Retouch',
        workBrief: 'Batch balance 24 high-...',
        status: TaskStatus.inProgress,
        timeWindow: '01:00 PM - 05:00 PM',
        timeLogged: '4h 00m logged',
      ),
      StudioTask(
        id: '5',
        date: 'Oct 23, 2024',
        designerName: 'Elena Rostova',
        designerRole: 'Lead Visual',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
        workName: 'Kiosk Touch UI Prototype',
        clientName: 'Museum of Craft',
        typeTag: 'UI / UX',
        workBrief: 'Drafting 4K touchscreen...',
        status: TaskStatus.pending,
        timeWindow: 'Pending Start',
        timeLogged: 'Est: 6h 00m',
      ),
      StudioTask(
        id: '6',
        date: 'Oct 23, 2024',
        designerName: 'Marcus Chen',
        designerRole: 'Graphic Design',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
        workName: 'Editorial Layout Rules',
        clientName: 'Forma Press',
        typeTag: 'Poster / Print',
        workBrief: 'Building modular...',
        status: TaskStatus.inProgress,
        timeWindow: '01:30 PM - 03:30 PM',
        timeLogged: '2h 00m logged',
      ),
    ];

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

  void _openAddNewWorkDialog() {
    final workNameCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'UI / UX');
    final briefCtrl = TextEditingController();
    String selectedDesignerName = 'Elena Rostova';
    TaskStatus selectedStatus = TaskStatus.inProgress;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              child: Container(
                width: 520,
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add New Studio Work',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: workNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Work / Project Title',
                        hintText: 'e.g. Brand Identity Overhaul',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: clientCtrl,
                      decoration: InputDecoration(
                        labelText: 'Client Name',
                        hintText: 'e.g. Veloce Mobility',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedDesignerName,
                            decoration: InputDecoration(
                              labelText: 'Assigned Designer',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Elena Rostova', child: Text('Elena Rostova (Lead)')),
                              DropdownMenuItem(value: 'Marcus Chen', child: Text('Marcus Chen (Graphic)')),
                              DropdownMenuItem(value: 'Maya Patel', child: Text('Maya Patel (3D)')),
                              DropdownMenuItem(value: 'Liam Vance', child: Text('Liam Vance (Retouch)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedDesignerName = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: typeCtrl,
                            decoration: InputDecoration(
                              labelText: 'Type Tag',
                              hintText: 'e.g. Video / 3D',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: briefCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Work Brief & Objectives',
                        hintText: 'Describe short deliverables & scope...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25206A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (workNameCtrl.text.trim().isEmpty) return;
                            String role = 'Designer';
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
                                  date: 'Oct 24, 2024',
                                  designerName: selectedDesignerName,
                                  designerRole: role,
                                  avatarUrl: avatar,
                                  workName: workNameCtrl.text.trim(),
                                  clientName: clientCtrl.text.trim().isEmpty ? 'Direct Studio' : clientCtrl.text.trim(),
                                  typeTag: typeCtrl.text.trim().isEmpty ? 'General' : typeCtrl.text.trim(),
                                  workBrief: briefCtrl.text.trim().isEmpty ? 'Initial milestone started' : briefCtrl.text.trim(),
                                  status: selectedStatus,
                                  timeWindow: '02:00 PM - 06:00 PM',
                                  timeLogged: '0h 00m logged',
                                ),
                              );
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            '+ Create Assignment',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
                final contentWidth = constraints.maxWidth < 1120 ? 1120.0 : (constraints.maxWidth - horizontalPadding * 2);

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
    final c1 = _buildMetricCard(
      icon: Icons.layers_outlined,
      iconBg: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF2563EB),
      label: 'ACTIVE TASKS',
      boldValue: '7',
      subText: 'in progress',
    );
    final c2 = _buildMetricCard(
      icon: Icons.access_time_rounded,
      iconBg: const Color(0xFFEEF2FF),
      iconColor: const Color(0xFF4F46E5),
      label: 'TODAY LOGGED',
      boldValue: '18.5',
      subText: 'hrs',
    );
    final c3 = _buildMetricCard(
      icon: Icons.verified_outlined,
      iconBg: const Color(0xFFECFDF5),
      iconColor: const Color(0xFF059669),
      label: 'COMPLETED TODAY',
      boldValue: '5',
      subText: 'deliverables',
    );
    final c4 = _buildMetricCard(
      icon: Icons.people_alt_outlined,
      iconBg: const Color(0xFFFDF2F8),
      iconColor: const Color(0xFFDB2777),
      label: 'ASSIGNED STAFF',
      boldValue: '4',
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
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DESIGNER:',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: const Color(0xFF8E9BAE),
                ),
              ),
              const SizedBox(width: 10),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'STATUS:',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: const Color(0xFF8E9BAE),
                ),
              ),
              const SizedBox(width: 10),
              _buildFilterChip('All', isSelected: _selectedStatus == 'All', onSelected: () {
                setState(() => _selectedStatus = 'All');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('In Progress', isSelected: _selectedStatus == 'In Progress', onSelected: () {
                setState(() => _selectedStatus = 'In Progress');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('In Review', isSelected: _selectedStatus == 'In Review', onSelected: () {
                setState(() => _selectedStatus = 'In Review');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Pending', isSelected: _selectedStatus == 'Pending', onSelected: () {
                setState(() => _selectedStatus = 'Pending');
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Completed', isSelected: _selectedStatus == 'Completed', onSelected: () {
                setState(() => _selectedStatus = 'Completed');
              }),
            ],
          ),
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
              ],
            ),
          ),
        ],
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
                _buildTableHeaderCell('TYPE', width: 130),
                _buildTableHeaderCell('WORK BRIEF & CONTENT', flex: 3),
                _buildTableHeaderCell('STATUS', width: 130),
                _buildTableHeaderCell('TIME WINDOW / TOTAL', width: 165),
                const SizedBox(width: 32),
              ],
            ),
          ),

          // Table Rows
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    Text(
                      'No studio assignments match the current filter',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
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
                  'Showing ${tasks.length} studio assignments',
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
                Text(
                  task.clientName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2563EB),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // TYPE (Pill)
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

          // STATUS
          SizedBox(
            width: 130,
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

          // TIME WINDOW / TOTAL
          SizedBox(
            width: 165,
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

          // Context 3-dots action menu
          SizedBox(
            width: 32,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (action) {
                  if (action == 'delete') {
                    setState(() {
                      _tasks.removeWhere((t) => t.id == task.id);
                    });
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Task Details'),
                  ),
                  const PopupMenuItem(
                    value: 'clock',
                    child: Text('Start Stopwatch'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Assignment', style: TextStyle(color: Colors.red)),
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
