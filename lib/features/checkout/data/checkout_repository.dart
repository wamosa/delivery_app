import '../../../services/order_functions_service.dart';
import '../domain/checkout_preview.dart';
import '../domain/place_order_request.dart';
import '../domain/place_order_result.dart';

class CheckoutRepository {
  CheckoutRepository({OrderFunctionsService? orderFunctionsService})
      : _orderFunctionsService = orderFunctionsService ?? OrderFunctionsService();

  final OrderFunctionsService _orderFunctionsService;

  CheckoutPreview getPreview() {
    return const CheckoutPreview(
      address: 'Westlands, Nairobi',
      paymentMethod: 'M-Pesa',
      eta: '25-35 min',
    );
  }

  Future<PlaceOrderResult> placeOrder(PlaceOrderRequest request) {
    return _orderFunctionsService.placeOrder(request);
  }
}
