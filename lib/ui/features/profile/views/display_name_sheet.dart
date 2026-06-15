import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../features/profile/view_models/profile_controller.dart';
import '../../../features/today/view_models/today_providers.dart';

Future<void> showDisplayNameSheet(BuildContext context) =>
    showCrudoSheet<void>(context, builder: (_) => const _DisplayNameSheet());

class _DisplayNameSheet extends ConsumerStatefulWidget {
  const _DisplayNameSheet();

  @override
  ConsumerState<_DisplayNameSheet> createState() => _DisplayNameSheetState();
}

class _DisplayNameSheetState extends ConsumerState<_DisplayNameSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final name = ref.read(profileProvider).requireValue.displayName;
    _controller = TextEditingController(text: name);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    return SheetScaffold(
      title: 'Your name',
      body: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter your name'),
      ),
      cta: PrimaryCta(
        label: 'Save',
        enabled: text.trim().isNotEmpty,
        onPressed: text.trim().isEmpty
            ? null
            : () async {
                await ref
                    .read(profileControllerProvider.notifier)
                    .setDisplayName(text.trim());
                if (context.mounted) Navigator.of(context).pop();
              },
      ),
    );
  }
}
