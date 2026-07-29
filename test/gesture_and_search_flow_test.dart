// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:da_tunes/features/search/presentation/search_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Search Flow and Focus Tests', () {
    test('SearchPage widget can be instantiated', () {
      const page = SearchPage();
      expect(page.initialQuery, isEmpty);
    });

    test('SearchPageState copyWith retains state correctly', () {
      const state = SearchPageState(query: '', isLoading: false);
      final updated = state.copyWith(query: 'Karan Aujla', isLoading: true);
      expect(updated.query, equals('Karan Aujla'));
      expect(updated.isLoading, isTrue);
    });
  });
}
