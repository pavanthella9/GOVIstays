import 'package:flutter/material.dart';

import '../services/booking_service.dart';

class RoomStatusScreen extends StatelessWidget {
  const RoomStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Status'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: BookingService.changeNotifier,
        builder: (context, _, __) {
          final occupiedRooms = BookingService.occupiedRoomsToday;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(),
              const SizedBox(height: 14),
              const Text(
                "Today's Room Availability",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...BookingService.allRooms.map((room) {
                final isOccupied = occupiedRooms.contains(room);
                return _roomCard(room, isOccupied);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem('Total', BookingService.totalRoomsCount),
            _summaryItem('Occupied', BookingService.occupiedRoomsCount),
            _summaryItem('Available', BookingService.availableRoomsCount),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  Widget _roomCard(String room, bool isOccupied) {
    final statusColor = isOccupied ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.14),
          child: Icon(
            isOccupied ? Icons.hotel : Icons.meeting_room,
            color: statusColor,
          ),
        ),
        title: Text(
          room,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isOccupied ? 'Occupied today' : 'Available today',
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          isOccupied ? Icons.cancel : Icons.check_circle,
          color: statusColor,
        ),
      ),
    );
  }
}
