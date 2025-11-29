class BookingModel {
  final String? id;
  final String therapistCode;
  final String customerEmail;
  final String customerName;
  final DateTime bookingDate;
  final String timeSlot;
  final List<String> serviceNames;
  final double totalPrice;
  final int totalDuration;
  final DateTime createdAt;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'

  BookingModel({
    this.id,
    required this.therapistCode,
    required this.customerEmail,
    required this.customerName,
    required this.bookingDate,
    required this.timeSlot,
    required this.serviceNames,
    required this.totalPrice,
    required this.totalDuration,
    required this.createdAt,
    this.status = 'confirmed',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'therapistCode': therapistCode,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'bookingDate': bookingDate.toIso8601String(),
      'timeSlot': timeSlot,
      'serviceNames': serviceNames.join(','),
      'totalPrice': totalPrice,
      'totalDuration': totalDuration,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id']?.toString(),
      therapistCode: map['therapistCode'] as String,
      customerEmail: map['customerEmail'] as String,
      customerName: map['customerName'] as String,
      bookingDate: DateTime.parse(map['bookingDate'] as String),
      timeSlot: map['timeSlot'] as String,
      serviceNames: (map['serviceNames'] as String).split(','),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      totalDuration: map['totalDuration'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: map['status'] as String? ?? 'confirmed',
    );
  }
}
