import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/user_service.dart';
import 'add_booking_screen.dart';
import 'booking_history_screen.dart';
import 'current_guests_screen.dart';
import 'future_bookings_screen.dart';
import 'room_status_screen.dart';
import 'today_checkins_screen.dart';
import 'today_checkouts_screen.dart';
import 'staff_management_screen.dart';
import 'customer_list_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GOVIstays Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: BookingService.changeNotifier,
        builder: (context, _, __) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _roomSummaryCard(context),
              const SizedBox(height: 16),
              _dashboardCard(
                icon: Icons.login,
                title: "Today's Check-ins",
                count: BookingService.todayCheckInsCount,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TodayCheckinsScreen(),
                    ),
                  );
                },
              ),
              _dashboardCard(
                icon: Icons.logout,
                title: "Today's Check-outs",
                count: BookingService.todayCheckOutsCount,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TodayCheckoutsScreen(),
                    ),
                  );
                },
              ),
              _dashboardCard(
                icon: Icons.people,
                title: 'Current Guests',
                count: BookingService.currentGuestsCount,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CurrentGuestsScreen(),
                    ),
                  );
                },
              ),
              _dashboardCard(
                icon: Icons.book_online,
                title: 'Future Bookings',
                count: BookingService.futureBookingsCount,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FutureBookingsScreen(),
                    ),
                  );
                },
              ),
              _dashboardCard(
                icon: Icons.history,
                title: 'Booking History',
                count: BookingService.bookingHistoryCount,
                color: Colors.brown,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookingHistoryScreen(),
                    ),
                  );
                },
              ),
              if (UserService.isAdmin) ...[
                const SizedBox(height: 8),
                Card(
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading: const CircleAvatar(
                      radius: 24,
                      child: Icon(Icons.people_alt),
                    ),
                    title: const Text(
                      'Customers',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: const Text('Search customers and view booking history'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerListScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading: const CircleAvatar(
                      radius: 24,
                      child: Icon(Icons.analytics),
                    ),
                    title: const Text(
                      'Reports & Analytics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: const Text('Revenue, balances, bookings and occupancy'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading: const CircleAvatar(
                      radius: 24,
                      child: Icon(Icons.manage_accounts),
                    ),
                    title: const Text(
                      'Staff Management',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: const Text('Add, edit, enable or disable staff'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffManagementScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (UserService.canManageBookings) ...[
                const SizedBox(height: 8),
                Card(
                  elevation: 5,
                  child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  leading: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                  title: const Text(
                    'Add Booking',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: const Text('Create a new guest reservation'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddBookingScreen(),
                      ),
                    );
                  },
                ),
              ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _roomSummaryCard(BuildContext context) {
    return Card(
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RoomStatusScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.hotel, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Room Availability',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roomMetric('Total', BookingService.totalRoomsCount),
                  _roomMetric('Occupied', BookingService.occupiedRoomsCount),
                  _roomMetric('Available', BookingService.availableRoomsCount),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: BookingService.occupancyPercentage / 100,
                  minHeight: 9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Occupancy: ${BookingService.occupancyPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roomMetric(String label, int value) {
    return Column(
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

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 5,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          count == 1 ? '1 booking' : '$count bookings',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 40),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await AuthService.signOut();
    }
  }

}
