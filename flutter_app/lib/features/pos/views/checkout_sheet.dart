import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pos_totals.dart';
import '../../../local_database/offline_queue_repository.dart';
import '../../../shared/widgets/cash_keypad.dart';
import '../../settings/providers/sync_providers.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/offline_cache_service.dart';
import '../../../services/printer_service.dart';
import '../../../services/receipt_builder.dart';
import '../../auth/providers/auth_providers.dart';
import '../../standalone/providers/standalone_providers.dart';
import '../../members/data/members_repository.dart';
import '../../members/models/member_detail_key.dart';
import '../../members/models/member_models.dart';
import '../../members/providers/members_providers.dart';
import '../../settings/data/settings_repository.dart';
import '../data/pos_repository.dart';
import '../models/pos_models.dart';
import '../models/transaction_success.dart';
import '../providers/cart_notifier.dart';
import '../providers/pos_providers.dart';

class CheckoutSheet extends ConsumerStatefulWidget {
  const CheckoutSheet({
    super.key,
    required this.outletId,
    this.shiftId,
    required this.paymentMethods,
    required this.onSuccess,
  });

  final int outletId;
  final int? shiftId;
  final List<PaymentMethod> paymentMethods;
  final void Function(TransactionSuccessInfo info) onSuccess;

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  PaymentMethod? _selectedMethod;
  var _isProcessing = false;
  String? _error;
  var _cashReceived = 0.0;
  String _discountType = 'nominal';
  final _discountController = TextEditingController();
  final _pointsRedeemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethods.isNotEmpty) {
      _selectedMethod = widget.paymentMethods.first;
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _pointsRedeemController.dispose();
    super.dispose();
  }

  double _pointsDiscount(CartState cart, PointBalanceDetail? points) {
    final pts = int.tryParse(_pointsRedeemController.text);
    if (pts == null || pts <= 0 || points?.config == null) return 0;
    final config = points!.config!;
    if (pts < config.minRedeemPoints || pts > points.balance) return 0;
    return config.discountForPoints(pts);
  }

  bool get _isCash =>
      _selectedMethod?.type == 'cash' || _selectedMethod?.code == 'cash';

  double _discountValue() =>
      double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0;

  double _discountTotal(double subtotal) {
    final value = _discountValue();
    if (value <= 0) return 0;
    if (_discountType == 'percentage') return subtotal * value / 100;
    return value;
  }

  Future<bool> _isServerUp() => ref
      .read(connectivityServiceProvider)
      .isServerReachable(ref.read(apiBaseUrlProvider));

  Future<TenantSettings> _loadSettings({required bool serverUp}) {
    return ref.read(settingsRepositoryProvider).getTenantSettings(
          cache: ref.read(offlineCacheServiceProvider),
          online: serverUp,
        );
  }

  Future<ReceiptData> _buildReceiptData({
    required CartState cart,
    required PosTotals totals,
    required PaymentMethod method,
    required String transactionNumber,
    required bool isOffline,
    String? receiptUuid,
    String? outletName,
  }) async {
    try {
      if (!isOffline && receiptUuid != null) {
        final receiptJson =
            await ref.read(posRepositoryProvider).getReceipt(receiptUuid);
        return ReceiptBuilder.fromApiReceipt(receiptJson);
      }
    } catch (_) {
      // Fallback to cart-based receipt below
    }

    final settings = await _loadSettings(serverUp: isOffline ? false : await _isServerUp());
    final cashierName = ref.read(authControllerProvider).session?.user.name;

    final wifiSsid = settings.receiptShowWifi ? settings.wifiSsid : null;
    final wifiPassword = settings.receiptShowWifi ? settings.wifiPassword : null;

    return ReceiptBuilder.fromCart(
      lines: cart.items
          .map((i) => (name: i.product.name, qty: i.quantity, unitPrice: i.unitPrice))
          .toList(),
      transactionNumber: transactionNumber,
      subtotal: totals.subtotal,
      grandTotal: totals.grandTotal,
      paymentMethodName: method.name,
      taxTotal: totals.taxTotal,
      serviceCharge: totals.serviceCharge,
      discountTotal: totals.discountTotal,
      businessName: settings.businessName,
      outletName: outletName,
      cashierName: cashierName,
      isOffline: isOffline,
      wifiSsid: wifiSsid,
      wifiPassword: wifiPassword,
    );
  }

  Future<PrintResult?> _printReceipt(ReceiptData data) async {
    final config = await ref.read(printerServiceProvider).getConfig();
    if (!config.autoPrint) return null;
    return ref.read(printerServiceProvider).printReceipt(data);
  }

  Future<void> _checkout() async {
    final cart = ref.read(cartProvider);
    final method = _selectedMethod;
    if (method == null) {
      setState(() => _error = 'Pilih metode pembayaran');
      return;
    }
    if (cart.items.isEmpty) return;

    final serverUp = await _isServerUp();
    final settings = await _loadSettings(serverUp: serverUp);
    PointBalanceDetail? memberPoints;
    if (cart.memberId != null) {
      try {
        memberPoints = await ref.read(membersRepositoryProvider).getPoints(
              MemberDetailKey(id: cart.memberId!, uuid: cart.memberUuid),
            );
      } catch (_) {}
    }
    final manualDiscount = _discountTotal(cart.subtotal);
    final pointsDiscount = _pointsDiscount(cart, memberPoints);
    final discountTotal = manualDiscount + pointsDiscount;
    final totals = calculatePosTotals(
      subtotal: cart.subtotal,
      discountTotal: discountTotal,
      taxRate: settings.taxRate,
      serviceRate: settings.serviceChargeRate,
    );
    final grandTotal = double.parse(totals.grandTotal.toStringAsFixed(2));

    if (_isCash && _cashReceived < grandTotal) {
      setState(() => _error = 'Uang diterima kurang dari total');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      ref.read(cartProvider.notifier).setDiscount(
            type: manualDiscount > 0 ? _discountType : null,
            value: _discountValue(),
          );
      final redeemPts = int.tryParse(_pointsRedeemController.text);
      ref.read(cartProvider.notifier).setPointsRedeem(
            redeemPts != null && redeemPts > 0 ? redeemPts : null,
          );

      final payload = ref.read(cartProvider.notifier).buildCheckoutPayload(
            outletId: widget.outletId,
            shiftId: widget.shiftId,
          );

      payload['payments'] = [
        {
          'payment_method_id': method.id,
          'amount': grandTotal,
        },
      ];

      final isStandalone =
          ref.read(authControllerProvider).status == AuthStatus.standalone;

      if (!serverUp || isStandalone) {
        final key = newIdempotencyKey();
        if (isStandalone) {
          await ref.read(offlineQueueRepositoryProvider).enqueueLocal(
                idempotencyKey: key,
                payload: payload,
              );
        } else {
          await ref.read(offlineQueueRepositoryProvider).enqueue(
                idempotencyKey: key,
                payload: payload,
              );
        }
        await ref.read(offlineCacheServiceProvider).recordOfflineSale(
              outletId: widget.outletId,
              amount: grandTotal,
            );
        if (isStandalone) {
          await ref.read(localInventoryRepositoryProvider).deductStockForSale(
                items: cart.items
                    .map(
                      (i) => (
                        productId: i.product.id,
                        quantity: i.quantity,
                      ),
                    )
                    .toList(),
              );
          await ref.read(standaloneServiceProvider).refreshPosCatalog();
          ref.invalidate(posCatalogProvider(PosCatalogQuery()));
        }
        ref.invalidate(pendingSyncCountProvider);
        ref.invalidate(currentShiftProvider(widget.outletId));

        final txNumber = isStandalone
            ? 'LOC-${key.substring(0, 8)}'
            : 'OFF-${key.substring(0, 8)}';
        final receiptData = await _buildReceiptData(
          cart: cart,
          totals: totals,
          method: method,
          transactionNumber: txNumber,
          isOffline: true,
        );
        PrintResult? printResult;
        try {
          printResult = await _printReceipt(receiptData);
        } catch (_) {}

        ref.read(cartProvider.notifier).clear();
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSuccess(
            TransactionSuccessInfo(
              transaction: PosTransaction(
                uuid: key,
                transactionNumber: txNumber,
                grandTotal: grandTotal,
                status: isStandalone ? 'completed' : 'pending_sync',
              ),
              receiptData: receiptData,
              wasOffline: !isStandalone,
              printSucceeded: printResult?.success,
              printMessage: printResult?.message,
            ),
          );
        }
        return;
      }

      final key = newIdempotencyKey();
      final tx = await ref.read(posRepositoryProvider).createTransaction(
            payload: payload,
            idempotencyKey: key,
          );

      final receiptData = await _buildReceiptData(
        cart: cart,
        totals: totals,
        method: method,
        transactionNumber: tx.transactionNumber,
        isOffline: false,
        receiptUuid: tx.uuid,
      );
      PrintResult? printResult;
      try {
        printResult = await _printReceipt(receiptData);
      } catch (_) {}

      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess(
          TransactionSuccessInfo(
            transaction: tx,
            receiptData: receiptData,
            wasOffline: false,
            receiptUuid: tx.uuid,
            printSucceeded: printResult?.success,
            printMessage: printResult?.message,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = friendlyError(e);
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isStandalone =
        ref.watch(authControllerProvider).status == AuthStatus.standalone;
    final settings = ref.watch(tenantSettingsProvider);
    final memberPoints = !isStandalone && cart.memberId != null
        ? ref.watch(
            memberPointsProvider(
              MemberDetailKey(id: cart.memberId!, uuid: cart.memberUuid),
            ),
          )
        : null;
    final manualDiscount = settings.maybeWhen(
      data: (_) => _discountTotal(cart.subtotal),
      orElse: () => 0.0,
    );
    final pointsDiscount = memberPoints?.maybeWhen(
          data: (p) => _pointsDiscount(cart, p),
          orElse: () => 0.0,
        ) ??
        0.0;
    final discountTotal = manualDiscount + pointsDiscount;
    final totals = settings.maybeWhen(
      data: (s) => calculatePosTotals(
        subtotal: cart.subtotal,
        discountTotal: discountTotal,
        taxRate: s.taxRate,
        serviceRate: s.serviceChargeRate,
      ),
      orElse: () => calculatePosTotals(subtotal: cart.subtotal),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.posGreenLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.posGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Pembayaran',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!isStandalone && cart.memberId != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.posGreenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.posGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cart.memberName ?? 'Member',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (cart.memberCode != null)
                            Text(
                              cart.memberCode!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearMember();
                        _pointsRedeemController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Lepas member',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            _SummaryRow('Item', '${cart.itemCount}'),
            _SummaryRow('Subtotal', Formatters.currency(totals.subtotal)),
            if (manualDiscount > 0)
              _SummaryRow('Diskon', '-${Formatters.currency(manualDiscount)}'),
            if (pointsDiscount > 0)
              _SummaryRow(
                'Redeem Poin',
                '-${Formatters.currency(pointsDiscount)}',
              ),
            if (totals.taxTotal > 0)
              _SummaryRow('Pajak', Formatters.currency(totals.taxTotal)),
            if (totals.serviceCharge > 0)
              _SummaryRow('Service', Formatters.currency(totals.serviceCharge)),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.posGreenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _SummaryRow(
                'Total Bayar',
                Formatters.currency(totals.grandTotal),
                bold: true,
                highlight: true,
              ),
            ),
            const SizedBox(height: 16),
            Text('Diskon', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'nominal', label: Text('Rp')),
                ButtonSegment(value: 'percentage', label: Text('%')),
              ],
              selected: {_discountType},
              onSelectionChanged: (v) => setState(() => _discountType = v.first),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _discountType == 'percentage' ? 'Diskon %' : 'Diskon Rp',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (!isStandalone && cart.memberUuid != null)
              memberPoints?.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (p) {
                  if (p.balance <= 0 || p.config == null) {
                    return const SizedBox.shrink();
                  }
                  final config = p.config!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Tukar Poin (saldo: ${p.balance})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pointsRedeemController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              'Jumlah poin (min ${config.minRedeemPoints})',
                          helperText:
                              '${config.redeemPoints} poin = ${Formatters.currency(config.redeemValue)}',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
            const SizedBox(height: 16),
            Text('Metode Pembayaran',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.paymentMethods.map((method) {
                final selected = _selectedMethod?.id == method.id;
                return ChoiceChip(
                  label: Text(method.name),
                  selected: selected,
                  selectedColor: AppColors.posGreenLight,
                  checkmarkColor: AppColors.posGreen,
                  onSelected: (_) => setState(() {
                    _selectedMethod = method;
                    if (method.type == 'cash' || method.code == 'cash') {
                      _cashReceived = totals.grandTotal;
                    }
                  }),
                );
              }).toList(),
            ),
            if (_isCash) ...[
              const SizedBox(height: 16),
              CashKeypad(
                total: totals.grandTotal,
                received: _cashReceived,
                onChanged: (v) => setState(() => _cashReceived = v),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _checkout();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.posGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print_outlined),
                label: const Text(
                  'BAYAR & CETAK STRUK',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false, this.highlight = false});

  final String label;
  final String value;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: highlight ? 20 : 18,
            color: highlight ? AppColors.posGreenDark : null,
          )
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}