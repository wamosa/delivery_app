import '../domain/meal_session.dart';
import '../domain/menu_item.dart';

class MenuScreenState {
  const MenuScreenState({
    required this.now,
    required this.sessions,
    required this.activeSession,
    required this.displaySession,
    required this.items,
    required this.isPrepWindow,
  });

  final DateTime now;
  final List<MealSession> sessions;
  final MealSession? activeSession;
  final MealSession? displaySession;
  final List<MenuItem> items;
  final bool isPrepWindow;

  bool get orderingClosed => activeSession == null;
  bool get hasDisplaySession => displaySession != null;
}
