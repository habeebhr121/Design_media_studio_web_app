import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shows custom Studio Time Picker that automatically defaults AM / PM:
/// - Hours 8 to 11 default to AM.
/// - Hours 12, 1, 2, 3, 4, 5, 6, 7 default to PM.
/// - The user can still freely tap AM or PM at any time to override.
Future<TimeOfDay?> showStudioTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StudioTimePickerDialog(initialTime: initialTime);
    },
  );
}

enum _TimePickerViewMode { hour, minute }

class StudioTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const StudioTimePickerDialog({
    super.key,
    required this.initialTime,
  });

  @override
  State<StudioTimePickerDialog> createState() => _StudioTimePickerDialogState();
}

class _StudioTimePickerDialogState extends State<StudioTimePickerDialog> {
  late int _selectedHour; // 1 to 12
  late int _selectedMinute; // 0 to 59
  late DayPeriod _selectedPeriod; // am or pm
  _TimePickerViewMode _viewMode = _TimePickerViewMode.hour;
  bool _useTextInput = false;

  late TextEditingController _hourTextController;
  late TextEditingController _minuteTextController;

  @override
  void initState() {
    super.initState();
    final hourOfPeriod = widget.initialTime.hourOfPeriod == 0 ? 12 : widget.initialTime.hourOfPeriod;
    _selectedHour = hourOfPeriod;
    _selectedMinute = widget.initialTime.minute;
    _selectedPeriod = widget.initialTime.period;

    _hourTextController = TextEditingController(text: _selectedHour.toString().padLeft(2, '0'));
    _minuteTextController = TextEditingController(text: _selectedMinute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourTextController.dispose();
    _minuteTextController.dispose();
    super.dispose();
  }

  void _onHourSelected(int hour, {bool autoAdvance = true}) {
    setState(() {
      _selectedHour = hour;
      // Auto default AM / PM rule:
      // 8, 9, 10, 11 -> AM
      // 12, 1, 2, 3, 4, 5, 6, 7 -> PM
      if (hour >= 8 && hour <= 11) {
        _selectedPeriod = DayPeriod.am;
      } else {
        _selectedPeriod = DayPeriod.pm;
      }
      _hourTextController.text = _selectedHour.toString().padLeft(2, '0');
      if (autoAdvance) {
        _viewMode = _TimePickerViewMode.minute;
      }
    });
  }

  void _onMinuteSelected(int minute) {
    setState(() {
      _selectedMinute = minute;
      _minuteTextController.text = _selectedMinute.toString().padLeft(2, '0');
    });
  }

  void _submit() {
    if (_useTextInput) {
      final parsedH = int.tryParse(_hourTextController.text) ?? _selectedHour;
      final parsedM = int.tryParse(_minuteTextController.text) ?? _selectedMinute;
      int clampedH = parsedH.clamp(1, 12);
      int clampedM = parsedM.clamp(0, 59);
      _selectedHour = clampedH;
      _selectedMinute = clampedM;
    }

    int final24Hour;
    if (_selectedPeriod == DayPeriod.am) {
      final24Hour = _selectedHour == 12 ? 0 : _selectedHour;
    } else {
      final24Hour = _selectedHour == 12 ? 12 : _selectedHour + 12;
    }

    Navigator.of(context).pop(TimeOfDay(hour: final24Hour, minute: _selectedMinute));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF2E2C7A);
    final activeBoxColor = const Color(0xFFE8EAFF);
    final inactiveBoxColor = const Color(0xFFF1F3F9);
    final activeTextColor = const Color(0xFF2E2C7A);
    final inactiveTextColor = const Color(0xFF64748B);

    return Dialog(
      backgroundColor: const Color(0xFFF6F6FB),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select time',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 420;
                  final leftPanel = _buildLeftPanel(
                    activeBoxColor: activeBoxColor,
                    inactiveBoxColor: inactiveBoxColor,
                    activeTextColor: activeTextColor,
                    inactiveTextColor: inactiveTextColor,
                    primaryColor: primaryColor,
                  );

                  final rightPanel = _useTextInput
                      ? _buildTextInputs()
                      : _buildDial(primaryColor: primaryColor);

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 170, child: leftPanel),
                        const SizedBox(width: 24),
                        Expanded(child: Center(child: rightPanel)),
                      ],
                    );
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        leftPanel,
                        const SizedBox(height: 20),
                        Center(child: rightPanel),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _useTextInput ? Icons.access_time : Icons.keyboard_outlined,
                      color: const Color(0xFF334155),
                      size: 22,
                    ),
                    tooltip: _useTextInput ? 'Switch to dial picker' : 'Switch to text input',
                    onPressed: () {
                      setState(() {
                        _useTextInput = !_useTextInput;
                      });
                    },
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _submit,
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel({
    required Color activeBoxColor,
    required Color inactiveBoxColor,
    required Color activeTextColor,
    required Color inactiveTextColor,
    required Color primaryColor,
  }) {
    final hourStr = _selectedHour.toString().padLeft(2, '0');
    final minuteStr = _selectedMinute.toString().padLeft(2, '0');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hour Tile
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _viewMode = _TimePickerViewMode.hour;
                  });
                },
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: _viewMode == _TimePickerViewMode.hour && !_useTextInput
                        ? activeBoxColor
                        : inactiveBoxColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _viewMode == _TimePickerViewMode.hour && !_useTextInput
                          ? primaryColor.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hourStr,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: _viewMode == _TimePickerViewMode.hour && !_useTextInput
                          ? activeTextColor
                          : inactiveTextColor,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            // Minute Tile
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _viewMode = _TimePickerViewMode.minute;
                  });
                },
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: _viewMode == _TimePickerViewMode.minute && !_useTextInput
                        ? activeBoxColor
                        : inactiveBoxColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _viewMode == _TimePickerViewMode.minute && !_useTextInput
                          ? primaryColor.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    minuteStr,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: _viewMode == _TimePickerViewMode.minute && !_useTextInput
                          ? activeTextColor
                          : inactiveTextColor,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // AM / PM Segmented Control
        Container(
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                  onTap: () {
                    setState(() {
                      _selectedPeriod = DayPeriod.am;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedPeriod == DayPeriod.am
                          ? const Color(0xFFFDE8E8) // Pink/soft peach highlight like in user's image
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'AM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _selectedPeriod == DayPeriod.am
                            ? const Color(0xFF4A154B)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1.2, color: const Color(0xFFCBD5E1)),
              Expanded(
                child: InkWell(
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                  onTap: () {
                    setState(() {
                      _selectedPeriod = DayPeriod.pm;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedPeriod == DayPeriod.pm
                          ? const Color(0xFFFDE8E8)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'PM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _selectedPeriod == DayPeriod.pm
                            ? const Color(0xFF4A154B)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputs() {
    return Container(
      width: 256,
      height: 256,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Enter time manually',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 68,
                child: TextField(
                  controller: _hourTextController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 2,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'Hour',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final h = int.tryParse(val);
                    if (h != null && h >= 1 && h <= 12) {
                      _onHourSelected(h, autoAdvance: false);
                    }
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 68,
                child: TextField(
                  controller: _minuteTextController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 2,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'Minute',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final m = int.tryParse(val);
                    if (m != null && m >= 0 && m <= 59) {
                      _onMinuteSelected(m);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDial({required Color primaryColor}) {
    const double dialSize = 250;
    final isHour = _viewMode == _TimePickerViewMode.hour;

    return SizedBox(
      width: dialSize,
      height: dialSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular dial background
          Container(
            width: dialSize,
            height: dialSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFECEEF4),
            ),
          ),
          // Pointer hand and selected circle
          CustomPaint(
            size: const Size(dialSize, dialSize),
            painter: _DialHandPainter(
              value: isHour ? _selectedHour : _selectedMinute,
              isHour: isHour,
              primaryColor: primaryColor,
            ),
          ),
          // Numbers positioned in circle
          ..._buildDialNumbers(dialSize: dialSize, isHour: isHour, primaryColor: primaryColor),
          // Dial gesture detector
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (details) => _handleDialTouch(details.localPosition, dialSize),
              onPanUpdate: (details) => _handleDialTouch(details.localPosition, dialSize),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDialNumbers({
    required double dialSize,
    required bool isHour,
    required Color primaryColor,
  }) {
    final List<Widget> widgets = [];
    final center = dialSize / 2;
    final radius = dialSize / 2 - 30; // Radius where numbers sit

    if (isHour) {
      for (int i = 1; i <= 12; i++) {
        // Angle in radians: 12 is at top (-pi/2)
        final angle = (i * 30 - 90) * (math.pi / 180);
        final x = center + radius * math.cos(angle);
        final y = center + radius * math.sin(angle);
        final isSelected = _selectedHour == i;

        widgets.add(
          Positioned(
            left: x - 18,
            top: y - 18,
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                '$i',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      // Minute mode: show multiples of 5 (00, 05, 10, ... 55)
      for (int i = 0; i < 60; i += 5) {
        final angle = (i * 6 - 90) * (math.pi / 180);
        final x = center + radius * math.cos(angle);
        final y = center + radius * math.sin(angle);
        final isSelected = _selectedMinute == i;

        widgets.add(
          Positioned(
            left: x - 18,
            top: y - 18,
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                i.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  void _handleDialTouch(Offset localPosition, double dialSize) {
    final center = Offset(dialSize / 2, dialSize / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // Angle in degrees from 0 to 360, where 12 o'clock is 0 / 360
    double angleDeg = (math.atan2(dy, dx) * 180 / math.pi) + 90;
    if (angleDeg < 0) {
      angleDeg += 360;
    }

    if (_viewMode == _TimePickerViewMode.hour) {
      // 12 hours -> each hour is 30 deg
      // 12 is at 0 deg, 1 is at 30 deg, etc.
      int hour = ((angleDeg + 15) ~/ 30) % 12;
      if (hour == 0) hour = 12;
      _onHourSelected(hour, autoAdvance: false);
    } else {
      // 60 minutes -> each minute is 6 deg
      int minute = ((angleDeg + 3) ~/ 6) % 60;
      _onMinuteSelected(minute);
    }
  }
}

class _DialHandPainter extends CustomPainter {
  final int value;
  final bool isHour;
  final Color primaryColor;

  _DialHandPainter({
    required this.value,
    required this.isHour,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;

    double angleDeg;
    if (isHour) {
      angleDeg = (value % 12) * 30.0 - 90.0;
    } else {
      angleDeg = (value % 60) * 6.0 - 90.0;
    }

    final angleRad = angleDeg * (math.pi / 180.0);
    final handEnd = Offset(
      center.dx + radius * math.cos(angleRad),
      center.dy + radius * math.sin(angleRad),
    );

    // Center pivot dot
    final centerDotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);

    // Hand line
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, handEnd, linePaint);

    // Selected circle indicator at the end of hand
    final selectorPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(handEnd, 18, selectorPaint);
  }

  @override
  bool shouldRepaint(covariant _DialHandPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.isHour != isHour ||
        oldDelegate.primaryColor != primaryColor;
  }
}
