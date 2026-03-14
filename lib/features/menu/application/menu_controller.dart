import '../../../core/data/business_settings_repository.dart';
import '../../admin/domain/business_settings.dart';
import '../data/menu_repository.dart';
import '../domain/meal_session.dart';
import '../domain/menu_item.dart';
import 'menu_screen_state.dart';

class MenuController {
  MenuController({MenuRepository? repository})
    : _repository = repository ?? MenuRepository(),
      _businessSettingsRepository = BusinessSettingsRepository();

  final MenuRepository _repository;
  final BusinessSettingsRepository _businessSettingsRepository;

  int _minutesOfDay(DateTime time) => (time.hour * 60) + time.minute;

  int _sessionStartMinutes(MealSession session) {
    return (session.startHour * 60) + session.startMinute;
  }

  int _sessionEndMinutes(MealSession session) {
    return (session.endHour * 60) + session.endMinute;
  }

  bool _isWithinSession(MealSession session, DateTime now) {
    if (!session.isActive) {
      return false;
    }

    final current = _minutesOfDay(now);
    final start = _sessionStartMinutes(session);
    final end = _sessionEndMinutes(session);

    return current >= start && current <= end;
  }

  Future<List<MenuItem>> loadPopularItems() {
    return _repository.fetchPopularItems();
  }

  Future<List<MealSession>> loadMealSessions() {
    return _repository.fetchMealSessions();
  }

  Stream<List<MenuItem>> watchAvailableItems() {
    return _repository.watchAvailableItems();
  }

  Stream<List<MenuItem>> watchAvailableItemsForSession(String sessionId) {
    return _repository.watchAvailableItemsForSession(sessionId);
  }

  Stream<List<MealSession>> watchMealSessions() {
    return _repository.watchMealSessions();
  }

  Stream<BusinessSettings> watchBusinessSettings() {
    return _businessSettingsRepository.watchBusinessSettings();
  }

  MealSession? findActiveSession(List<MealSession> sessions, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    for (final session in sessions) {
      if (_isWithinSession(session, currentTime)) {
        return session;
      }
    }

    return null;
  }

  MealSession? findNextSession(List<MealSession> sessions, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final currentMinutes = _minutesOfDay(currentTime);

    MealSession? nextSession;

    for (final session in sessions) {
      if (!session.isActive) {
        continue;
      }

      final start = _sessionStartMinutes(session);
      if (start <= currentMinutes) {
        continue;
      }

      if (nextSession == null || start < _sessionStartMinutes(nextSession)) {
        nextSession = session;
      }
    }

    if (nextSession != null) {
      return nextSession;
    }

    for (final session in sessions) {
      if (session.isActive) {
        return session;
      }
    }

    return null;
  }

  Stream<MenuScreenState> watchMenuScreenState() {
    return watchMealSessions().asyncExpand((sessions) {
      final now = DateTime.now();
      final activeSession = findActiveSession(sessions, now: now);
      final displaySession =
          activeSession ?? findNextSession(sessions, now: now);
      final isPrepWindow = activeSession == null && displaySession != null;

      if (displaySession == null) {
        return Stream<MenuScreenState>.value(
          MenuScreenState(
            now: now,
            sessions: sessions,
            activeSession: activeSession,
            displaySession: null,
            items: const <MenuItem>[],
            isPrepWindow: false,
          ),
        );
      }

      return watchAvailableItemsForSession(displaySession.id).map(
        (items) => MenuScreenState(
          now: now,
          sessions: sessions,
          activeSession: activeSession,
          displaySession: displaySession,
          items: items,
          isPrepWindow: isPrepWindow,
        ),
      );
    });
  }
}
