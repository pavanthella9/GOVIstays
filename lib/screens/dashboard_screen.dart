import 'package:flutter/material.dart';

import 'add_booking_screen.dart';
import 'today_checkins_screen.dart';
import 'today_checkouts_screen.dart';
import 'current_guests_screen.dart';
import 'future_bookings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GOVIstays Dashboard'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          dashboardCard(
            Icons.calendar_today,
            "Today's Check-ins",
            Colors.green,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TodayCheckinsScreen(),
                ),
              );
            },
          ),

          dashboardCard(
            Icons.logout,
            "Today's Check-outs",
            Colors.orange,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TodayCheckoutsScreen(),
                ),
              );
            },
          ),

          dashboardCard(
            Icons.people,
            "Current Guests",
            Colors.blue,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrentGuestsScreen(),
                ),
              );
            },
          ),

          dashboardCard(
            Icons.book_online,
            "Future Bookings",
            Colors.purple,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FutureBookingsScreen(),
                ),
              );
            },
          ),

          dashboardCard(
            Icons.add_box,
            "Add Booking",
            Colors.red,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBookingScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget dashboardCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 5,
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
          size: 35,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}