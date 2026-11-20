import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../connections/application/connections_controller.dart';
import '../../editor/application/editor_tabs.dart';
import '../application/gridfs_controller.dart';
import 'gridfs_dialogs.dart';

enum GridFsAction { upload, download, rename, replace, delete, refresh }

Future<void> runGridFsAction(
  BuildContext context,
  WidgetRef ref,
  EditorTab tab,
  GridFsAction action,
) async {
  final provider = gridFsControllerProvider(tab.id);
  final state = ref.read(provider);
  final target = state.target;
  if (target == null) return;
  final controller = ref.read(provider.notifier);
  if (action == GridFsAction.refresh) {
    if (state.work?.canCancel ?? false) {
      controller.cancel();
    } else if (state.work == null) {
      await controller.refresh();
    }
    return;
  }
  if (state.work != null) return;
  final selected = state.selection?.file;
  final production =
      ref
          .read(connectionsControllerProvider)
          .value
          ?.where((p) => p.id == tab.connectionId)
          .firstOrNull
          ?.production ??
      false;

  bool sameTarget() => context.mounted && ref.read(provider).target == target;

  Future<bool> confirm(bool forProduction) => sameTarget() && selected != null
      ? confirmGridFsWrite(
          context,
          selected,
          production: forProduction,
          replace: action == GridFsAction.replace,
        )
      : Future.value(false);

  try {
    switch (action) {
      case GridFsAction.upload:
      case GridFsAction.replace:
        if (action == GridFsAction.replace && selected == null) return;
        final source = await openFile();
        if (source == null || !sameTarget() || !context.mounted) return;
        final upload = await showGridFsUploadDialog(
          context,
          source.name,
          replacing: action == GridFsAction.replace ? selected : null,
        );
        if (upload == null || !sameTarget()) return;
        await controller.upload(
          File(source.path),
          upload,
          production: production,
          confirm: confirm,
        );
      case GridFsAction.download:
        if (selected == null) return;
        final name = selected.filename.split(RegExp(r'[/\\]')).last;
        final location = await getSaveLocation(
          suggestedName: name.isEmpty || name == '.' || name == '..'
              ? 'download'
              : name,
        );
        if (location == null || !sameTarget()) return;
        await controller.download(selected, File(location.path));
      case GridFsAction.rename:
        if (selected == null) return;
        final name = await showGridFsNameDialog(
          context,
          title: 'Rename file',
          initial: selected.filename,
        );
        if (name == null || name == selected.filename || !sameTarget()) return;
        await controller.rename(selected, name);
      case GridFsAction.delete:
        if (selected == null) return;
        await controller.delete(
          selected,
          production: production,
          confirm: confirm,
        );
      case GridFsAction.refresh:
        break;
    }
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
