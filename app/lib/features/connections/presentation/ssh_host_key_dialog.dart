import 'package:flutter/material.dart';

import '../domain/models.dart';

Future<bool> showSshHostKeyDialog(
  BuildContext context,
  TestFailed failure,
) async {
  final key = failure.hostKey;
  if (key == null) return false;
  final unknown = failure.kind == ConnectionErrorKind.sshUnknownKey;
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(failure.headline),
          content: SelectableText(
            [
              'Host  ${key.host}:${key.port}',
              'Presented key  ${key.presented}',
              if (key.trusted.isNotEmpty) 'Trusted key  ${key.trusted}',
              if (unknown) 'Verify the fingerprint with the SSH host administrator before trusting it.',
              if (!unknown) failure.message,
            ].join('\n\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(unknown ? 'Cancel' : 'Close'),
            ),
            if (unknown)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Trust host key'),
              ),
          ],
        ),
      ) ??
      false;
}
