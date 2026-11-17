import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/quotation_models.dart';
import '../data/quotation_repository.dart';

class QuotationListScreen extends ConsumerWidget {
  const QuotationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(myQuotationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My quotations'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-quotation'),
        onPressed: () => context.push('/products'),
        icon: const Icon(Icons.add),
        label: const Text('New quotation'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myQuotationsProvider);
          await ref.read(myQuotationsProvider.future);
        },
        child: items.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(e.toString(), textAlign: TextAlign.center),
              ),
            ],
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(48),
                      child: Text('No quotations yet.', textAlign: TextAlign.center),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _QuotationTile(list[i]),
                ),
        ),
      ),
    );
  }
}

class _QuotationTile extends StatelessWidget {
  const _QuotationTile(this.q);

  final QuotationSummary q;

  @override
  Widget build(BuildContext context) {
    final amount = q.loanAmount == null
        ? ''
        : ' | ${q.loanAmount!.toStringAsFixed(0)} THB / ${q.termMonths ?? '-'} months';
    return Card(
      child: ListTile(
        leading: Icon(q.productType == 'MOTORCYCLE_LOAN' ? Icons.two_wheeler : Icons.payments_outlined),
        title: Text('#${q.quotationNo}  ${q.productName}'),
        subtitle: Text('${q.applicantName ?? 'No applicant yet'}$amount'),
        trailing: Chip(label: Text(q.status)),
        // Only drafts can be edited; other statuses are read-only for now.
        onTap: q.isDraft ? () => context.push('/quotations/${q.id}') : null,
      ),
    );
  }
}
