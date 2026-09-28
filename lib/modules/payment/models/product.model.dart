// lib/modules/payment/models/product.model.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rexone_mobile/constants/constants.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String price;
  final int unitAmount;
  final String currency;
  final String? interval;
  final String periodLabel;
  final bool recurring;
  final bool active;
  final bool free;
  final String? stripeProductId;
  final String? stripePriceId;
  final String? googlePlayProductId;
  final String? appStoreProductId;
  final List<String> supportedProviders;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unitAmount,
    required this.currency,
    this.interval,
    required this.periodLabel,
    required this.recurring,
    required this.active,
    this.free = false,
    this.stripeProductId,
    this.stripePriceId,
    this.googlePlayProductId,
    this.appStoreProductId,
    this.supportedProviders = const [],
  });

  bool get isFree => free || unitAmount == 0;

  /// Returns the native platform in-app store SKU:
  /// Google Play Product ID on Android, App Store Product ID on iOS/macOS.
  String? get storeId {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return googlePlayProductId;
    if (Platform.isIOS || Platform.isMacOS) return appStoreProductId;
    return null;
  }

  /// Whether this product is available for native in-app purchase on the current running device.
  bool get isInApp => storeId != null && storeId!.isNotEmpty;

  /// Whether this product supports web / card checkout via Stripe.
  bool get supportsStripe => stripePriceId != null && stripePriceId!.isNotEmpty;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final amount = json[PaymentKeys.unitAmount] is int
        ? json[PaymentKeys.unitAmount] as int
        : int.tryParse(
                json[PaymentKeys.unitAmount]?.toString() ?? '0',
              ) ??
              0;

    final providersRaw = json[PaymentKeys.supportedProviders];
    final providersList = providersRaw is List
        ? providersRaw.map((e) => e.toString()).toList()
        : <String>[];

    return ProductModel(
      id: json[ApiKeys.id]?.toString() ?? '',
      name: json[PaymentKeys.name]?.toString() ?? '',
      description: json[PaymentKeys.description]?.toString() ?? '',
      price: json[PaymentKeys.price]?.toString() ?? (amount == 0 ? 'Free' : '\$0.00'),
      unitAmount: amount,
      currency: json[PaymentKeys.currency]?.toString() ?? 'usd',
      interval: json[PaymentKeys.interval]?.toString(),
      periodLabel: json[PaymentKeys.periodLabel]?.toString() ?? '',
      recurring: json[PaymentKeys.recurring] == true,
      active: json[PaymentKeys.active] != false,
      free: json[PaymentKeys.free] == true || amount == 0,
      stripeProductId: json[PaymentKeys.stripeProductId]?.toString(),
      stripePriceId: json[PaymentKeys.stripePriceId]?.toString(),
      googlePlayProductId: json[PaymentKeys.googlePlayProductId]?.toString(),
      appStoreProductId: json[PaymentKeys.appStoreProductId]?.toString(),
      supportedProviders: providersList,
    );
  }

  Map<String, dynamic> toJson() => {
    ApiKeys.id: id,
    PaymentKeys.name: name,
    PaymentKeys.description: description,
    PaymentKeys.price: price,
    PaymentKeys.unitAmount: unitAmount,
    PaymentKeys.currency: currency,
    PaymentKeys.interval: interval,
    PaymentKeys.periodLabel: periodLabel,
    PaymentKeys.recurring: recurring,
    PaymentKeys.active: active,
    PaymentKeys.free: isFree,
    if (stripeProductId != null)
      PaymentKeys.stripeProductId: stripeProductId,
    if (stripePriceId != null)
      PaymentKeys.stripePriceId: stripePriceId,
    if (googlePlayProductId != null)
      PaymentKeys.googlePlayProductId: googlePlayProductId,
    if (appStoreProductId != null)
      PaymentKeys.appStoreProductId: appStoreProductId,
    if (supportedProviders.isNotEmpty)
      PaymentKeys.supportedProviders: supportedProviders,
  };
}
