import 'package:cloud_functions/cloud_functions.dart';

import '../features/checkout/domain/place_order_request.dart';
import '../features/checkout/domain/place_order_result.dart';

class OrderFunctionsService {
  OrderFunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<PlaceOrderResult> placeOrder(PlaceOrderRequest request) async {
    final callable = _functions.httpsCallable('placeOrder');
    final response = await callable.call<Map<String, dynamic>>(request.toMap());
    return PlaceOrderResult.fromMap(response.data);
  }
}
