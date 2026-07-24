import '../models/booking.dart';
import '../services/booking_service.dart';

import 'package:flutter/material.dart';

class AddBookingScreen extends StatefulWidget {
  const AddBookingScreen({super.key});

  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {

  final _formKey = GlobalKey<FormState>();

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

  DateTime? checkInDate;
  DateTime? checkOutDate;

  Future<void> pickCheckInDate() async {

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (picked != null) {

      setState(() {
        checkInDate = picked;

        if (checkOutDate != null &&
            !checkOutDate!.isAfter(checkInDate!)) {
          checkOutDate = null;
        }
      });
    }
  }

  Future<void> pickCheckOutDate() async {

    if (checkInDate == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select Check-in Date first.",
          ),
        ),
      );

      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: checkInDate!.add(const Duration(days: 1)),
      firstDate: checkInDate!.add(const Duration(days: 1)),
      lastDate: DateTime(2035),
    );

    if (picked != null) {

      setState(() {
        checkOutDate = picked;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Booking"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Booking ID : GST-0001",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: customerNameController,
            decoration: const InputDecoration(
              labelText: "Customer Name *",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Phone Number *",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: "Address *",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: guestsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Number of Guests *",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 25),
          const Text(
            "Select Room(s)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          CheckboxListTile(
            title: const Text("Master Room 1"),
            value: masterRoom1,
            onChanged: (v) => setState(() => masterRoom1 = v ?? false),
          ),
          CheckboxListTile(
            title: const Text("Master Room 2"),
            value: masterRoom2,
            onChanged: (v) => setState(() => masterRoom2 = v ?? false),
          ),
          CheckboxListTile(
            title: const Text("Queen Room 1"),
            value: queenRoom1,
            onChanged: (v) => setState(() => queenRoom1 = v ?? false),
          ),
          CheckboxListTile(
            title: const Text("Queen Room 2"),
            value: queenRoom2,
            onChanged: (v) => setState(() => queenRoom2 = v ?? false),
          ),
          CheckboxListTile(
            title: const Text("Penthouse"),
            value: pentHouse,
            onChanged: (v) => setState(() => pentHouse = v ?? false),
          ),

          const SizedBox(height: 20),

          ListTile(
            title: Text(
              checkInDate == null
                  ? "Select Check-in Date"
                  : "Check-in : ${checkInDate!.day}/${checkInDate!.month}/${checkInDate!.year}",
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: pickCheckInDate,
          ),
          ListTile(
            title: Text(
              checkOutDate == null
                  ? "Select Check-out Date"
                  : "Check-out : ${checkOutDate!.day}/${checkOutDate!.month}/${checkOutDate!.year}",
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: pickCheckOutDate,
          ),

          const SizedBox(height: 20),

          TextField(
            controller: totalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Total Amount *",
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: advanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Advance Amount *",
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 15),

          Builder(
            builder: (context) {
              final total = double.tryParse(totalController.text) ?? 0;
              final advance = double.tryParse(advanceController.text) ?? 0;
              final balance = total - advance;

              return Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total : ₹${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Advance : ₹${advance.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const Divider(),
                      Text(
                        "Balance : ₹${balance.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Notes (Optional)",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                // Mandatory fields
                if (customerNameController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty ||
                    guestsController.text.trim().isEmpty ||
                    totalController.text.trim().isEmpty ||
                    advanceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all mandatory fields."),
                    ),
                  );
                  return;
                }

                // Room validation
                if (!(masterRoom1 ||
                    masterRoom2 ||
                    queenRoom1 ||
                    queenRoom2 ||
                    pentHouse)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select at least one room."),
                    ),
                  );
                  return;
                }

                // Date validation
                if (checkInDate == null || checkOutDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select Check-in & Check-out dates."),
                    ),
                  );
                  return;
                }

                if (!checkOutDate!.isAfter(checkInDate!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Check-out date must be after Check-in date."),
                    ),
                  );
                  return;
                }

                final total = double.tryParse(totalController.text.trim()) ?? 0;
                final advance = double.tryParse(advanceController.text.trim()) ?? 0;

                if (advance > total) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Advance Amount cannot be greater than Total Amount.",
                      ),
                    ),
                  );
                  return;
                }

                final selectedRooms = <String>[
                  if (masterRoom1) "MR1",
                  if (masterRoom2) "MR2",
                  if (queenRoom1) "QR1",
                  if (queenRoom2) "QR2",
                  if (pentHouse) "PH",
                ];

                // Double booking validation
                for (final room in selectedRooms) {
                  if (!BookingService.isRoomAvailable(
                    room,
                    checkInDate!,
                    checkOutDate!,
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "$room is already booked for selected dates.",
                        ),
                      ),
                    );
                    return;
                  }
                }

                final booking = Booking(
                  bookingId: "GST${DateTime.now().millisecondsSinceEpoch}",
                  customerName: customerNameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  address: addressController.text.trim(),
                  guests: int.parse(guestsController.text.trim()),
                  rooms: selectedRooms,
                  checkIn: checkInDate!,
                  checkOut: checkOutDate!,
                  totalAmount: total,
                  advanceAmount: advance,
                  balanceAmount: total - advance,
                  notes: notesController.text.trim(),
                );

                final success = await BookingService.addBooking(booking);

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Booking failed. Room already booked.",
                      ),
                    ),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text("Booking Saved Successfully"),
                  ),
                );

                Navigator.pop(context);
              },
              child: const Text(
                "Save Booking",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
