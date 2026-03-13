class AdminDashboardState {
  const AdminDashboardState({
    required this.todaysOrdersCount,
    required this.pendingOrdersCount,
    required this.activeMealSessionName,
    required this.soldOutItemsCount,
    required this.businessName,
    required this.bannerMessage,
    required this.activeOffer,
    required this.pickupEnabled,
    required this.orderingOpen,
  });

  final int todaysOrdersCount;
  final int pendingOrdersCount;
  final String activeMealSessionName;
  final int soldOutItemsCount;
  final String businessName;
  final String bannerMessage;
  final String activeOffer;
  final bool pickupEnabled;
  final bool orderingOpen;
}
