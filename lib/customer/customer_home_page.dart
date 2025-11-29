import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../providers/cart_provider.dart';

class CustomerHomePage extends StatefulWidget {
  final String therapistCode;
  final String therapistName;
  final String therapistBio;
  final String therapistContact;

  const CustomerHomePage({
    super.key,
    this.therapistCode = "THERAPIST123",
    this.therapistName = "Dr. Sarah Johnson",
    this.therapistBio = "Licensed massage therapist with 10+ years of experience specializing in therapeutic and relaxation massage.",
    this.therapistContact = "contact@therapist.com | (555) 123-4567",
  });

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  // Dummy services - Replace with database query later
  final List<ServiceModel> _services = [
    ServiceModel(
      id: '1',
      name: 'Swedish Massage',
      description: 'Relaxing full body massage using gentle strokes',
      durationMinutes: 60,
      price: 80.0,
    ),
    ServiceModel(
      id: '2',
      name: 'Deep Tissue Massage',
      description: 'Focused pressure on deep muscle layers',
      durationMinutes: 60,
      price: 95.0,
    ),
    ServiceModel(
      id: '3',
      name: 'Sports Massage',
      description: 'Targeted therapy for athletes and active individuals',
      durationMinutes: 75,
      price: 110.0,
    ),
    ServiceModel(
      id: '4',
      name: 'Hot Stone Therapy',
      description: 'Heated stones combined with massage techniques',
      durationMinutes: 90,
      price: 130.0,
    ),
    ServiceModel(
      id: '5',
      name: 'Aromatherapy Massage',
      description: 'Essential oils massage for relaxation and healing',
      durationMinutes: 60,
      price: 90.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Therapist Services"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'My Bookings',
            onPressed: () {
              Navigator.pushNamed(context, '/customer_bookings');
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Therapist Info Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Colors.teal),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.therapistName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.therapistBio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.therapistContact,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: 20),
                      Icon(Icons.star, color: Colors.yellow[700], size: 20),
                      Icon(Icons.star, color: Colors.yellow[700], size: 20),
                      Icon(Icons.star, color: Colors.yellow[700], size: 20),
                      Icon(Icons.star_half, color: Colors.yellow[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '4.5 (120 reviews)',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Services Header
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Available Services',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Services List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                final isInCart = cart.isInCart(service.id);

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '\$${service.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${service.durationMinutes} min',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: isInCart
                                  ? null
                                  : () {
                                      cart.addService(service);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${service.name} added to cart'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                              icon: Icon(
                                isInCart ? Icons.check : Icons.add_shopping_cart,
                              ),
                              label: Text(isInCart ? 'Added' : 'Add to Cart'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isInCart ? Colors.grey : Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: cart.itemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/cart');
              },
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('View Cart (${cart.itemCount})'),
              backgroundColor: Colors.teal,
            )
          : null,
    );
  }
}
