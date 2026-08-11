import 'package:flutter/material.dart';

import '../services/booking_service.dart';
import 'booking_details_screen.dart';

class TodayCheckinsScreen extends StatelessWidget {
  const TodayCheckinsScreen({super.key});

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$day-$month-${date.year} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Check-ins"),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: BookingService.changeNotifier,
        builder: (context, _, __) {
          final bookings = BookingService.getTodayCheckIns();
          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                "No Check-ins Today",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                elevation: 3,
                child: ListTile(
                  leading: const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.hotel),
                  ),
                  title: Text(
                    booking.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Rooms : ${booking.rooms.join(', ')}\n"
                      "Guests : ${booking.guests}\n"
                      "Phone : ${booking.phoneNumber}\n"
                      "Check-in : ${_formatDateTime(booking.checkIn)}",
                    ),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailsScreen(booking: booking),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
