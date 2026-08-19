import '../../orders/data/order_repository.dart';
import '../../../models/order.dart';
import '../../../models/order_item.dart';
import '../data/printer_config_repository.dart';
import 'printer_service.dart';
import 'receipt_builder.dart';

class ReceiptService {
  ReceiptService({
    OrderRepository? orderRepository,
    PrinterConfigRepository? configRepository,
    PrinterService? printerService,
    ReceiptBuilder? receiptBuilder,
  }) : _orderRepository = orderRepository ?? SqliteOrderRepository(),
       _configRepository = configRepository ?? PrinterConfigRepository(),
       _printerService = printerService ?? PrinterService(),
       _receiptBuilder = receiptBuilder ?? ReceiptBuilder();

  final OrderRepository _orderRepository;
  final PrinterConfigRepository _configRepository;
  final PrinterService _printerService;
  final ReceiptBuilder _receiptBuilder;

  Future<void> printOrder(int orderId) async {
    final printer = await _configRepository.getSelectedPrinter();
    if (printer == null) {
      throw const PrinterException(
        'No receipt printer is configured. Select a paired printer first.',
      );
    }
    final results = await Future.wait([
      _orderRepository.getOrder(orderId),
      _orderRepository.getOrderItems(orderId),
    ]);
    final bytes = await _receiptBuilder.build(
      order: results[0] as RestaurantOrder,
      items: results[1] as List<OrderItem>,
    );
    await _printerService.printBytes(printer, bytes);
  }
}
