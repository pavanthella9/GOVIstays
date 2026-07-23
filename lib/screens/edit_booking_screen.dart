import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';

class EditBookingScreen extends StatefulWidget {
  final Booking booking;

  const EditBookingScreen({
    super.key,
    required this.booking,
  });

  @override
  State<EditBookingScreen> createState() =>
      _EditBookingScreenState();
}

class _EditBookingScreenState
    extends State<EditBookingScreen> {

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

  @override
  void initState() {
    super.initState();

    customerNameController.text =
        widget.booking.customerName;

    phoneController.text =
        widget.booking.phoneNumber;

    addressController.text =
        widget.booking.address;

    guestsController.text =
        widget.booking.guests.toString();

    totalController.text =
        widget.booking.totalAmount.toString();

    advanceController.text =
        widget.booking.advanceAmount.toString();

    notesController.text =
        widget.booking.notes;

    checkInDate = widget.booking.checkIn;
    checkOutDate = widget.booking.checkOut;

    masterRoom1 =
        widget.booking.rooms.contains("MR1");

    masterRoom2 =
        widget.booking.rooms.contains("MR2");

    queenRoom1 =
        widget.booking.rooms.contains("QR1");

    queenRoom2 =
        widget.booking.rooms.contains("QR2");

    pentHouse =
        widget.booking.rooms.contains("PH");
  }

  Future<void> pickCheckInDate() async {

    final picked = await showDatePicker(
      context: context,
      initialDate: checkInDate ?? DateTime.now(),
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

    if (checkInDate == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: checkOutDate ??
          checkInDate!.add(
            const Duration(days: 1),
          ),
      firstDate:
          checkInDate!.add(
            const Duration(days: 1),
          ),
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
    title: const Text("Edit Booking"),
    centerTitle: true,
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [

      Text(
        "Booking ID : ${widget.booking.bookingId}",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
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
        maxLines: 2,
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
          labelText: "Guests *",
          border: OutlineInputBorder(),
        ),
      ),

      const SizedBox(height: 25),

      const Text(
        "Rooms",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      CheckboxListTile(
        value: masterRoom1,
        title: const Text("Master Room 1"),
        onChanged: (value) {
          setState(() {
            masterRoom1 = value!;
          });
        },
      ),

      CheckboxListTile(
        value: masterRoom2,
        title: const Text("Master Room 2"),
        onChanged: (value) {
          setState(() {
            masterRoom2 = value!;
          });
        },
      ),

      CheckboxListTile(
        value: queenRoom1,
        title: const Text("Queen Room 1"),
        onChanged: (value) {
          setState(() {
            queenRoom1 = value!;
          });
        },
      ),

      CheckboxListTile(
        value: queenRoom2,
        title: const Text("Queen Room 2"),
        onChanged: (value) {
          setState(() {
            queenRoom2 = value!;
          });
        },
      ),

      CheckboxListTile(
        value: pentHouse,
        title: const Text("Penthouse"),
        onChanged: (value) {
          setState(() {
            pentHouse = value!;
          });
        },
      ),

      const SizedBox(height: 20),

      ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.grey),
        ),
        title: Text(
          checkInDate == null
              ? "Select Check-In Date"
              : "Check-In : ${checkInDate!.toLocal().toString().split(' ')[0]}",
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: pickCheckInDate,
      ),

      const SizedBox(height: 10),

      ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.grey),
        ),
        title: Text(
          checkOutDate == null
              ? "Select Check-Out Date"
              : "Check-Out : ${checkOutDate!.toLocal().toString().split(' ')[0]}",
        ),
        trailing: const Icon(Icons.calendar_today),
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

const SizedBox(height: 20),

Builder(
  builder: (context) {

    final total =
        double.tryParse(totalController.text) ?? 0;

    final advance =
        double.tryParse(advanceController.text) ?? 0;

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
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

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
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    ),
    onPressed: () {

      if (customerNameController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty ||
          addressController.text.trim().isEmpty ||
          guestsController.text.trim().isEmpty ||
          totalController.text.trim().isEmpty ||
          advanceController.text.trim().isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please fill all mandatory fields.",
            ),
          ),
        );
        return;
      }

      if (checkInDate == null || checkOutDate == null) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please select Check-In & Check-Out dates.",
            ),
          ),
        );
        return;
      }

      if (!checkOutDate!.isAfter(checkInDate!)) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Check-Out must be after Check-In.",
            ),
          ),
        );
        return;
      }

      final total =
          double.tryParse(totalController.text) ?? 0;

      final advance =
          double.tryParse(advanceController.text) ?? 0;

      if (advance > total) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Advance cannot exceed Total Amount.",
            ),
          ),
        );
        return;
      }

      final rooms = <String>[
        if (masterRoom1) "MR1",
        if (masterRoom2) "MR2",
        if (queenRoom1) "QR1",
        if (queenRoom2) "QR2",
        if (pentHouse) "PH",
      ];

      final updatedBooking = Booking(
        bookingId: widget.booking.bookingId,
        customerName: customerNameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        address: addressController.text.trim(),
        guests: int.parse(guestsController.text.trim()),
        rooms: rooms,
        checkIn: checkInDate!,
        checkOut: checkOutDate!,
        totalAmount: total,
        advanceAmount: advance,
        balanceAmount: total - advance,
        notes: notesController.text.trim(),
      );

      BookingService.updateBooking(
        widget.booking,
        updatedBooking,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Booking Updated Successfully",
          ),
        ),
      );

      Navigator.pop(context, true);

    },
    child: const Text(
      "Update Booking",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

const SizedBox(height: 20),

],
),
);
}
}