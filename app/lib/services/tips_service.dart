import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Pourboires « Soutenir Nalvium » : achats intégrés CONSOMMABLES (Apple / Google), sans aucune contrepartie.
/// Les produits sont à créer dans App Store Connect et la Play Console avec exactement ces identifiants.
const kTipProductIds = ['nalvium.tip.coffee', 'nalvium.tip.two_coffees', 'nalvium.tip.meal'];

class TipProduct {
  const TipProduct({required this.id, required this.price});
  final String id;

  /// Prix localisé fourni par le store (ex. « 2,99 € »). Jamais codé en dur.
  final String price;
}

enum TipOutcome { thanks, cancelled, failed, pending }

abstract interface class TipsService {
  /// Produits disponibles (liste vide si le store est indisponible ou les produits pas encore créés).
  Future<List<TipProduct>> products();
  Future<TipOutcome> tip(String productId);
}

class StoreTipsService implements TipsService {
  StoreTipsService([InAppPurchase? iap, this.timeout = const Duration(seconds: 10)])
    : _iap = iap ?? InAppPurchase.instance {
    // Écoute permanente : un achat en attente (paiement différé, app fermée) est toujours finalisé,
    // sinon Google le rembourse au bout de 3 jours.
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (_) => _settle(TipOutcome.failed));
  }

  final InAppPurchase _iap;

  /// Délai maximal pour joindre le store (sinon : « indisponible », jamais de chargement sans fin).
  final Duration timeout;
  late final StreamSubscription<List<PurchaseDetails>> _sub;
  final Map<String, ProductDetails> _details = {};
  Completer<TipOutcome>? _pending;

  @override
  Future<List<TipProduct>> products() async {
    try {
      if (!await _iap.isAvailable().timeout(timeout)) return const [];
      final resp = await _iap.queryProductDetails(kTipProductIds.toSet()).timeout(timeout);
      for (final d in resp.productDetails) {
        _details[d.id] = d;
      }
      return [
        for (final id in kTipProductIds)
          if (_details[id] != null) TipProduct(id: id, price: _details[id]!.price),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<TipOutcome> tip(String productId) async {
    final d = _details[productId];
    if (d == null) return TipOutcome.failed;
    // Un paiement précédent resté sans réponse (feuille fermée en cours de route) ne bloque jamais les
    // suivants : il est clos ici. S'il aboutit plus tard, l'écoute permanente le finalise quand même.
    _settle(TipOutcome.cancelled);
    final c = _pending = Completer<TipOutcome>();
    try {
      final started = await _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: d));
      if (!started) _settle(TipOutcome.failed);
    } catch (_) {
      _settle(TipOutcome.failed);
    }
    return c.future;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (!kTipProductIds.contains(p.productID)) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _settle(TipOutcome.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _settle(TipOutcome.thanks);
        case PurchaseStatus.canceled:
          _settle(TipOutcome.cancelled);
        case PurchaseStatus.error:
          _settle(TipOutcome.failed);
      }
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (e) {
          debugPrint('tip complete failed'); // aucun identifiant ni montant journalisé
        }
      }
    }
  }

  void _settle(TipOutcome o) {
    final c = _pending;
    _pending = null;
    if (c != null && !c.isCompleted) c.complete(o);
  }

  void dispose() => _sub.cancel();
}
