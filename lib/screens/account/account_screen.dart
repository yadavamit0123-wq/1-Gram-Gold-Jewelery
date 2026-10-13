import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../info/policy_screen.dart';
import '../orders/orders_screen.dart';
import 'addresses_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Account'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Header Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: AppColors.primary,
              child: authProvider.isLoggedIn && user != null
                  ? Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.gold,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: const TextStyle(color: AppColors.goldLight, fontSize: 13),
                              ),
                              if (user.phone != null && user.phone!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user.phone!,
                                  style: const TextStyle(color: AppColors.borderLight, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome to 1 Gram Gold',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sign in to access orders, saved addresses and personalized offers',
                          style: TextStyle(color: AppColors.goldLight, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              child: const Text('Sign In'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              child: const Text('Register'),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // Main Menu Options
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Orders',
                    subtitle: 'Track current shipments & view past purchases',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrdersScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Saved Addresses',
                    subtitle: 'Manage home, work and gift delivery addresses',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddressesScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  _buildMenuItem(
                    icon: Icons.verified_outlined,
                    title: 'Store Policies & Class 14 Trademark',
                    subtitle: 'Authenticity guarantee, shipping & return policies',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PolicyScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy & Data Rights',
                    subtitle: 'Data protection, user rights & Google Play compliance',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PolicyScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  _buildMenuItem(
                    icon: Icons.support_agent_outlined,
                    title: 'Customer Care & Help Desk',
                    subtitle: AppConstants.supportEmail,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Customer Helpline'),
                          content: const Text(
                            'Need assistance with your jewellery order or sizing?\n\n'
                            'Helpline: ${AppConstants.supportPhone}\n'
                            'Email: ${AppConstants.supportEmail}\n'
                            'Store Address: ${AppConstants.storeAddress}\n'
                            'Working hours: Mon-Sat, 10 AM to 7 PM',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Logout & Delete Account Options (Only when logged in)
            if (authProvider.isLoggedIn) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to log out from this device?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () async {
                              final cart = Provider.of<CartProvider>(context, listen: false);
                              final wishlist = Provider.of<WishlistProvider>(context, listen: false);
                              Navigator.pop(ctx);
                              await authProvider.logout();
                              cart.loadCart();
                              wishlist.loadWishlist();
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Delete Account (Google Play Store User Data Compliance)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                  title: const Text(
                    'Delete Account & Personal Data',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Permanently remove your account and stored data',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Account?'),
                          ],
                        ),
                        content: const Text(
                          'Are you sure you want to permanently delete your 1 Gram Gold Jewellery account?\n\n'
                          '• Your personal profile, saved addresses and wishlists will be deleted.\n'
                          '• This action is permanent and cannot be undone.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              final cart = Provider.of<CartProvider>(context, listen: false);
                              final wishlist = Provider.of<WishlistProvider>(context, listen: false);
                              Navigator.pop(ctx);
                              final scaffold = ScaffoldMessenger.of(context);
                              final ok = await authProvider.deleteAccount();
                              if (ok) {
                                cart.loadCart();
                                wishlist.loadWishlist();
                                scaffold.showSnackBar(
                                  const SnackBar(
                                    content: Text('Your account and personal data have been deleted.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                scaffold.showSnackBar(
                                  SnackBar(
                                    content: Text(authProvider.errorMessage ?? 'Failed to delete account'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                            child: const Text('Permanently Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // App Version & Class 14 Trademark Pill
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    '${AppConstants.appName} v1.0.0',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Protected under Class 14 Registered Trademark',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.goldDark, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
