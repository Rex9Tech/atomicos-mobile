// lib/modules/payment/pages/payment_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/helpers.dart';

import '../payment.dart';

class PaymentPage extends GetView<PaymentController> {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppLocales.payment.plansPricing.tr,
      showBackButton: true,
      padding: Design.spacing.zero,
      child: Obx(() {
        final filterChips = [
          const AppSearchChipItem(
            id: PaymentController.filterAll,
            label: 'All Plans',
          ),
          const AppSearchChipItem(
            id: PaymentController.filterSubscription,
            label: 'Subscriptions',
            icon: Icons.repeat_rounded,
          ),
          const AppSearchChipItem(
            id: PaymentController.filterOneTime,
            label: 'One-Time',
            icon: Icons.flash_on_rounded,
          ),
        ];

        final searchHeader = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              AppLocales.payment.choosePlan.tr,
              style: context.typo.headline1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Design.spacing.xs),
            Text(
              AppLocales.payment.choosePlanSub.tr,
              style: context.typo.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Design.spacing.lg),

            // Search and Filter Bar
            AppSearchBar(
              hint: 'Search plans...',
              initialQuery: controller.searchQuery.value,
              onSearchChanged: controller.onSearchChanged,
              isSearching:
                  controller.isLoading.value && controller.items.isNotEmpty,
              filterChips: filterChips,
              selectedFilterId: controller.selectedFilterId,
              onFilterSelected: controller.selectFilterId,
            ),
          ],
        );

        return AppPagyListView<ProductModel>(
          items: controller.products,
          isLoading: controller.isLoading.value,
          isLoadingMore: controller.isLoadingMore.value,
          hasMore: controller.hasMore,
          errorMessage: controller.errorMessage.value,
          onRefresh: controller.fetchData,
          onLoadMore: controller.loadMore,
          header: searchHeader,
          emptyMessage:
              'No products available matching your search or filters.',
          itemBuilder: (context, product, index) {
            final isLast = index == controller.products.length - 1;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProductCard(context, controller, product),
                if (isLast && controller.purchases.isNotEmpty) ...[
                  SizedBox(height: Design.spacing.xxxl),
                  Text(
                    AppLocales.payment.purchases.tr,
                    style: context.typo.headline3,
                  ),
                  SizedBox(height: Design.spacing.md),
                  ...controller.purchases.map(
                    (p) => _buildPurchaseTile(context, p),
                  ),
                  SizedBox(height: Design.spacing.xxl),
                ],
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    PaymentController controller,
    ProductModel product,
  ) {
    final isFree = product.isFree;
    final hasAccess = controller.hasActiveAccess(product.id);
    final activeSub = controller.getActiveSubscription(product.id);
    final canceledSub = controller.getCanceledSubscription(product.id);
    final fullyCanceledSub = controller.getFullyCanceledSubscription(
      product.id,
    );
    final purchaseCount = controller.getPurchaseCount(product.id);

    return AppCard(
      margin: EdgeInsets.only(bottom: Design.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(product.name, style: context.typo.headline3),
              ),
              if (isFree && hasAccess)
                AppBadge(
                  text: AppLocales.payment.claimed.tr,
                  type: BadgeType.success,
                  icon: Design.icons.activeSubscription,
                )
              else if (!product.recurring && hasAccess)
                AppBadge(
                  text: AppLocales.payment.active.tr,
                  type: BadgeType.success,
                  icon: Design.icons.activeSubscription,
                )
              else if (activeSub != null)
                AppBadge(
                  text: AppLocales.payment.active.tr,
                  type: BadgeType.success,
                  icon: Design.icons.activeSubscription,
                )
              else if (canceledSub != null)
                AppBadge(
                  text: AppLocales.payment.expiring.tr,
                  type: BadgeType.warning,
                  icon: Design.icons.scheduledCancel,
                )
              else if (fullyCanceledSub != null)
                AppBadge(
                  text: AppLocales.payment.ended.tr,
                  type: BadgeType.error,
                  icon: Design.icons.canceledSubscription,
                ),
            ],
          ),
          SizedBox(height: Design.spacing.xs),
          Text(product.description, style: context.typo.bodyMedium),
          SizedBox(height: Design.spacing.lg),

          // Pricing
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                product.price,
                style: context.typo.headline1.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: Design.spacing.xs),
              Text(
                product.recurring ? '/ ${product.periodLabel}' : ' (one-time)',
                style: context.typo.bodySmall,
              ),
            ],
          ),
          SizedBox(height: Design.spacing.xl),

          // Actions
          _buildActionButtons(
            context,
            controller,
            product,
            isFree,
            hasAccess,
            activeSub,
            canceledSub,
            fullyCanceledSub,
            purchaseCount,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    PaymentController controller,
    ProductModel product,
    bool isFree,
    bool hasAccess,
    SubscriptionModel? activeSub,
    SubscriptionModel? canceledSub,
    SubscriptionModel? fullyCanceledSub,
    int purchaseCount,
  ) {
    // 1. Free Product Flow
    if (isFree) {
      if (hasAccess) {
        return AppButton(
          type: EButtonType.secondary,
          text: AppLocales.payment.claimed.tr,
          onPressed: null,
        );
      }

      return AppButton(
        text: AppLocales.payment.claimNow.tr,
        onPressed: () => controller.startCheckout(product.id),
      );
    }

    // 2. Active subscription -> Cancel button
    if (activeSub != null) {
      final periodEnd = activeSub.currentPeriodEnd != null
          ? AppDateTime.formatLocalDate(activeSub.currentPeriodEnd)
          : 'end of period';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocales.payment.renewsOn.trParams({'date': periodEnd}),
            style: context.typo.caption,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Design.spacing.md),
          AppButton(
            type: EButtonType.secondary,
            text: AppLocales.payment.cancelSubscription.tr,
            onPressed: () async {
              final ok = await AppDialog.confirm(
                context: context,
                title: AppLocales.setting.cancelSubTitle.tr,
                message: AppLocales.setting.cancelSubConfirmMsg.tr,
                confirmLabel: AppLocales.setting.cancelSubTitle.tr,
                destructive: true,
              );
              if (ok) controller.cancelSubscription(activeSub.id);
            },
          ),
        ],
      );
    }

    // 3. Canceled (pending end of cycle) -> Resume button
    if (canceledSub != null) {
      final periodEnd = canceledSub.currentPeriodEnd != null
          ? AppDateTime.formatLocalDate(canceledSub.currentPeriodEnd)
          : 'end of period';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocales.payment.accessUntil.trParams({'date': periodEnd}),
            style: context.typo.caption.copyWith(
              color: Design.colors.warning,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Design.spacing.md),
          AppButton(
            type: EButtonType.secondary,
            text: AppLocales.payment.resumeSubscription.tr,
            onPressed: () => controller.resumeSubscription(canceledSub.id),
          ),
        ],
      );
    }

    // 4. Fully canceled / ended -> Subscribe again
    if (fullyCanceledSub != null) {
      return AppButton(
        text: AppLocales.payment.subscribeAgain.tr,
        onPressed: () => controller.startCheckout(product.id),
      );
    }

    // 5. One-time purchase product with active access
    if (!product.recurring && hasAccess) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            text: AppLocales.payment.buyAgain.tr,
            onPressed: () => controller.startCheckout(product.id),
          ),
          if (purchaseCount > 0) ...[
            SizedBox(height: Design.spacing.xs),
            Text(
              purchaseCount > 1
                  ? AppLocales.payment.purchasedTimes
                      .trParams({'count': '$purchaseCount'})
                  : AppLocales.payment.purchasedOnce.tr,
              style: context.typo.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    // 6. One-time purchase product previously purchased
    if (!product.recurring && purchaseCount > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            text: AppLocales.payment.buyAgain.tr,
            onPressed: () => controller.startCheckout(product.id),
          ),
          SizedBox(height: Design.spacing.xs),
          Text(
            purchaseCount > 1
                  ? AppLocales.payment.purchasedTimes
                      .trParams({'count': '$purchaseCount'})
                  : AppLocales.payment.purchasedOnce.tr,
            style: context.typo.caption,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // 7. Default Subscribe / Buy button
    return AppButton(
      text: product.recurring ? AppLocales.payment.subscribeNow.tr : AppLocales.payment.buyNow.tr,
      onPressed: () => controller.startCheckout(product.id),
    );
  }

  Widget _buildPurchaseTile(BuildContext context, PurchaseModel p) {
    return AppCard(
      margin: EdgeInsets.only(bottom: Design.spacing.sm),
      padding: EdgeInsets.symmetric(
        horizontal: Design.spacing.md,
        vertical: Design.spacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.productName ?? AppLocales.payment.paymentLabel.tr, style: context.typo.bodyLarge),
              if (p.createdAt != null)
                Text(
                  AppDateTime.formatLocalDate(p.createdAt),
                  style: context.typo.caption,
                ),
            ],
          ),
          AppBadge(
            text: p.paid ? AppLocales.payment.paid.tr : p.status,
            type: p.paid ? BadgeType.success : BadgeType.warning,
          ),
        ],
      ),
    );
  }
}
