import 'package:flutter/material.dart';
import '../widgets/side_menu.dart';
import '../../services/db_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _weekOffset = 0;
  bool _isLoading = false;
  String? _error;
  Map<String, List<Map<String, dynamic>>> _schedule = {};
  final List<String> _days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await DBService.getCurrentUser();
      if (user == null || user['group_id'] == null) {
        throw Exception('Группа не найдена');
      }

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final adjustedStart = startOfWeek.add(Duration(days: _weekOffset * 7));
      final adjustedEnd = adjustedStart.add(const Duration(days: 6));

      final lessons = await DBService.getSchedule(
        user['group_id'],
        adjustedStart,
        adjustedEnd,
      );

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final day in _days) grouped[day] = [];

      for (final lesson in lessons) {
        final date = DateTime.parse(lesson['lesson_date']);
        final dayName = _days[date.weekday - 1];
        
        grouped[dayName]?.add({
          'subject': lesson['subject'],
          'time': '${_formatTime(lesson['start_time'])} - ${_formatTime(lesson['end_time'])}',
          'teacher': lesson['teacher'],
          'room': lesson['room'],
          'start_time': lesson['start_time'],
        });
      }

      for (final day in grouped.keys) {
        grouped[day]!.sort((a, b) => a['start_time'].compareTo(b['start_time']));
      }

      if (mounted) {
        setState(() {
          _schedule = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить расписание';
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }

  String _getCurrentWeekText() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final adjustedStart = startOfWeek.add(Duration(days: _weekOffset * 7));
    final adjustedEnd = adjustedStart.add(const Duration(days: 6));

    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 
                    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];

    String formatDate(DateTime date) => '${date.day} ${months[date.month - 1]}';
    return '${formatDate(adjustedStart)} – ${formatDate(adjustedEnd)}';
  }

  void _previousWeek() {
    setState(() => _weekOffset--);
    _loadSchedule();
  }

  void _nextWeek() {
    setState(() => _weekOffset++);
    _loadSchedule();
  }

  void _currentWeek() {
    setState(() => _weekOffset = 0);
    _loadSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE53935),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Text(
                      'Расписание',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        GestureDetector(onTap: _previousWeek, child: _navButton(Icons.chevron_left)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _currentWeek,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getCurrentWeekText(),
                                      style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  if (_weekOffset != 0) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _currentWeek,
                                      child: const Icon(Icons.refresh, size: 16, color: Color(0xFFE53935)),
                                    )
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(onTap: _nextWeek, child: _navButton(Icons.chevron_right)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                        : _error != null
                            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _days.length,
                                itemBuilder: (context, index) => _buildDaySection(_days[index]),
                              ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(margin: const EdgeInsets.only(right: 12), child: const SideMenu(activeIndex: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: const Color(0xFFE53935)),
    );
  }

  Widget _buildDaySection(String day) {
    final lessons = _schedule[day] ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
          const SizedBox(height: 12),
          if (lessons.isEmpty)
            const Text('Нет занятий', style: TextStyle(color: Colors.grey, fontSize: 14))
          else
            ...lessons.map((lesson) => _buildLessonItem(lesson)).toList(),
        ],
      ),
    );
  }

  Widget _buildLessonItem(Map<String, dynamic> lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lesson['subject'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(lesson['time'], style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(child: Text(lesson['teacher'], style: TextStyle(color: Colors.grey[700], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.meeting_room, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('Ауд. ${lesson['room']}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}