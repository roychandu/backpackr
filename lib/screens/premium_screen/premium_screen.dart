// ignore_for_file: unnecessary_to_list_in_spreads, deprecated_member_use

import 'package:backpackr/provider/purchase_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/app_config_service.dart';
import '../../common_widgets/app_colors.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool isLoading = false;
  final AppConfigService _configService = AppConfigService();

  @override
  Widget build(BuildContext context) {
    return Consumer<InAppPurchaseProvider>(
      builder: (context, inAppPurchaseProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Professional Header
                _buildProfessionalHeader(inAppPurchaseProvider),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Value Proposition
                        _buildValueProposition(),

                        const SizedBox(height: 32),

                        // Pricing Section
                        _buildPricingSection(),

                        const SizedBox(height: 32),

                        // Plans Comparison
                        _buildPlansComparison(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Bottom CTA
                _buildBottomCTA(inAppPurchaseProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalHeader(InAppPurchaseProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background2.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: AppColors.text2.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.text1,
                size: 18,
              ),
            ),
          ),
          SizedBox(width: 16),
          Text(
            'Premium Membership',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text1,
            ),
          ),
          Spacer(),
          if (provider.isPremiumMember)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cta1, AppColors.cta2],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ACTIVE',
                style: TextStyle(
                  color: AppColors.text1,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildValueProposition() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cta1.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.cta1.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'UNLOCK UNLIMITED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.cta1,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Everything You Need,\nUnlimited Access',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.text1,
            height: 1.2,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Join thousands of premium members enjoying unlimited features',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.text2.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cta1, AppColors.cta2],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cta1.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text1,
                  ),
                ),
              ),
              Text(
                '0.99',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text1,
                  height: 0.9,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPriceFeature(Icons.payments, 'One-time\nPayment'),
              Container(
                width: 1,
                height: 40,
                color: AppColors.text1.withOpacity(0.3),
              ),
              _buildPriceFeature(Icons.all_inclusive, 'Lifetime\nAccess'),
              Container(
                width: 1,
                height: 40,
                color: AppColors.text1.withOpacity(0.3),
              ),
              _buildPriceFeature(Icons.cancel, 'No\nSubscription'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFeature(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.text1, size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.text1,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPlansComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features Comparison',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.text1,
          ),
        ),
        const SizedBox(height: 20),

        // Free Plan Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background2.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.text2.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.text2.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.text2,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Free Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._configService.getAllFreePlanFeatures().map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: AppColors.text2, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.text2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Premium Plan Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cta1.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cta1.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.cta1, AppColors.cta2],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      color: AppColors.text1,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Premium Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.cta1, AppColors.cta2],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text1,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._configService.getAllPremiumPlanFeatures().map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.cta1,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.text1,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrustIndicators() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background2.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrustItem(Icons.lock, 'Secure\nPayment'),
              _buildTrustItem(Icons.verified_user, 'Trusted by\nThousands'),
              _buildTrustItem(Icons.support_agent, '24/7\nSupport'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.cta1, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text2,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCTA(InAppPurchaseProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.text2.withOpacity(0.1), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.text3.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.isPremiumMember)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cta1.withOpacity(0.15),
                    AppColors.cta2.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.cta1.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.cta1, AppColors.cta2],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified,
                      color: AppColors.text1,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Member',
                          style: TextStyle(
                            color: AppColors.text1,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All features unlocked',
                          style: TextStyle(
                            color: AppColors.text2,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (!provider.isPremiumMember) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        provider.buyNONConsumableInAppPurchase();
                        // _handleUpgrade();
                        setState(() => isLoading = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.cta1, AppColors.cta2],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.text1,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Get Premium for \$0.99',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text1,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    setState(() => isLoading = true);
                    provider.restorePurchases();
                    setState(() => isLoading = false);
                  },
            child: Text(
              'Restore Purchases',
              style: TextStyle(
                color: AppColors.text2,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpgrade() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(seconds: 2));
      await AuthService().updatePremiumStatus(true);

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.background2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: AppColors.cta1, size: 28),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Premium Activated!',
                  style: TextStyle(
                    color: AppColors.text1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Congratulations! You now have unlimited access.',
            style: TextStyle(color: AppColors.text2),
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final provider = Provider.of<InAppPurchaseProvider>(
                    context,
                    listen: false,
                  );
                  provider.isPremiumMember = true;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.background2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Upgrade Failed',
            style: TextStyle(
              color: AppColors.text1,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Failed to activate: $e',
            style: TextStyle(color: AppColors.text2),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.cta1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
