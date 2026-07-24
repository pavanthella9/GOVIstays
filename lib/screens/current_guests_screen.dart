import 'package:flutter/material.dart';

import '../services/booking_service.dart';
import 'booking_details_screen.dart';

class CurrentGuestsScreen extends StatefulWidget {
  const CurrentGuestsScreen({super.key});

  @override
  State<CurrentGuestsScreen> createState() =>
      _CurrentGuestsScreenState();
}

class _CurrentGuestsScreenState extends State<CurrentGuestsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: BookingService.changeNotifier,
      builder: (context, _, __) {
        final currentGuests = BookingService.getCurrentGuests();
        final bookings = BookingService.searchBookings(
          currentGuests,
          _searchQuery,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Current Guests'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Search by name, phone, or booking ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: bookings.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No Current Guests'
                              : 'No matching guests found',
                          style: const TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.only(bottom: 12),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(booking.customerName),
                              subtitle: Text(
                                'Phone: ${booking.phoneNumber}\n'
                                'Room: ${booking.rooms.join(', ')}\n'
                                'Check-out: ${_formatDate(booking.checkOut)}',
                              ),
                              trailing: Text(
                                '₹${booking.balanceAmount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              isThreeLine: true,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BookingDetailsScreen(
                                      booking: booking,
                                    ),
                                  ),
                                );

                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
