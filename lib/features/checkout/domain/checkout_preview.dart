class CheckoutPreview {
  const CheckoutPreview({
    required this.address,
    required this.paymentMethod,
    required this.eta,
  });

  final String address;
  final String paymentMethod;
  final String eta;
}
