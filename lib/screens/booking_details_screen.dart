import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'edit_booking_screen.dart';

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
            const SizedBox(height: 30),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.edit),
    label: const Text("Edit Booking"),
    onPressed: () async {

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditBookingScreen(
        booking: booking,
      ),
    ),
  );

  if (result == true) {
    Navigator.pop(context, true);
  }


    },
  ),
),

const SizedBox(height: 15),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    icon: const Icon(Icons.delete),
    label: const Text("Delete Booking"),
    onPressed: () async {

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Delete Booking"),
            content: const Text(
              "Are you sure you want to delete this booking?",
            ),
            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text("Delete"),
              ),

            ],
          );
        },
      );

      if (confirm == true) {

        final deleted = await BookingService.deleteBooking(booking);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: deleted ? Colors.red : Colors.orange,
            content: Text(
              deleted
                  ? "Booking Deleted"
                  : "Delete failed. Please check the internet and try again.",
            ),
          ),
        );

        if (deleted) {
          Navigator.pop(context, true);
        }
      }
    },
  ),
),

          ],
        ),
      ),
    );
  }
}