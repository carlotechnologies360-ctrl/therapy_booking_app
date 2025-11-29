import 'package:flutter/foundation.dart';
import '../models/service_model.dart';

class CartProvider extends ChangeNotifier {
  final List<ServiceModel> _items = [];

  List<ServiceModel> get items => _items;

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.price);
  }

  int get totalDuration {
    return _items.fold(0, (sum, item) => sum + item.durationMinutes);
  }

  void addService(ServiceModel service) {
    _items.add(service);
    notifyListeners();
  }

  void removeService(ServiceModel service) {
    _items.removeWhere((item) => item.id == service.id);
    notifyListeners();
  }

  bool isInCart(String serviceId) {
    return _items.any((item) => item.id == serviceId);
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
