import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/customer_service.dart';
import '../services/user_service.dart';
import '../services/whatsapp_service.dart';

class AddBookingScreen extends StatefulWidget {
  const AddBookingScreen({super.key});

  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final customerNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final guestsController = TextEditingController();
  final totalController = TextEditingController();
  final advanceController = TextEditingController();
  final notesController = TextEditingController();

  bool masterRoom1 = false;
  bool masterRoom2 = false;
  bool queenRoom1 = false;
  bool queenRoom2 = false;
  bool pentHouse = false;

  DateTime? checkIn;
  DateTime? checkOut;
  late final DateTime bookingCreatedAt;

  bool get _isAdmin => UserService.isAdmin;

  @override
  void initState() {
    super.initState();
    bookingCreatedAt = DateTime.now();
  }

  @override
  void dispose() {
    customerNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    guestsController.dispose();
    totalController.dispose();
    advanceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime({required DateTime initial}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickCheckIn() async {
    final value = await _pickDateTime(
      initial: checkIn ?? DateTime.now().add(const Duration(hours: 1)),
    );
    if (value == null) return;
    setState(() {
      checkIn = value;
      if (checkOut != null && !checkOut!.isAfter(value)) checkOut = null;
    });
  }

  Future<void> _pickCheckOut() async {
    if (checkIn == null) {
      _message('Please select Check-in date and time first.');
      return;
    }
    final value = await _pickDateTime(
      initial: checkOut ?? checkIn!.add(const Duration(hours: 12)),
    );
    if (value == null) return;
    if (!value.isAfter(checkIn!)) {
      _message('Check-out must be after Check-in.');
      return;
    }
    setState(() => checkOut = value);
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year} '
        '$hour:$minute $period';
  }

  void _message(String text, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _showBookingConfirmation(Booking booking) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Expanded(child: Text('Booking Saved')),
          ],
        ),
        content: const Text(
          'The booking was saved successfully. You can now send the confirmation to the customer.',
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await WhatsAppService.copyBookingDetails(booking);
              if (!mounted) return;
              _message('Booking details copied.', error: false);
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Details'),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                await WhatsAppService.openWhatsApp(booking);
              } on WhatsAppException catch (error) {
                if (!mounted) return;
                _message(error.message);
              }
            },
            icon: const Icon(Icons.chat),
            label: const Text('WhatsApp'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (customerNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        guestsController.text.trim().isEmpty) {
      _message('Please fill all mandatory guest details.');
      return;
    }

    final guests = int.tryParse(guestsController.text.trim());
    if (guests == null || guests <= 0) {
      _message('Enter a valid number of guests.');
      return;
    }

    final selectedRooms = <String>[
      if (masterRoom1) 'MR1',
      if (masterRoom2) 'MR2',
      if (queenRoom1) 'QR1',
      if (queenRoom2) 'QR2',
      if (pentHouse) 'PH',
    ];
    if (selectedRooms.isEmpty) {
      _message('Please select at least one room.');
      return;
    }
    if (checkIn == null || checkOut == null) {
      _message('Please select Check-in and Check-out date and time.');
      return;
    }
    if (!checkOut!.isAfter(checkIn!)) {
      _message('Check-out must be after Check-in.');
      return;
    }

    var total = 0.0;
    var advance = 0.0;
    if (_isAdmin) {
      if (totalController.text.trim().isEmpty ||
          advanceController.text.trim().isEmpty) {
        _message('Please enter Total and Advance amounts.');
        return;
      }
      total = double.tryParse(totalController.text.trim()) ?? -1;
      advance = double.tryParse(advanceController.text.trim()) ?? -1;
      if (total < 0 || advance < 0 || advance > total) {
        _message('Enter valid payment amounts. Advance cannot exceed Total.');
        return;
      }
    }

    for (final room in selectedRooms) {
      if (!BookingService.isRoomAvailable(room, checkIn!, checkOut!)) {
        _message('$room is already booked for the selected time.');
        return;
      }
    }

    final booking = Booking(
      bookingId: BookingService.generateBookingId(),
      bookingCreatedAt: bookingCreatedAt,
      customerName: customerNameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      address: addressController.text.trim(),
      guests: guests,
      rooms: selectedRooms,
      checkIn: checkIn!,
      checkOut: checkOut!,
      totalAmount: total,
      advanceAmount: advance,
      balanceAmount: total - advance,
      notes: notesController.text.trim(),
    );

    final success = await BookingService.addBooking(booking);
    if (!success) {
      if (mounted) _message('Booking failed. A selected room may be unavailable.');
      return;
    }

    try {
      await CustomerService.upsertFromBooking(booking);
    } catch (error) {
      debugPrint('Customer profile sync failed: $error');
    }

    if (!mounted) return;
    await _showBookingConfirmation(booking);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Booking'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Booking Date'),
              subtitle: Text(_formatDateTime(bookingCreatedAt)),
            ),
          ),
          const SizedBox(height: 12),
          _field(customerNameController, 'Customer Name *'),
          _field(phoneController, 'Phone Number *', type: TextInputType.phone),
          _field(addressController, 'Address *', maxLines: 2),
          _field(guestsController, 'Number of Guests *', type: TextInputType.number),
          const SizedBox(height: 12),
          const Text('Select Room(s)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          CheckboxListTile(title: const Text('Master Room 1'), value: masterRoom1, onChanged: (v) => setState(() => masterRoom1 = v ?? false)),
          CheckboxListTile(title: const Text('Master Room 2'), value: masterRoom2, onChanged: (v) => setState(() => masterRoom2 = v ?? false)),
          CheckboxListTile(title: const Text('Queen Room 1'), value: queenRoom1, onChanged: (v) => setState(() => queenRoom1 = v ?? false)),
          CheckboxListTile(title: const Text('Queen Room 2'), value: queenRoom2, onChanged: (v) => setState(() => queenRoom2 = v ?? false)),
          CheckboxListTile(title: const Text('Penthouse'), value: pentHouse, onChanged: (v) => setState(() => pentHouse = v ?? false)),
          const SizedBox(height: 8),
          _dateTimeTile('Check-in *', checkIn, _pickCheckIn),
          const SizedBox(height: 10),
          _dateTimeTile('Check-out *', checkOut, _pickCheckOut),
          if (_isAdmin) ...[
            const SizedBox(height: 20),
            _field(totalController, 'Total Amount *', type: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {})),
            _field(advanceController, 'Advance Amount *', type: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {})),
            Builder(builder: (_) {
              final total = double.tryParse(totalController.text) ?? 0;
              final advance = double.tryParse(advanceController.text) ?? 0;
              return Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    'Balance: ₹${(total - advance).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('Payment details are managed by the administrator.'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _field(notesController, 'Notes (Optional)', maxLines: 3),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? type,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _dateTimeTile(String label, DateTime? value, VoidCallback onTap) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)),
      title: Text(value == null ? 'Select $label' : '$label: ${_formatDateTime(value)}'),
      trailing: const Icon(Icons.calendar_month),
      onTap: onTap,
    );
  }
}
