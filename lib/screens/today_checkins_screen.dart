import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'booking_details_screen.dart';

class TodayCheckinsScreen extends StatelessWidget {
  const TodayCheckinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    final List<Booking> todayBookings =
        BookingService.bookings.where((booking) {
      return booking.checkIn.year == today.year &&
          booking.checkIn.month == today.month &&
          booking.checkIn.day == today.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Check-ins"),
        centerTitle: true,
      ),
      body: todayBookings.isEmpty
          ? const Center(
              child: Text(
                "No Check-ins Today",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: todayBookings.length,
              itemBuilder: (context, index) {
                final booking = todayBookings[index];

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
                        "Check-in : ${booking.checkIn.day}/${booking.checkIn.month}/${booking.checkIn.year}",
                      ),
                    ),

                    isThreeLine: true,

                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                    ),

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
                  ),
                );
              },
            ),
    );
  }
}