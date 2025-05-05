import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/property_request_provider.dart';
import '../../providers/property_provider.dart';
import 'package:intl/intl.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({Key? key}) : super(key: key);

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<PropertyRequestProvider>(context, listen: false)
            .fetchUserRequests());
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        centerTitle: true,
      ),
      body: Consumer2<PropertyRequestProvider, PropertyProvider>(
        builder: (context, requestProvider, propertyProvider, child) {
          final requests = requestProvider.requests;

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد طلبات حالياً',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final request = requests[index];
              final property =
                  propertyProvider.getPropertyById(request.propertyId);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(property?.title ?? 'عقار غير متوفر'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'تاريخ الطلب: ${DateFormat('dd/MM/yyyy').format(request.requestDate)}'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              getStatusColor(request.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          getStatusText(request.status),
                          style: TextStyle(
                            color: getStatusColor(request.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: request.status == 'pending'
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          color: Colors.red,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('إلغاء الطلب'),
                                content: const Text(
                                    'هل أنت متأكد من إلغاء هذا الطلب؟'),
                                actions: [
                                  TextButton(
                                    child: const Text('إلغاء'),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                  TextButton(
                                    child: const Text('تأكيد'),
                                    onPressed: () {
                                      requestProvider.cancelRequest(request.id);
                                      Navigator.of(ctx).pop();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
