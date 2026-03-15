import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _introText(),
                      const SizedBox(height: 16),
                      ...plans.map((plan) => _planCard(plan)).toList(),
                      const SizedBox(height: 20),
                      _footer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Upgrade to Premium",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          InkWell(
            onTap: onClose,
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xffeeeeee),
              child: Icon(Icons.close, size: 18, color: Colors.black),
            ),
          )
        ],
      ),
    );
  }

  Widget _introText() {
    return const Text(
      "Get unlimited access to advanced features and take your riding to the next level.",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey,
      ),
    );
  }

  Widget _planCard(SubscriptionPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: plan.popular ? Colors.blue : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(18),
        color: plan.popular ? Colors.blue.withOpacity(.05) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    plan.period,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  )
                ],
              ),
              if (plan.popular)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
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
                )
            ],
          ),

          const SizedBox(height: 12),

          /// Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.price,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              if (plan.originalPrice != null)
                Text(
                  plan.originalPrice!,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                )
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
                        const Icon(Icons.check_circle,
                            size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 13),
                          ),
                        )
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 12),

          /// Subscribe button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    plan.popular ? Colors.blue : Colors.grey.shade200,
                foregroundColor:
                    plan.popular ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {},
              child: const Text("Subscribe Now"),
            ),
          )
        ],
      ),
    );
  }

  Widget _footer() {
    return Column(
      children: const [
        Text(
          "Cancel anytime. No questions asked.",
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        SizedBox(height: 4),
        Text(
          "All plans include access to core riding features",
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}