import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/resources/frontend_resource_config.dart';

class SubscriptionScreen extends StatelessWidget {
  final VoidCallback onClose;
  final String? title;
  final String? description;

  const SubscriptionScreen({
    super.key,
    required this.onClose,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeController.instance,
        FrontendResourceConfig.instance,
      ]),
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        final resource = FrontendResourceConfig.instance.subscriptions;
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(theme),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _introText(theme),
                          const SizedBox(height: 16),
                          ...resource.plans.map(
                            (plan) => _planCard(plan, theme, resource),
                          ),
                          const SizedBox(height: 20),
                          _footer(theme, resource),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.textPrimary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title ?? FrontendResourceConfig.instance.subscriptions.title,
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          InkWell(
            onTap: onClose,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.surface,
              child: Icon(Icons.close, size: 18, color: theme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _introText(AppThemeConfig theme) {
    return Text(
      description ?? FrontendResourceConfig.instance.subscriptions.description,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: theme.textPrimary.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _planCard(
    SubscriptionPlanResource plan,
    AppThemeConfig theme,
    FrontendSubscriptionResourceConfig resource,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: plan.popular
              ? theme.primary
              : const Color(0x52B8C6DA).withValues(alpha: 0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(18),
        color: plan.popular
            ? theme.primary.withValues(alpha: 0.05)
            : theme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    plan.period,
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (plan.popular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Popular",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          /// Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                resource.formatPrice(plan.priceInr),
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (plan.originalPriceInr != null)
                Text(
                  resource.formatPrice(plan.originalPriceInr!),
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.4),
                    decoration: TextDecoration.lineThrough,
                    fontSize: 14,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          /// Features
          Column(
            children: plan.features
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: theme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.popular
                    ? theme.primary
                    : theme.textPrimary.withValues(alpha: 0.05),
                foregroundColor: plan.popular
                    ? Colors.white
                    : theme.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {},
              child: Text(plan.ctaLabel, style: GoogleFonts.lexend()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(
    AppThemeConfig theme,
    FrontendSubscriptionResourceConfig resource,
  ) {
    final style = TextStyle(
      fontSize: 11,
      color: theme.textPrimary.withValues(alpha: 0.6),
    );
    return Column(
      children: [
        Text(resource.cancelAnytimeText, style: style),
        const SizedBox(height: 4),
        Text(resource.allPlansIncludeText, style: style),
      ],
    );
  }
}
