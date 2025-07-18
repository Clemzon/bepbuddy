import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../viewmodel/packaged_invoices_viewmodel.dart';

class PackagedInvoicesView extends StatelessWidget {
  final bool multiSelect;
  final String reportPath;

  const PackagedInvoicesView({
    super.key,
    this.multiSelect = false,
    required this.reportPath,
  });

  Future<void> _submit(
      BuildContext context,
      PackagedInvoicesViewModel vm,
      ) async {
    final navigator = Navigator.of(context);
    final files = <XFile>[
      XFile(reportPath),
      ...vm.selectedPaths.map((path) => XFile(path)),
    ];

    await SharePlus.instance.share(
      ShareParams(
        files: files,
        text: 'Please find attached the report and selected invoice packages.',
      ),
    );

    navigator.pop();
  }

  Future<void> _showItemActions(
    BuildContext context,
    PackagedInvoicesViewModel vm,
    String path,
    String name,
  ) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () async {
                Navigator.pop(context);
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(path)],
                    text: 'Please find attached the invoice package: $name',
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                vm.deletePackage(path);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PackagedInvoicesViewModel>(
      create: (_) => PackagedInvoicesViewModel(reportPath)..loadPackaged(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invoice Packages'),
          actions: [
            if (multiSelect)
              Consumer<PackagedInvoicesViewModel>(
                builder: (_, vm, __) => TextButton(
                  onPressed:
                  vm.isLoading ? null : () => _submit(context, vm),
                  child: const Text(
                    'SUBMIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Consumer<PackagedInvoicesViewModel>(
          builder: (_, vm, __) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.packages.isEmpty) {
              return const Center(
                  child: Text('No invoice packages found.'));
            }
            return ListView.builder(
              itemCount: vm.packages.length,
              itemBuilder: (_, i) {
                if (!multiSelect) {
                  final file = vm.packages[i];
                  final path = file.path;
                  final name = p.basename(path);
                  return ListTile(
                    title: Text(name),
                    trailing: IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () async {
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(path)],
                            text: 'Please find attached the invoice package: $name',
                          ),
                        );
                      },
                    ),
                    onLongPress: () => _showItemActions(context, vm, path, name),
                  );
                }
                final file = vm.packages[i];
                final path = file.path;
                final name = p.basename(path);
                final checked = vm.selectedPaths.contains(path);
                return GestureDetector(
                  onLongPress: () => _showItemActions(context, vm, path, name),
                  child: CheckboxListTile(
                    title: Text(name),
                    value: checked,
                    onChanged: (_) => vm.togglePath(path),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}