import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message.dart';
import '../../members/data/members_repository.dart';
import '../providers/cart_notifier.dart';

Future<void> showMemberPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _MemberPickerSheet(),
  );
}

class _MemberPickerSheet extends ConsumerStatefulWidget {
  const _MemberPickerSheet();

  @override
  ConsumerState<_MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends ConsumerState<_MemberPickerSheet> {
  final _codeController = TextEditingController();
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Masukkan kode member');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final member = await ref.read(membersRepositoryProvider).findByCode(code);
      ref.read(cartProvider.notifier).setMember(
            id: member.id,
            uuid: member.uuid,
            name: member.name,
            code: member.memberCode,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hubungkan Member', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Kode member',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _lookup(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _lookup,
            style: FilledButton.styleFrom(backgroundColor: AppColors.posGreen),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cari & Hubungkan'),
          ),
        ],
      ),
    );
  }
}