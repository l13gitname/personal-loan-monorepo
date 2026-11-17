import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a product')),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(productsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final p = items[i];
            return Card(
              child: ListTile(
                leading: Icon(p.isMotorcycle ? Icons.two_wheeler : Icons.payments_outlined),
                title: Text(p.name),
                subtitle: Text(_range(p)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/quotations/new/${p.code}'),
              ),
            );
          },
        ),
      ),
    );
  }

  String _range(Product product) {
    final parts = <String>[];
    if (product.minAmount != null && product.maxAmount != null) {
      parts.add('${product.minAmount!.toStringAsFixed(0)} - ${product.maxAmount!.toStringAsFixed(0)} THB');
    }
    if (product.minTermMonths != null && product.maxTermMonths != null) {
      parts.add('${product.minTermMonths}-${product.maxTermMonths} months');
    }
    return parts.join(' | ');
  }
}
