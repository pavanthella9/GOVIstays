class Booking {
  final String bookingId;
  final String customerName;
  final String phoneNumber;
  final String address;
  final int guests;
  final List<String> rooms;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalAmount;
  final double advanceAmount;
  final double balanceAmount;
  final String notes;
  

  Booking({
    required this.bookingId,
    required this.customerName,
    required this.phoneNumber,
    required this.address,
    required this.guests,
    required this.rooms,
    required this.checkIn,
    required this.checkOut,
    required this.totalAmount,
    required this.advanceAmount,
    required this.balanceAmount,
    required this.notes,
  });

  
}