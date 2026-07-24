import 'package:flutter/material.dart';

import '../services/booking_service.dart';
import '../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'This Month';
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: ValueListenableBuilder<int>(
        valueListenable: BookingService.changeNotifier,
        builder: (context, _, __) {
          final range = _selectedRange();
          final summary = ReportService.buildSummary(range.$1, range.$2);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _period,
                decoration: const InputDecoration(
                  labelText: 'Report period',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  'Today',
                  'This Week',
                  'This Month',
                  'All Time',
                  'Custom Range',
                ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  if (value == 'Custom Range') {
                    await _chooseCustomRange();
                    if (_customStart == null || _customEnd == null) return;
                  }
                  setState(() => _period = value);
                },
              ),
              const SizedBox(height: 12),
              Text(
                '${_formatDate(summary.start)} – ${_formatDate(summary.end)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _moneyCard('Booking Value', summary.bookingValue, Icons.currency_rupee),
              _moneyCard('Advance Collected', summary.advanceCollected, Icons.payments),
              _moneyCard('Pending Balance', summary.pendingBalance, Icons.account_balance_wallet),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  _metricCard('Bookings', '${summary.bookings}', Icons.book_online),
                  _metricCard('Guests', '${summary.guests}', Icons.people),
                  _metricCard('Room Nights', '${summary.roomNights}', Icons.nights_stay),
                  _metricCard(
                    'Occupancy',
                    '${summary.occupancyPercentage.toStringAsFixed(1)}%',
                    Icons.hotel,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Most Booked Room'),
                  subtitle: Text(summary.mostBookedRoom),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Values are calculated from bookings whose check-in date falls within the selected period.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  (DateTime, DateTime) _selectedRange() {
    final now = DateTime.now();
    switch (_period) {
      case 'Today':
        return (now, now);
      case 'This Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (start, now);
      case 'All Time':
        if (BookingService.bookings.isEmpty) return (now, now);
        final dates = BookingService.bookings.map((booking) => booking.checkIn).toList()..sort();
        return (dates.first, now.isAfter(dates.last) ? now : dates.last);
      case 'Custom Range':
        return (_customStart ?? now, _customEnd ?? now);
      case 'This Month':
      default:
        return (DateTime(now.year, now.month, 1), now);
    }
  }

  Future<void> _chooseCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(
        start: _customStart ?? DateTime(now.year, now.month, 1),
        end: _customEnd ?? now,
      ),
    );
    if (picked != null) {
      _customStart = picked.start;
      _customEnd = picked.end;
    }
  }

  Widget _moneyCard(String title, double value, IconData icon) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        trailing: Text(
          '₹${value.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
