import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kliensy/core/router/app_routes.dart';
import 'package:kliensy/features/auth/state/auth_controller.dart';
import 'package:kliensy/features/requests/models/request_model.dart';
import 'package:kliensy/features/requests/state/requests_controller.dart';
import 'package:kliensy/features/requests/ui/modals/new_request_modal.dart';
import 'package:kliensy/shared/ui/app_shell.dart';
import 'package:kliensy/shared/ui/page_header.dart';
import 'package:kliensy/shared/ui/status_badge.dart';



class RequestsPage extends StatefulWidget {
  const RequestsPage({
    super.key,
    required this.requestsController,
  });

  final RequestsController requestsController;

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  RequestsController get _rc => widget.requestsController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rc.load(refresh: true);
      _rc.loadCounts();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _rc.loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openNewRequest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewRequestModal(requestsController: _rc),
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
            title: 'Заявки',
            searchHint: 'Поиск по заявкам и клиентам',
            actionLabel: '+ Новая заявка',
            onAction: _openNewRequest,
            searchController: _searchController,
            onSearch: _rc.setSearch,
          ),
        if (isMobile) _MobileHeader(onSearch: () {}, onAdd: _openNewRequest),
        _TabBar(controller: _rc),
        const Divider(height: 1),
        Expanded(
          child: AnimatedBuilder(
            animation: _rc,
            builder: (_, __) => _Body(
              controller: _rc,
              scrollController: _scrollController,
              isMobile: isMobile,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});
  final RequestsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Tab(
                label: 'Все',
                count: controller.countAll,
                isActive: controller.activeTab == RequestsTab.all,
                onTap: () => controller.setTab(RequestsTab.all),
              ),
              _Tab(
                label: 'Новые',
                count: controller.countNew,
                isActive: controller.activeTab == RequestsTab.newRequests,
                onTap: () => controller.setTab(RequestsTab.newRequests),
              ),
              _Tab(
                label: 'В работе',
                count: controller.countInProgress,
                isActive: controller.activeTab == RequestsTab.inProgress,
                onTap: () => controller.setTab(RequestsTab.inProgress),
              ),
              _Tab(
                label: 'Завершённые',
                count: controller.countDone,
                isActive: controller.activeTab == RequestsTab.done,
                onTap: () => controller.setTab(RequestsTab.done),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive
                  ? const Color(0xFF1A5BFF)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF1A5BFF)
                    : const Color(0xFF6B7280),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF1A5BFF)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                    isActive ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body — Desktop table / Mobile list
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.controller,
    required this.scrollController,
    required this.isMobile,
  });

  final RequestsController controller;
  final ScrollController scrollController;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.listError != null && controller.items.isEmpty) {
      return Center(
        child: Text(
          controller.listError!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (controller.items.isEmpty) {
      return _EmptyState(
        activeTab: controller.activeTab,
      );
    }

    if (isMobile) {
      return _MobileList(
        items: controller.items,
        scrollController: scrollController,
        isLoadingMore: controller.isLoadingMore,
      );
    }

    return _DesktopTable(
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

  final List<RequestModel> items;
  final ScrollController scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _TableHeader(),
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
                return _TableRow(item: items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: const Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(
              'Клиент',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Название',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              'Статус',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              'Дата создания',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Комментарий',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.item});
  final RequestModel item;

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.requestDetailPath(item.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.clientName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1D2E),
                    ),
                  ),
                  if (item.clientPhone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.clientPhone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 130,
              child: StatusBadge(status: item.status),
            ),
            SizedBox(
              width: 130,
              child: Text(
                _formatDate(item.createdAt),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                '${item.commentCount}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(
              width: 32,
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFD1D5DB),
              ),
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

  final List<RequestModel> items;
  final ScrollController scrollController;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 16),
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
        return _MobileRequestTile(item: items[index]);
      },
    );
  }
}

class _MobileRequestTile extends StatelessWidget {
  const _MobileRequestTile({required this.item});
  final RequestModel item;

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    if (isToday) {
      return 'Сегодня в ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.requestDetailPath(item.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.clientName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1D2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(status: item.status),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatTime(item.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile header
// ─────────────────────────────────────────────────────────────────────────────

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
              'Заявки',
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.activeTab});
  final RequestsTab activeTab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text(
            activeTab == RequestsTab.all
                ? 'У вас пока нет заявок'
                : 'Нет заявок в этом статусе',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Создайте первую заявку, чтобы начать работу',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}