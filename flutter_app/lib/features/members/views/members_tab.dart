import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/interactive_card.dart';
import '../../../shared/widgets/load_more_list_view.dart';
import '../../pos/views/barcode_scanner_screen.dart';
import '../data/members_repository.dart';
import '../models/member_models.dart';
import 'member_detail_screen.dart';
import 'member_register_sheet.dart';
import 'tiers_screen.dart';

class MembersTab extends ConsumerStatefulWidget {
  const MembersTab({super.key});

  @override
  ConsumerState<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<MembersTab> {
  final _searchController = TextEditingController();
  String _search = '';
  var _listKey = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _bumpList() => setState(() => _listKey++);

  Future<({List<MemberModel> items, int lastPage})> _loadPage(int page) async {
    final result = await ref.read(membersRepositoryProvider).listMembers(
          search: _search.isEmpty ? null : _search,
          page: page,
        );
    return (items: result.items, lastPage: result.meta.lastPage);
  }

  Future<void> _scanMember() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || !mounted) return;

    try {
      final repo = ref.read(membersRepositoryProvider);
      final member = code.length > 20
          ? await repo.findByQrToken(code)
          : await repo.findByCode(code);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemberDetailScreen(
            memberId: member.id,
            memberUuid: member.uuid.isNotEmpty ? member.uuid : null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member tidak ditemukan: $e')),
      );
    }
  }

  Future<void> _registerMember() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const MemberRegisterSheet(),
    );
    if (created == true) _bumpList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama / telepon / kode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                        _bumpList();
                      },
                    ),
                  ),
                  onSubmitted: (v) {
                    setState(() => _search = v);
                    _bumpList();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _scanMember,
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan member',
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TiersScreen()),
                ),
                icon: const Icon(Icons.military_tech_outlined),
                tooltip: 'Tier member',
              ),
              IconButton.filled(
                onPressed: _registerMember,
                icon: const Icon(Icons.person_add),
                tooltip: 'Daftar member',
              ),
            ],
          ),
        ),
        Expanded(
          child: LoadMoreListView<MemberModel>(
            key: ValueKey('members-$_listKey-$_search'),
            loader: _loadPage,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            empty: const Center(child: Text('Belum ada member')),
            itemBuilder: (context, member, index) {
              return InteractiveCard(
                margin: EdgeInsets.zero,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MemberDetailScreen(
                        memberId: member.id,
                        memberUuid:
                            member.uuid.isNotEmpty ? member.uuid : null,
                      ),
                    ),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${member.memberCode} · ${member.phone}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (member.tier != null)
                        Chip(
                          label: Text(
                            member.tier!.name,
                            style: const TextStyle(fontSize: 10),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      Text(
                        Formatters.currency(member.totalSpend),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}