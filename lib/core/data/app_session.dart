class AppSession {
  const AppSession({
    required this.userId,
    required this.activeOrderCount,
  });

  final String userId;
  final int activeOrderCount;
}
