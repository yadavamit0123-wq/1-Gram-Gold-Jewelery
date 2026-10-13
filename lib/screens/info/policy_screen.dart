import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Store Policies & Trademark'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Trademark Pill Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: AppColors.goldLight, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Class 14 Registered Trademark',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    AppConstants.trademarkNotice,
                    style: TextStyle(
                      color: AppColors.borderLight,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Authenticity & Quality Guarantee
            _buildPolicyCard(
              icon: Icons.workspace_premium,
              title: '100% Quality & Authenticity Guarantee',
              content:
                  'Every item is crafted with genuine 24 Karat gold micro-plating on premium copper and brass alloys. '
                  'Our imitation jewellery undergoes multi-layer testing for anti-tarnish longevity and skin safety.',
            ),
            const SizedBox(height: 12),

            // Shipping & Delivery Policy
            _buildPolicyCard(
              icon: Icons.local_shipping_outlined,
              title: 'Express Shipping & Delivery',
              content:
                  'We offer FREE express courier delivery across India for all orders above ₹${AppConstants.freeShippingThreshold.toInt()}. '
                  'Orders below ₹${AppConstants.freeShippingThreshold.toInt()} carry a flat fee of ₹${AppConstants.standardShippingFee.toInt()}. '
                  'Dispatch takes place within 24 hours in tamper-evident secured parcel boxes.',
            ),
            const SizedBox(height: 12),

            // Returns & Exchange Policy
            _buildPolicyCard(
              icon: Icons.replay_circle_filled,
              title: '7-Day Return & Replacement Policy',
              content:
                  'If you receive a defective, damaged, or incorrect piece, initiate a replacement within 7 calendar days. '
                  'Our courier partner will pick up the parcel from your doorstep without extra charges.',
            ),
            const SizedBox(height: 12),

            // Privacy Policy & User Data Protection (Google Play Mandatory)
            _buildPolicyCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy & User Data Protection',
              content:
                  'We collect only necessary information (Name, Email, Phone, Shipping Address) solely for fulfilling orders, '
                  'courier dispatch, and customer assistance. We never store payment card credentials.\n\n'
                  'You have the full right to delete your account and personal data anytime under My Account -> Delete Account '
                  'or through our online data deletion portal.',
            ),
            const SizedBox(height: 12),

            // Terms of Service
            _buildPolicyCard(
              icon: Icons.gavel_outlined,
              title: 'Terms & Conditions of Service',
              content:
                  'All products are manufactured under Class 14 registered trademark standards with 24K micron gold electroplating '
                  'over copper and brass base alloys. All prices include 3% GST. Transactions are governed by Indian commercial laws.',
            ),
            const SizedBox(height: 12),

            // Customer Support
            _buildPolicyCard(
              icon: Icons.support_agent,
              title: 'Customer Care & Grievances',
              content:
                  'Email: ${AppConstants.supportEmail}\n'
                  'Helpline: ${AppConstants.supportPhone} (Mon–Sat, 10 AM – 7 PM IST)\n'
                  'Address: ${AppConstants.storeAddress}',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.goldDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
