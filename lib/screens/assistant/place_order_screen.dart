import 'package:flutter/material.dart';
import 'package:event_planner/constants/app_colors.dart';
import 'package:event_planner/services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlaceOrderScreen extends StatefulWidget {
  final int taskId;
  final int vendorId;
  final String vendorName;

  const PlaceOrderScreen({
    super.key,
    required this.taskId,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _existingOrder;

  @override
  void initState() {
    super.initState();
    _loadExistingOrder();
  }

  Future<void> _loadExistingOrder() async {
    try {
      final result = await ApiService.getMyOrders();
      if (result['success'] == true) {
        final orders = result['data'] as List? ?? [];
        for (var order in orders) {
          if (order['task_id'] == widget.taskId &&
              order['vendor_id'] == widget.vendorId) {
            setState(() {
              _existingOrder = Map<String, dynamic>.from(order);
              _priceController.text = order['price']?.toString() ?? '';
              _notesController.text = order['notes'] ?? '';
            });
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _submitOrder() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await ApiService.submitOrder(
        taskId: widget.taskId,
        vendorId: widget.vendorId,
        price: double.parse(_priceController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(22),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: FaIcon(
                                FontAwesomeIcons.arrowLeft,
                                size: 20,
                                color: AppColors.darkpink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.burgundy,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_existingOrder != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.coral.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: AppColors.darkpink,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'You can update your existing order',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.darkpink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 28),

                        // Vendor info - simple text, no white box
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Vendor: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.burgundy,
                                ),
                              ),
                              TextSpan(
                                text: widget.vendorName,
                                style: const TextStyle(
                                  color: AppColors.burgundy,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Price
                        const Text(
                          'Price (\$)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.burgundy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Enter the quoted price',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.burgundy),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: AppColors.green.withOpacity(0.4),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Notes
                        const Text(
                          'Order Notes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.burgundy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'What are you ordering?',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          style: const TextStyle(color: AppColors.burgundy),
                          decoration: InputDecoration(
                            hintText: 'place your order here',
                            hintStyle: TextStyle(
                              color: AppColors.green.withOpacity(0.4),
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkpink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _existingOrder != null
                                        ? 'Update Order'
                                        : 'Place Order',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = AppColors.coral.withOpacity(0.10);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), 130, p);
    p.color = AppColors.darkpink.withOpacity(0.07);
    canvas.drawCircle(Offset(size.width * -0.12, size.height * 0.48), 170, p);
    p.color = const Color.fromARGB(255, 176, 27, 44).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 1.08, size.height * 0.72), 190, p);
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => false;
}
