import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class DateRangeValue {
  const DateRangeValue({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class DateTimeService extends ChangeNotifier {
  DateTimeService() {
    _scheduleMidnightRefresh();
  }

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _shortDateFormat = DateFormat('EEE, dd MMM');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _longDateFormat = DateFormat('EEEE, d MMMM yyyy');

  Timer? _midnightTimer;

  DateTime get currentDateTime => DateTime.now();

  DateTime get currentTime => currentDateTime;

  DateTime get currentDate {
    final value = currentDateTime;
    return DateTime(value.year, value.month, value.day);
  }

  DateTime get today => currentDate;

  DateTime get yesterday => today.subtract(const Duration(days: 1));

  DateTime get startOfWeek {
    final daysFromMonday = today.weekday - DateTime.monday;
    return today.subtract(Duration(days: daysFromMonday));
  }

  DateTime get endOfWeek => startOfWeek.add(const Duration(days: 6));

  DateTime get startOfMonth => DateTime(today.year, today.month);

  DateTime get endOfMonth => DateTime(today.year, today.month + 1, 0);

  DateRangeValue get last7Days => DateRangeValue(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      );

  DateRangeValue get last30Days => DateRangeValue(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      );

  String formatDate(DateTime value) => _dateFormat.format(value.toLocal());

  String formatTime(DateTime value) => _timeFormat.format(value.toLocal());

  String formatShortDate(DateTime value) =>
      _shortDateFormat.format(value.toLocal());

  String formatMonthYear(DateTime value) =>
      _monthYearFormat.format(value.toLocal());

  String formatLongDate(DateTime value) =>
      _longDateFormat.format(value.toLocal());

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final nextMidnight = DateTime(today.year, today.month, today.day + 1);
    final delay = nextMidnight.difference(currentDateTime);
    _midnightTimer = Timer(delay, () {
      notifyListeners();
      _scheduleMidnightRefresh();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}