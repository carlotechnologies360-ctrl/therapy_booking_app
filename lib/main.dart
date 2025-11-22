import 'package:flutter/material.dart';

void main() {
  runApp(MassageBookingApp());
}

class MassageBookingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Massage Booking",
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: "Helvetica",
      ),
      home: HomePage(),
    );
  }
}

// ---------------- HOME PAGE ----------------
class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> services = [
    {"name": "Swedish Massage", "price": 999, "duration": "60 min"},
    {"name": "Thai Massage", "price": 1199, "duration": "60 min"},
    {"name": "Aroma Therapy", "price": 1499, "duration": "90 min"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Massage Services"),
        actions: [
          IconButton(
            icon: Icon(Icons.login),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MasseurLoginPage()),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(
                services[index]["name"],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "₹${services[index]["price"]} • ${services[index]["duration"]}",
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailsPage(service: services[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------------- SERVICE DETAILS ----------------
class ServiceDetailsPage extends StatelessWidget {
  final Map<String, dynamic> service;

  ServiceDetailsPage({required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(service["name"]),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service["name"],
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Price: ₹${service["price"]}",
                style: TextStyle(fontSize: 20)),
            Text("Duration: ${service["duration"]}",
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 30),
            ElevatedButton(
              child: Text("Book Now"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(service: service),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- BOOKING PAGE ----------------
class BookingPage extends StatefulWidget {
  final Map<String, dynamic> service;

  BookingPage({required this.service});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book Appointment")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Select Date
            ListTile(
              title: Text(selectedDate == null
                  ? "Select Date"
                  : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}"),
              trailing: Icon(Icons.calendar_today),
              onTap: pickDate,
            ),
            // Select Time
            ListTile(
              title: Text(selectedTime == null
                  ? "Select Time"
                  : selectedTime!.format(context)),
              trailing: Icon(Icons.access_time),
              onTap: pickTime,
            ),

            SizedBox(height: 30),

            ElevatedButton(
              child: Text("Confirm Booking"),
              onPressed: selectedDate == null || selectedTime == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingConfirmationPage(
                            service: widget.service,
                            date: selectedDate!,
                            time: selectedTime!,
                          ),
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  void pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  void pickTime() async {
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) setState(() => selectedTime = time);
  }
}

// ---------------- BOOKING CONFIRMATION ----------------
class BookingConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> service;
  final DateTime date;
  final TimeOfDay time;

  BookingConfirmationPage(
      {required this.service, required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Booking Confirmed")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your booking is confirmed!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text("Service: ${service["name"]}", style: TextStyle(fontSize: 18)),
            Text("Date: ${date.day}-${date.month}-${date.year}",
                style: TextStyle(fontSize: 18)),
            Text("Time: ${time.format(context)}",
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                child: Text("Go to Home"),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- MASSEUR LOGIN ----------------
class MasseurLoginPage extends StatelessWidget {
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Masseur Login")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Enter Password"),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              child: Text("Login"),
              onPressed: () {
                if (passwordController.text == "admin123") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MasseurDashboardPage(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Incorrect password")),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- MASSEUR DASHBOARD ----------------
class MasseurDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Masseur Dashboard"),
      ),
      body: Center(
        child: Text(
          "Bookings will appear here (backend coming soon)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
