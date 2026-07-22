import 'package:flutter/material.dart';
import '../models/booking.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Booking booking;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            Text(
              booking.customerName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text("Booking ID : ${booking.bookingId}"),
            Text("Phone : ${booking.phoneNumber}"),
            Text("Address : ${booking.address}"),
            Text("Guests : ${booking.guests}"),

            const SizedBox(height: 15),

            Text("Rooms : ${booking.rooms.join(", ")}"),

            const SizedBox(height: 15),

            Text("Check In : ${booking.checkIn}"),
            Text("Check Out : ${booking.checkOut}"),

            const SizedBox(height: 15),

            Text("Total : ₹${booking.totalAmount}"),
            Text("Advance : ₹${booking.advanceAmount}"),
            Text("Balance : ₹${booking.balanceAmount}"),

            const SizedBox(height: 20),

            Text("Notes"),

            Text(booking.notes),

          ],
        ),
      ),
    );
  }
}