import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../services/customer_service.dart';
import 'booking_details_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _addressController = TextEditingController(text: widget.customer.address);
    _notesController = TextEditingController(text: widget.customer.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await CustomerService.updateCustomer(Customer(
        customerId: widget.customer.customerId,
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        notes: _notesController.text,
        totalBookings: widget.customer.totalBookings,
        totalSpent: widget.customer.totalSpent,
        lastVisit: widget.customer.lastVisit,
        createdAt: widget.customer.createdAt,
      ));
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = CustomerService.bookingsForPhone(widget.customer.phone);
    final paid = bookings.fold<double>(0, (sum, item) => sum + item.advanceAmount);
    final outstanding = bookings.fold<double>(0, (sum, item) => sum + item.balanceAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            tooltip: _editing ? 'Cancel editing' : 'Edit customer',
            onPressed: () => setState(() => _editing = !_editing),
            icon: Icon(_editing ? Icons.close : Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            enabled: _editing,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _phoneController,
            enabled: false,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          TextField(
            controller: _addressController,
            enabled: _editing,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          TextField(
            controller: _notesController,
            enabled: _editing,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          if (_editing) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ],
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 28,
                runSpacing: 16,
                children: [
                  _metric('Bookings', '${bookings.length}'),
                  _metric('Paid', '₹${paid.toStringAsFixed(0)}'),
                  _metric('Balance', '₹${outstanding.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Booking History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (bookings.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No bookings found for this customer.'),
              ),
            )
          else
            ...bookings.map((booking) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.hotel)),
                    title: Text(booking.rooms.join(', ')),
                    subtitle: Text(
                      '${_date(booking.checkIn)} to ${_date(booking.checkOut)}\n'
                      'Total ₹${booking.totalAmount.toStringAsFixed(0)} · '
                      'Balance ₹${booking.balanceAmount.toStringAsFixed(0)}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailsScreen(booking: booking),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}
