import '../data/home_repository.dart';
import '../domain/dashboard_item.dart';

class HomeController {
  HomeController({HomeRepository? repository})
      : _repository = repository ?? HomeRepository();

  final HomeRepository _repository;

  List<DashboardItem> loadModules() {
    return _repository.loadModules();
  }
}
