import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kliensy/core/router/app_routes.dart';
import 'package:kliensy/features/auth/state/auth_controller.dart';
import 'package:kliensy/features/clients/models/client_model.dart';
import 'package:kliensy/features/clients/state/clients_controller.dart';
import 'package:kliensy/features/clients/ui/modals/new_client_modal.dart';
import 'package:kliensy/shared/ui/app_shell.dart';
import 'package:kliensy/shared/ui/page_header.dart';



class ClientsPage extends StatefulWidget {
  const ClientsPage({
    super.key,
    required this.clientsController,
  });

  final ClientsController clientsController;

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  ClientsController get _cc => widget.clientsController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _cc.load(refresh: true));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cc.loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openNewClient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewClientModal(clientsController: _cc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile)
          PageHeader(
            title: 'Клиенты',
            searchHint: 'Поиск по имени или телефону',
            actionLabel: '+ Новый клиент',
            onAction: _openNewClient,
            searchController: _searchController,
            onSearch: _cc.setSearch,
          )
        else
          _MobileHeader(onSearch: () {}, onAdd: _openNewClient),
        const Divider(height: 1),
        Expanded(
          child: AnimatedBuilder(
            animation: _cc,
            builder: (_, __) => _Body(
              controller: _cc,
              scrollController: _scrollController,
              isMobile: isMobile,
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.onSearch, required this.onAdd});
  final VoidCallback onSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Клиенты',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D2E),
              ),
            ),
          ),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
          ),
          IconButton(
            onPressed: onAdd,
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1A5BFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.controller,
    required this.scrollController,
    required this.isMobile,
  });

  final ClientsController controller;
  final ScrollController scrollController;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.listError != null) {
      return Center(
        child: Text(controller.listError!,
            style: const TextStyle(color: Colors.red)),
      );
    }

    if (controller.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_outlined,
                size: 64, color: Color(0xFFD1D5DB)),
            SizedBox(height: 16),
            Text('Нет клиентов',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280))),
            SizedBox(height: 8),
            Text('Добавьте первого клиента',
                style:
                TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return isMobile
        ? _MobileList(
      items: controller.items,
      scrollController: scrollController,
      isLoadingMore: controller.isLoadingMore,
    )
        : _DesktopTable(
      items: controller.items,
      scrollController: scrollController,
      isLoadingMore: controller.isLoadingMore,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop table
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({
    required this.items,
    required this.scrollController,
    required this.isLoadingMore,
  });

  final List<ClientModel> items;
  final ScrollController scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Table header
          Container(
            color: const Color(0xFFFAFAFA),
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Row(
              children: [
                SizedBox(
                    width: 260,
                    child: Text('Имя',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF)))),
                SizedBox(
                    width: 180,
                    child: Text('Телефон',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF)))),
                Expanded(
                    child: Text('Комментарий',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF)))),
                SizedBox(
                    width: 160,
                    child: Text('Дата добавления',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF)))),
                SizedBox(width: 32),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: items.length + (isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _ClientTableRow(item: items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientTableRow extends StatelessWidget {
  const _ClientTableRow({required this.item});
  final ClientModel item;

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.clientDetailPath(item.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 260,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEEF2FF),
                    ),
                    child: Center(
                      child: Text(
                        item.name.isNotEmpty
                            ? item.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF1A5BFF),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1D2E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              child: Text(
                item.phone,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF374151)),
              ),
            ),
            Expanded(
              child: Text(
                item.comment ?? '—',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF9CA3AF)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 160,
              child: Text(
                _formatDate(item.createdAt),
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ),
            const SizedBox(
              width: 32,
              child: Icon(Icons.chevron_right,
                  size: 20, color: Color(0xFFD1D5DB)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile list
// ─────────────────────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  const _MobileList({
    required this.items,
    required this.scrollController,
    required this.isLoadingMore,
  });

  final List<ClientModel> items;
  final ScrollController scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) =>
      const Divider(height: 1, color: Color(0xFFF0F0F0)),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = items[index];
        return ListTile(
          onTap: () => context.go(AppRoutes.clientDetailPath(item.id)),
          leading: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEEF2FF),
            ),
            child: Center(
              child: Text(
                item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF1A5BFF),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Text(item.name,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(item.phone,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF9CA3AF))),
          trailing: const Icon(Icons.chevron_right,
              color: Color(0xFFD1D5DB)),
        );
      },
    );
  }
}