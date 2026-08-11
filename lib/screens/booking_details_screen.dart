import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/customer_service.dart';
import '../services/user_service.dart';
import '../services/whatsapp_service.dart';
import 'customer_details_screen.dart';
import 'edit_booking_screen.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Booking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '$hour:$minute $period';
  }

  String _money(double value) => value.toStringAsFixed(
        value == value.roundToDouble() ? 0 : 2,
      );

  @override
  Widget build(BuildContext context) {
    final isAdmin = UserService.isAdmin;
    final isCompleted = !booking.checkOut.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            booking.customerName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _row('Booking ID', booking.bookingId),
          _row('Booking Date', _formatDateTime(booking.bookingCreatedAt)),
          _row('Phone', booking.phoneNumber),
          _row('Address', booking.address),
          _row('Guests', booking.guests.toString()),
          _row('Rooms', booking.rooms.join(', ')),
          _row('Check-in', _formatDateTime(booking.checkIn)),
          _row('Check-out', _formatDateTime(booking.checkOut)),
          if (isAdmin) ...[
            const Divider(height: 28),
            _row('Total', '₹${_money(booking.totalAmount)}'),
            _row('Advance', '₹${_money(booking.advanceAmount)}'),
            _row('Balance', '₹${_money(booking.balanceAmount)}'),
          ] else if (UserService.canViewBalance) ...[
            const Divider(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Balance to Collect',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '₹${_money(booking.balanceAmount)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Divider(height: 28),
          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(booking.notes.isEmpty ? 'No notes' : booking.notes),
          const SizedBox(height: 24),
          if (isAdmin) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('View Customer Profile'),
                onPressed: () async {
                  try {
                    await CustomerService.upsertFromBooking(booking);
                    final customer = await CustomerService.getByPhone(
                      booking.phoneNumber,
                    );
                    if (!context.mounted || customer == null) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailsScreen(customer: customer),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to open customer: $error')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (isAdmin && isCompleted) ...[
            const SizedBox(height: 14),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star_rate_rounded, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guest has checked out',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Send a WhatsApp message requesting a Google review.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.reviews_outlined),
                      label: const Text('Request Google Review'),
                      onPressed: () async {
                        try {
                          await WhatsAppService.openGoogleReviewRequest(
                            booking,
                          );
                        } on WhatsAppException catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Send WhatsApp Confirmation'),
              onPressed: () async {
                try {
                  await WhatsAppService.openWhatsApp(booking);
                } on WhatsAppException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy Booking Details'),
              onPressed: () async {
                await WhatsAppService.copyBookingDetails(booking);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking details copied.')),
                );
              },
            ),
          ),
          if (UserService.canManageBookings) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Booking'),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditBookingScreen(booking: booking),
                    ),
                  );
                  if (result == true && context.mounted) {
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
                label: const Text('Delete Booking'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete Booking?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  final deleted = await BookingService.deleteBooking(booking);
                  if (!context.mounted) return;
                  if (deleted) Navigator.pop(context, true);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
