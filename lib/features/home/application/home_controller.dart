import '../../auth/domain/auth_user.dart';
import '../data/home_repository.dart';
import '../domain/dashboard_item.dart';

class HomeController {
  HomeController({HomeRepository? repository})
      : _repository = repository ?? HomeRepository();

  final HomeRepository _repository;

  List<DashboardItem> loadModules(AuthRole role) {
    return _repository.loadModules(role);
  }
}
