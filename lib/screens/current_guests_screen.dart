import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import 'booking_details_screen.dart';

class CurrentGuestsScreen extends StatelessWidget {
  const CurrentGuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

final bookings = BookingService.bookings.where((booking) {
  final checkIn = DateTime(
    booking.checkIn.year,
    booking.checkIn.month,
    booking.checkIn.day,
  );

  final checkOut = DateTime(
    booking.checkOut.year,
    booking.checkOut.month,
    booking.checkOut.day,
  );

  final current = DateTime(today.year, today.month, today.day);

  return !current.isBefore(checkIn) &&
      !current.isAfter(checkOut);
}).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Current Guests"),
      ),
      body: bookings.isEmpty
          ? const Center(
              child: Text(
                "No Current Guests",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(booking.customerName),
                    subtitle: Text(
                      "${booking.phoneNumber}\nGuests: ${booking.guests}",
                    ),
                    trailing: Text("₹${booking.balanceAmount}"),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingDetailsScreen(booking: booking),
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