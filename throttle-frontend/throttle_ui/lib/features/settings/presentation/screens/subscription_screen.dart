import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final String period;
  final String price;
  final String? originalPrice;
  final List<String> features;
  final bool popular;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.period,
    required this.price,
    this.originalPrice,
    required this.features,
    this.popular = false,
  });
}

class SubscriptionScreen extends StatelessWidget {
  final VoidCallback onClose;

  SubscriptionScreen({super.key, required this.onClose});

  final List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'monthly',
      name: 'Monthly',
      period: 'per month',
      price: '\$9.99',
      features: [
        'Advanced ride analytics',
        'Group management tools',
        'Custom leaderboards',
        'Priority support',
        'Export ride data',
      ],
    ),
    SubscriptionPlan(
      id: 'quarterly',
      name: 'Quarterly',
      period: 'per 3 months',
      price: '\$24.99',
      originalPrice: '\$29.97',
      popular: true,
      features: [
        'All Monthly features',
        'Unlimited custom routes',
        'Team collaboration tools',
        'Advanced notifications',
        'Early access to new features',
        'Badge customization',
      ],
    ),
    SubscriptionPlan(
      id: 'yearly',
      name: 'Yearly',
      period: 'per year',
      price: '\$79.99',
      originalPrice: '\$119.88',
      features: [
        'All Quarterly features',
        'Lifetime ride history',
        'VIP club access',
        'Dedicated account manager',
        '24/7 premium support',
        'Exclusive rewards program',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
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
                          ...plans
                              .map((plan) => _planCard(plan, theme))
                              .toList(),
                          const SizedBox(height: 20),
                          _footer(theme),
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
            "Upgrade to Premium",
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
      "Get unlimited access to advanced features and take your riding to the next level.",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: theme.textPrimary.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _planCard(SubscriptionPlan plan, AppThemeConfig theme) {
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
                plan.price,
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (plan.originalPrice != null)
                Text(
                  plan.originalPrice!,
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
              child: Text("Subscribe Now", style: GoogleFonts.lexend()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(AppThemeConfig theme) {
    final style = TextStyle(
      fontSize: 11,
      color: theme.textPrimary.withValues(alpha: 0.6),
    );
    return Column(
      children: [
        Text("Cancel anytime. No questions asked.", style: style),
        const SizedBox(height: 4),
        Text("All plans include access to core riding features", style: style),
      ],
    );
  }
}
