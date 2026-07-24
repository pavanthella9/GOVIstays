import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/finance_service.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: ValueListenableBuilder<int>(
        valueListenable: BookingService.changeNotifier,
        builder: (context, _, __) {
          final summary = FinanceService.allTime;
          final outstanding = FinanceService.outstandingBookings;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _summaryCard('Booking Value', summary.totalBookingValue),
                  _summaryCard('Collected', summary.totalCollected),
                  _summaryCard('Pending Balance', summary.pendingBalance),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Paid: ${summary.paidBookings}   Partial: ${summary.partialBookings}   Pending: ${summary.pendingBookings}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              const Text(
                'Outstanding Bookings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (outstanding.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No pending balances')),
                  ),
                )
              else
                ...outstanding.map(
                  (booking) => _bookingCard(context, booking),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(String title, double amount) {
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookingCard(BuildContext context, Booking booking) {
    return Card(
      child: ListTile(
        title: Text(
          booking.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${booking.rooms.join(', ')}\n'
          'Total: ₹${booking.totalAmount.toStringAsFixed(0)}  '
          'Paid: ₹${booking.advanceAmount.toStringAsFixed(0)}\n'
          'Balance: ₹${booking.balanceAmount.toStringAsFixed(0)}  '
          '(${FinanceService.paymentStatus(booking)})',
        ),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: () => _showCollectDialog(context, booking),
          child: const Text('Collect'),
        ),
      ),
    );
  }

  Future<void> _showCollectDialog(
    BuildContext context,
    Booking booking,
  ) async {
    final controller = TextEditingController(
      text: booking.balanceAmount.toStringAsFixed(0),
    );

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Collect Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${booking.customerName}'),
            Text('Balance: ₹${booking.balanceAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount received',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (amount == null || !context.mounted) return;

    final success = await FinanceService.collectPayment(booking, amount);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Payment updated successfully.'
              : 'Enter an amount greater than 0 and not more than the balance.',
        ),
      ),
    );
  }
}
