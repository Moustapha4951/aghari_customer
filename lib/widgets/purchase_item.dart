import 'dart:ui';

import 'package:flutter/material.dart';

Widget _buildStatusDisplay(String? status) {
  print('قراءة حالة الطلب: $status');

  // تحويل الحالة إلى حروف صغيرة والتأكد من وجود قيمة
  final normalizedStatus = (status ?? 'pending').trim().toLowerCase();

  Color bgColor;
  Color textColor;
  String statusText;

  switch (normalizedStatus) {
    case 'approved':
      bgColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green[800]!;
      statusText = 'تمت الموافقة';
      break;
    case 'rejected':
    case 'cancelled':
      bgColor = Colors.red.withOpacity(0.2);
      textColor = Colors.red[800]!;
      statusText = 'تم الرفض';
      break;
    case 'completed':
      bgColor = Colors.blue.withOpacity(0.2);
      textColor = Colors.blue[800]!;
      statusText = 'مكتمل';
      break;
    case 'pending':
    default:
      bgColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange[800]!;
      statusText = 'قيد الانتظار';
  }

  print('عرض حالة الطلب: $status => $statusText');

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      statusText,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}
