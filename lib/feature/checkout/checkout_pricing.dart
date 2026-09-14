const double freeShippingFrom = 100;
const double standardShippingFee = 4.90;

double shippingFor(double subtotal) {
  if (subtotal >= freeShippingFrom) return 0;
  return standardShippingFee;
}

double checkoutTotal(double subtotal) => subtotal + shippingFor(subtotal);
