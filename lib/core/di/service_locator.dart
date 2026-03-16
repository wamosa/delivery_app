import 'package:get_it/get_it.dart';

import '../../features/admin/application/admin_controller.dart';
import '../../features/admin/data/admin_repository.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/cart/application/cart_controller.dart';
import '../../features/cart/data/cart_repository.dart';
import '../../features/checkout/application/checkout_controller.dart';
import '../../features/checkout/data/checkout_repository.dart';
import '../../features/home/application/home_controller.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/menu/application/menu_controller.dart';
import '../../features/menu/data/menu_repository.dart';
import '../../features/orders/application/orders_controller.dart';
import '../../features/orders/data/orders_repository.dart';
import '../data/business_settings_repository.dart';
import '../services/order_functions_service.dart';
import '../services/notification_service.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  if (getIt.isRegistered<AuthController>()) {
    return;
  }

  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<AuthController>(
    () => AuthController(repository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<BusinessSettingsRepository>(
    () => BusinessSettingsRepository(),
  );
  getIt.registerLazySingleton<MenuRepository>(() => MenuRepository());
  getIt.registerLazySingleton<MenuController>(
    () => MenuController(
      repository: getIt<MenuRepository>(),
      businessSettingsRepository: getIt<BusinessSettingsRepository>(),
    ),
  );

  getIt.registerLazySingleton<CartRepository>(() => CartRepository());
  getIt.registerLazySingleton<CartController>(
    () => CartController(repository: getIt<CartRepository>()),
  );

  getIt.registerLazySingleton<OrderFunctionsService>(
    () => OrderFunctionsService(),
  );
  getIt.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepository(
      orderFunctionsService: getIt<OrderFunctionsService>(),
    ),
  );
  getIt.registerLazySingleton<CheckoutController>(
    () => CheckoutController(repository: getIt<CheckoutRepository>()),
  );

  getIt.registerLazySingleton<OrdersRepository>(() => OrdersRepository());
  getIt.registerLazySingleton<OrdersController>(
    () => OrdersController(repository: getIt<OrdersRepository>()),
  );

  getIt.registerLazySingleton<HomeRepository>(() => HomeRepository());
  getIt.registerLazySingleton<HomeController>(
    () => HomeController(repository: getIt<HomeRepository>()),
  );

  getIt.registerLazySingleton<AdminRepository>(() => AdminRepository());
  getIt.registerLazySingleton<AdminController>(
    () => AdminController(repository: getIt<AdminRepository>()),
  );

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService.instance,
  );
}
