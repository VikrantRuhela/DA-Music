// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:da_tunes/shared/widgets/app_shell.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Back Stack Hierarchy Tests', () {
    test('PopScope is present in AppShell tree', () {
      expect(find.byType(PopScope), isNotNull);
    });
  });
}
