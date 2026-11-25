import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Menampilkan sheet paket StreakWok Pro dengan alur konfirmasi UC-03:
/// Pilih paket -> Konfirmasi Upgrade -> Sukses / Batal / Exception ("Upgrade dibatalkan").
Future<void> showUpgradeProBottomSheet({
  required BuildContext context,
  required VoidCallback onUpgradeConfirmed,
  Future<bool> Function(String planLabel)? onProcessPayment,
}) {
  int selectedPlanIndex = 1; // 0 = Monthly, 1 = Yearly

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (modalContext, setModalState) {
        final String planTitle = selectedPlanIndex == 0 ? 'Monthly' : 'Yearly';
        final String planPrice = selectedPlanIndex == 0 ? 'Rp 29.000' : 'Rp 199.000';
        final String planPeriod = selectedPlanIndex == 0 ? '/ month' : '/ year';

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFF9800),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'StreakWok Pro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1D1E),
                          ),
                        ),
                        Text(
                          'Never lose your group streak again',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBenefitRow(
                Icons.replay_rounded,
                '5 Streak Restores per Month',
                'Extra chances to keep your group streak alive',
              ),
              _buildBenefitRow(
                Icons.groups_rounded,
                '10 Members Group Capacity',
                'Workout with your entire squad',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPlanCard(
                      title: 'Monthly',
                      price: 'Rp 29.000',
                      period: '/ month',
                      isSelected: selectedPlanIndex == 0,
                      onTap: () => setModalState(() => selectedPlanIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPlanCard(
                      title: 'Yearly',
                      price: 'Rp 199.000',
                      period: '/ year',
                      badge: 'Save 40%',
                      isSelected: selectedPlanIndex == 1,
                      onTap: () => setModalState(() => selectedPlanIndex = 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const Key('proceed_upgrade_pro_btn'),
                  onPressed: () async {
                    final bool? confirmed = await showDialog<bool>(
                      context: sheetContext,
                      builder: (dialogContext) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text(
                          'Confirm Upgrade',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D1E),
                          ),
                        ),
                        content: Text(
                          'Activate StreakWok Pro ($planTitle • $planPrice $planPeriod)?',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        actions: [
                          TextButton(
                            key: const Key('cancel_upgrade_payment_btn'),
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            key: const Key('confirm_upgrade_pro_btn'),
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D09E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Confirm Payment',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );

                    // Alternative Flow: pengguna membatalkan konfirmasi -> kembali ke sheet paket.
                    if (confirmed != true) return;

                    bool paymentSucceeded = true;
                    if (onProcessPayment != null) {
                      try {
                        paymentSucceeded = await onProcessPayment(planTitle);
                      } catch (_) {
                        paymentSucceeded = false;
                      }
                    }

                    if (!sheetContext.mounted || !context.mounted) return;
                    Navigator.of(sheetContext).pop();

                    if (!paymentSucceeded) {
                      // Exception Flow (SDD UC-03): Transaksi terputus -> "Upgrade dibatalkan"
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Upgrade dibatalkan'),
                            duration: Duration(seconds: 3),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      return;
                    }

                    onUpgradeConfirmed();
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Upgraded to StreakWok Pro! 5 restores per month & 10-member capacity unlocked.',
                          ),
                          duration: Duration(seconds: 3),
                          backgroundColor: Color(0xFF1A1D1E),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D09E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(sheetContext).pop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
    ),
  );
}

Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8FDF5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF00A87A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D1E),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildPlanCard({
  required String title,
  required String price,
  required String period,
  String? badge,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8FDF5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF00D09E) : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF00A87A) : const Color(0xFF4B5563),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1D1E),
            ),
          ),
          Text(
            period,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    ),
  );
}
