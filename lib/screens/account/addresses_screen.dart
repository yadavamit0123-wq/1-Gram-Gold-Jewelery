import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state_widget.dart';
import '../auth/login_screen.dart';

class AddressesScreen extends StatefulWidget {
  final bool isSelecting;

  const AddressesScreen({super.key, this.isSelecting = false});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isLoggedIn) {
        Provider.of<OrderProvider>(context, listen: false).loadAddresses();
      }
    });
  }

  void _showAddressDialog({AddressModel? existingAddress}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existingAddress?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: existingAddress?.phone ?? '');
    final line1Ctrl = TextEditingController(text: existingAddress?.addressLine1 ?? '');
    final line2Ctrl = TextEditingController(text: existingAddress?.addressLine2 ?? '');
    final cityCtrl = TextEditingController(text: existingAddress?.city ?? '');
    final stateCtrl = TextEditingController(text: existingAddress?.state ?? '');
    final pinCtrl = TextEditingController(text: existingAddress?.postalCode ?? '');
    bool isDefault = existingAddress?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existingAddress == null ? 'Add Delivery Address' : 'Edit Address',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Full Name
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),

                      // Phone
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: '10-Digit Mobile Number *'),
                        validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid phone' : null,
                      ),
                      const SizedBox(height: 10),

                      // Address Line 1
                      TextFormField(
                        controller: line1Ctrl,
                        decoration: const InputDecoration(labelText: 'House / Flat / Street *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),

                      // Address Line 2
                      TextFormField(
                        controller: line2Ctrl,
                        decoration: const InputDecoration(labelText: 'Landmark / Colony (Optional)'),
                      ),
                      const SizedBox(height: 10),

                      // City & State Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cityCtrl,
                              decoration: const InputDecoration(labelText: 'City *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: stateCtrl,
                              decoration: const InputDecoration(labelText: 'State *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // PIN Code
                      TextFormField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(labelText: 'PIN Code *', counterText: ''),
                        validator: (v) => v == null || v.trim().length != 6 ? 'Enter 6-digit PIN' : null,
                      ),
                      const SizedBox(height: 10),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Set as default delivery address', style: TextStyle(fontSize: 13)),
                        value: isDefault,
                        activeColor: AppColors.gold,
                        onChanged: (val) => setSheetState(() => isDefault = val ?? false),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final orderProvider = Provider.of<OrderProvider>(context, listen: false);

                            final newAddr = AddressModel(
                              id: existingAddress?.id ?? 0,
                              fullName: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              addressLine1: line1Ctrl.text.trim(),
                              addressLine2: line2Ctrl.text.trim(),
                              city: cityCtrl.text.trim(),
                              state: stateCtrl.text.trim(),
                              postalCode: pinCtrl.text.trim(),
                              isDefault: isDefault,
                            );

                            final nav = Navigator.of(context);
                            final ok = await orderProvider.saveAddress(newAddr);
                            if (!context.mounted) return;
                            if (ok) {
                              nav.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Delivery address saved')),
                              );
                            } else {
                              final msg = orderProvider.addressError ?? 'Could not save address. Please try again.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          },
                          child: const Text('Save Address'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Addresses')),
        body: EmptyStateWidget(
          icon: Icons.lock_outline,
          title: 'Sign In Required',
          description: 'Please sign in to manage your delivery addresses.',
          buttonText: 'Sign In Now',
          onButtonPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      );
    }

    final addresses = orderProvider.addresses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddressDialog(),
          ),
        ],
      ),
      body: orderProvider.isLoadingAddresses
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : addresses.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.location_on_outlined,
                  title: 'No Saved Addresses',
                  description: 'Add your shipping address for fast express checkout.',
                  buttonText: 'Add New Address',
                  onButtonPressed: () => _showAddressDialog(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final addr = addresses[index];
                    final isSelected = orderProvider.selectedAddress?.id == addr.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected && widget.isSelecting ? AppColors.gold : AppColors.borderLight,
                          width: isSelected && widget.isSelecting ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                addr.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              if (addr.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      color: AppColors.goldDark,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addr.phone,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            addr.formattedAddress,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.borderLight),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (widget.isSelecting)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? AppColors.primary : AppColors.gold,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    orderProvider.selectAddress(addr);
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    isSelected ? 'Selected' : 'Deliver Here',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => _showAddressDialog(existingAddress: addr),
                                    child: const Text('Edit', style: TextStyle(color: AppColors.goldDark)),
                                  ),
                                  TextButton(
                                    onPressed: () => orderProvider.deleteAddress(addr.id),
                                    child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
