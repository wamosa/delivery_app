import '../data/checkout_repository.dart';
import '../domain/checkout_preview.dart';
import '../domain/place_order_request.dart';
import '../domain/place_order_result.dart';

class CheckoutController {
  CheckoutController({CheckoutRepository? repository})
      : _repository = repository ?? CheckoutRepository();

  final CheckoutRepository _repository;

  CheckoutPreview loadPreview() {
    return _repository.getPreview();
  }

  Future<PlaceOrderResult> placeOrder(PlaceOrderRequest request) {
    return _repository.placeOrder(request);
  }
}
