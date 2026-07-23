import 'package:flutter/material.dart';

import '../services/booking_service.dart';
import 'booking_details_screen.dart';

class FutureBookingsScreen extends StatefulWidget {
  const FutureBookingsScreen({super.key});

  @override
  State<FutureBookingsScreen> createState() =>
      _FutureBookingsScreenState();
}

class _FutureBookingsScreenState
    extends State<FutureBookingsScreen> {

  

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    final bookings = BookingService.bookings.where((booking) {
      final checkIn = DateTime(
        booking.checkIn.year,
        booking.checkIn.month,
        booking.checkIn.day,
      );

      final current = DateTime(
        today.year,
        today.month,
        today.day,
      );

      return checkIn.isAfter(current);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Future Bookings"),
      ),
      body: bookings.isEmpty
          ? const Center(
              child: Text(
                "No Future Bookings",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(booking.customerName),
                    subtitle: Text(
                      "Room: ${booking.rooms.join(',')}\n"
                      "Check-in: ${booking.checkIn.toLocal().toString().split(' ')[0]}",
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BookingDetailsScreen(
        booking: booking,
      ),
    ),
  );

  if (result == true) {
    setState(() {});
  }

},
                  ),
                );
              },
            ),
    );
  }
}