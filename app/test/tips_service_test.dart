import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nalvium/services/tips_service.dart';

/// Faux store : disponibilité et réponses pilotées par le test.
class _FakeIap implements InAppPurchase {
  _FakeIap({this.available, this.hangAvailable = false});
  final bool? available;
  final bool hangAvailable;
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  int buys = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;

  @override
  Future<bool> isAvailable() => hangAvailable ? Completer<bool>().future : Future.value(available ?? true);

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async => ProductDetailsResponse(
    productDetails: [
      for (final id in identifiers)
        ProductDetails(id: id, title: id, description: '', price: '2,99 €', rawPrice: 2.99, currencyCode: 'EUR'),
    ],
    notFoundIDs: const [],
  );

  @override
  Future<bool> buyConsumable({required PurchaseParam purchaseParam, bool autoConsume = true}) async {
    buys++;
    return true; // la fenêtre du store s'ouvre ; aucune réponse n'arrive tant que le test n'en émet pas
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('store indisponible : aucun produit, pas d\'erreur', () async {
    final s = StoreTipsService(_FakeIap(available: false));
    expect(await s.products(), isEmpty);
    s.dispose();
  });

  test('store qui ne répond pas : liste vide après le délai (jamais de chargement sans fin)', () async {
    final s = StoreTipsService(_FakeIap(hangAvailable: true), const Duration(milliseconds: 20));
    expect(await s.products(), isEmpty);
    s.dispose();
  });

  test('paiement abandonné (feuille fermée) : le suivant n\'est pas bloqué', () async {
    final iap = _FakeIap(available: true);
    final s = StoreTipsService(iap);
    expect(await s.products(), hasLength(3));
    final first = s.tip('nalvium.tip.coffee');
    await Future<void>.delayed(Duration.zero);
    final second = s.tip('nalvium.tip.meal');
    expect(await first, TipOutcome.cancelled);
    expect(iap.buys, 2);
    iap.purchases.add([
      PurchaseDetails(
        productID: 'nalvium.tip.meal',
        verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: 'test'),
        transactionDate: null,
        status: PurchaseStatus.purchased,
      ),
    ]);
    expect(await second, TipOutcome.thanks);
    s.dispose();
  });
}
