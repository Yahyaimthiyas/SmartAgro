import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'farmer_orders_screen.dart';

class FarmerOrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final num totalAmount;
  final bool needsDosageAdvice;

  const FarmerOrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    this.needsDosageAdvice = false,
  });

  @override
  State<FarmerOrderSuccessScreen> createState() =>
      _FarmerOrderSuccessScreenState();
}

class _FarmerOrderSuccessScreenState extends State<FarmerOrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    // Auto-redirect to Orders Screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FarmerOrdersScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 80,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.needsDosageAdvice
                  ? (LocalizationService.isTamil ? 'அளவு ஆலோசனை அனுப்பப்பட்டது!' : 'Dosage Advice Sent!')
                  : LocalizationService.tr('title_order_success_ta'),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansTamil(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.needsDosageAdvice
                  ? (LocalizationService.isTamil ? 'உங்கள் கோரிக்கை நிபுணருக்கு அனுப்பப்பட்டுள்ளது.' : 'Your request has been sent to our expert.')
                  : LocalizationService.tr('title_order_success_en'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Ticket-like info
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          LocalizationService.tr('label_order_id'),
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          widget.orderId,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          LocalizationService.tr('label_total_amount'),
                          style: GoogleFonts.notoSansTamil(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '₹${widget.totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.notoSansTamil(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FarmerOrdersScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    LocalizationService.tr('title_my_orders') ?? 'View Orders',
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
