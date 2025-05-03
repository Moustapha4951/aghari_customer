import 'package:flutter/material.dart';

class PurchaseCard extends StatelessWidget {
  // تعديل جزء عرض حالة الطلب
  Widget _buildStatusBadge(String status) {
    // تحويل النص إلى حروف صغيرة للمقارنة بشكل أكثر دقة
    final normalizedStatus = status.toLowerCase();
    
    Color color;
    String text;
    
    switch (normalizedStatus) {
      case 'approved':
        color = Colors.green;
        text = 'تمت الموافقة';
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.red;
        text = 'مرفوض';
        break;
      case 'completed':
        color = Colors.blue;
        text = 'مكتمل';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        text = 'قيد الانتظار';
    }
    
    // إظهار المعلومات التشخيصية
    print('عرض حالة الطلب: $status -> $text (القيمة الأصلية: $normalizedStatus)');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Example usage
    String status = 'pending';
    return _buildStatusBadge(status);
  }
} 