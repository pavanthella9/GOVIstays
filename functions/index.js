const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const TOPIC = "govistays_bookings";

function two(value) {
  return String(value).padStart(2, "0");
}

function formatCheckIn(timestamp) {
  if (!timestamp || typeof timestamp.toDate !== "function") {
    return "Check-in time available in app";
  }

  const date = timestamp.toDate();

  // Firebase functions run in UTC by default. Format using India time
  // because Hillside Heaven Homestay operates in Tirupati.
  return new Intl.DateTimeFormat("en-IN", {
    timeZone: "Asia/Kolkata",
    day: "2-digit",
    month: "short",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(date);
}

exports.notifyNewBooking = onDocumentCreated(
  {
    document: "bookings/{bookingId}",
    region: "asia-south1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const booking = snapshot.data();
    const rooms = Array.isArray(booking.rooms)
      ? booking.rooms.join(", ")
      : "Room";

    const checkIn = formatCheckIn(booking.checkIn);

    const message = {
      topic: TOPIC,
      notification: {
        title: "New GOVIstays Booking",
        // Keep customer/payment details out of push notifications.
        body: `${rooms} • Check-in ${checkIn}`,
      },
      data: {
        type: "new_booking",
        bookingId: String(
          booking.bookingId || event.params.bookingId,
        ),
      },
      android: {
        priority: "high",
      },
    };

    await getMessaging().send(message);
  },
);
