import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';
import 'booking_details_screen.dart';

class BookingCalendarScreen extends StatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  State<BookingCalendarScreen> createState() =>
      _BookingCalendarScreenState();
}

class _BookingCalendarScreenState
    extends State<BookingCalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${_two(value.minute)} $period';
  }

  String _formatDate(DateTime value) =>
      '${_two(value.day)}-${_two(value.month)}-${value.year}';

  String _roomLabel(String room) {
    switch (room) {
      case 'Master Room 1':
        return 'Master Room 1 (MR1)';
      case 'Master Room 2':
        return 'Master Room 2 (MR2)';
      case 'Queen Room 1':
        return 'Queen Room 1 (QR1)';
      case 'Queen Room 2':
        return 'Queen Room 2 (QR2)';
      case 'Penthouse':
        return 'Penthouse (PH)';
      default:
        return room;
    }
  }

  List<Booking> _eventsForDay(DateTime day) =>
      BookingService.getBookingsForDate(day);

  // Green: no room booked; orange: some booked time; red: all rooms
  // booked for the entire day. Uses scheduled times, not actual movements.
  Color _availabilityColor(DateTime day) {
    var anyBooked = false;
    var allRoomsBookedAllDay = true;
    for (final room in BookingService.allRooms) {
      final segments = BookingService.getRoomAvailabilityForDate(room, day);
      if (segments.any((segment) => segment.isBooked)) {
        anyBooked = true;
      }
      if (segments.any((segment) => !segment.isBooked)) {
        allRoomsBookedAllDay = false;
      }
    }
    if (!anyBooked) return Colors.green;
    return allRoomsBookedAllDay ? Colors.red : Colors.orange;
  }

  Widget _calendarDay(DateTime day, {bool selected = false, bool today = false}) {
    final color = _availabilityColor(day);
    return Center(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 1 : 0.20),
          shape: BoxShape.circle,
          border: today ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: selected || today ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Calendar'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: BookingService.changeNotifier,
        builder: (context, _, __) {
          final selectedBookings =
              BookingService.getBookingsForDate(_selectedDay);

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<Booking>(
                    firstDay: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDay: DateTime.now().add(
                      const Duration(days: 730),
                    ),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) =>
                        isSameDay(day, _selectedDay),
                    eventLoader: _eventsForDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: const CalendarStyle(
                      markersMaxCount: 0,
                      outsideDaysVisible: false,
                    ),
                    calendarBuilders: CalendarBuilders<Booking>(
                      defaultBuilder: (context, day, focusedDay) => _calendarDay(day),
                      todayBuilder: (context, day, focusedDay) =>
                          _calendarDay(day, today: true),
                      selectedBuilder: (context, day, focusedDay) =>
                          _calendarDay(day, selected: true, today: isSameDay(day, DateTime.now())),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  _legendItem(Colors.green, 'All available'),
                  _legendItem(Colors.orange, 'Partially booked'),
                  _legendItem(Colors.red, 'Fully booked all day'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Availability for ${_formatDate(_selectedDay)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                selectedBookings.isEmpty
                    ? 'No bookings on this date.'
                    : '${selectedBookings.length} booking(s) touch this date. '
                        'Times below show partial-day availability.',
              ),
              const SizedBox(height: 12),
              ...BookingService.allRooms.map(
                (room) => _roomTimelineCard(room),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _roomTimelineCard(String room) {
    final segments = BookingService.getRoomAvailabilityForDate(
      room,
      _selectedDay,
    );

    final allDayAvailable =
        segments.length == 1 && !segments.first.isBooked;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: !allDayAvailable,
        leading: Icon(
          allDayAvailable
              ? Icons.check_circle_outline
              : Icons.schedule,
        ),
        title: Text(
          _roomLabel(room),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          allDayAvailable
              ? 'Available all day'
              : 'Tap to view booked and available time slots',
        ),
        children: [
          if (allDayAvailable)
            const ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Available all day'),
            )
          else
            ...segments.map(_segmentTile),
        ],
      ),
    );
  }

  Widget _segmentTile(RoomAvailabilitySegment segment) {
    final endIsMidnightNextDay =
        segment.end.hour == 0 &&
        segment.end.minute == 0 &&
        !isSameDay(segment.start, segment.end);

    final range =
        '${_formatTime(segment.start)} – '
        '${endIsMidnightNextDay ? '12:00 Midnight' : _formatTime(segment.end)}';

    if (!segment.isBooked) {
      return ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: const Text(
          'AVAILABLE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(range),
      );
    }

    final booking = segment.booking!;
    return ListTile(
      leading: const Icon(Icons.event_busy),
      title: Text(
        'BOOKED • ${booking.customerName}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '$range\n'
        'Booking ID: ${booking.bookingId}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailsScreen(
              booking: booking,
            ),
          ),
        );
      },
    );
  }
}
