import '../../../services/receipt_builder.dart';
import 'pos_models.dart';

class TransactionSuccessInfo {
  const TransactionSuccessInfo({
    required this.transaction,
    required this.receiptData,
    this.wasOffline = false,
    this.receiptUuid,
    this.printMessage,
    this.printSucceeded,
  });

  final PosTransaction transaction;
  final ReceiptData receiptData;
  final bool wasOffline;
  final String? receiptUuid;
  final String? printMessage;
  final bool? printSucceeded;
}