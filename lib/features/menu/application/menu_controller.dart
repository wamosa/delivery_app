import '../data/menu_repository.dart';
import '../domain/meal_session.dart';
import '../domain/menu_item.dart';

class MenuController {
  MenuController({MenuRepository? repository})
      : _repository = repository ?? MenuRepository();

  final MenuRepository _repository;

  Future<List<MenuItem>> loadPopularItems() {
    return _repository.fetchPopularItems();
  }

  Future<List<MealSession>> loadMealSessions() {
    return _repository.fetchMealSessions();
  }

  Stream<List<MenuItem>> watchAvailableItems() {
    return _repository.watchAvailableItems();
  }

  Stream<List<MealSession>> watchMealSessions() {
    return _repository.watchMealSessions();
  }
}
