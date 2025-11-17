import 'package:flutter/material.dart';

/// Widget لاختيار النطاق الزمني
class DateRangePickerWidget extends StatefulWidget {
  const DateRangePickerWidget({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
    this.label = 'النطاق الزمني',
  });

  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final String label;

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.date_range, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // أزرار سريعة
        Wrap(
          spacing: 8,
          children: <Widget>[
            _buildQuickButton('اليوم', () => _setQuickRange(0)),
            _buildQuickButton('أمس', () => _setQuickRange(1)),
            _buildQuickButton('آخر 7 أيام', () => _setQuickRange(7)),
            _buildQuickButton('آخر 30 يوم', () => _setQuickRange(30)),
            _buildQuickButton('آخر 90 يوم', () => _setQuickRange(90)),
          ],
        ),
      ],
    );

  Widget _buildQuickButton(String label, VoidCallback onPressed) => OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      locale: const Locale('ar', 'SA'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      widget.onDateRangeChanged(picked);
    }
  }

  void _setQuickRange(int days) {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(days: days));
    final DateTime end = days == 0 ? now : now.subtract(const Duration(days: 1));

    setState(() {
      _startDate = start;
      _endDate = end;
    });

    widget.onDateRangeChanged(DateTimeRange(start: start, end: end));
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

/// Widget لاختيار التاريخ الواحد
class DatePickerWidget extends StatefulWidget {
  const DatePickerWidget({
    super.key,
    required this.date,
    required this.onDateChanged,
    this.label = 'التاريخ',
    this.firstDate,
    this.lastDate,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
  }

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.firstDate ?? DateTime(2020),
      lastDate:
          widget.lastDate ?? DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SA'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateChanged(picked);
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
