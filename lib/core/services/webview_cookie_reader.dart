// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Music Contributors
// Licensed under GPL-3.0.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;
import 'logger_service.dart';

class WebviewCookieReader {
  WebviewCookieReader._();

  static Uint8List? _decryptDpapi(Uint8List encryptedData) {
    final dataIn = calloc<CRYPT_INTEGER_BLOB>();
    final dataOut = calloc<CRYPT_INTEGER_BLOB>();

    try {
      final pBytes = calloc<Uint8>(encryptedData.length);
      pBytes.asTypedList(encryptedData.length).setAll(0, encryptedData);

      dataIn.ref.cbData = encryptedData.length;
      dataIn.ref.pbData = pBytes;

      final result = CryptUnprotectData(
        dataIn,
        nullptr, // ppszDataDescr
        nullptr, // pOptionalEntropy
        nullptr, // pvReserved
        nullptr, // pPromptStruct
        0,       // dwFlags
        dataOut,
      );

      if (result == TRUE) {
        final cbData = dataOut.ref.cbData;
        final pbData = dataOut.ref.pbData;
        final decrypted = pbData.asTypedList(cbData);
        return Uint8List.fromList(decrypted);
      }
    } catch (e) {
      DALogger.error('WebviewCookieReader: DPAPI Decryption error', e);
    } finally {
      if (dataOut.ref.pbData != nullptr) {
        LocalFree(dataOut.ref.pbData);
      }
      calloc.free(dataIn);
      calloc.free(dataOut);
    }
    return null;
  }

  static String? readAllCookies() {
    final paths = [
      p.join(Directory.current.path, 'webview_window_WebView2', 'EBWebView', 'Default', 'Network', 'Cookies'),
      p.join(p.dirname(Platform.resolvedExecutable), 'webview_window_WebView2', 'EBWebView', 'Default', 'Network', 'Cookies'),
    ];

    File? cookiesFile;
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        cookiesFile = file;
        break;
      }
    }

    if (cookiesFile == null) {
      DALogger.warning('WebviewCookieReader: Could not locate WebView2 Cookies file on disk.');
      return null;
    }

    DALogger.info('WebviewCookieReader: Reading SQLite cookies from ${cookiesFile.path}');

    // Copy cookies database to a temporary location to bypass WebView2 file locks
    final tempFile = File(p.join(Directory.systemTemp.path, 'temp_webview_cookies.db'));
    try {
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
      cookiesFile.copySync(tempFile.path);
    } catch (e) {
      DALogger.error('WebviewCookieReader: Failed to copy locked cookies file', e);
      return null;
    }

    Database? db;
    try {
      db = sqlite3.open(tempFile.path);
      final ResultSet resultSet = db.select(
        'SELECT host_key, name, value, encrypted_value FROM cookies WHERE host_key LIKE "%youtube.com" OR host_key LIKE "%google.com"'
      );

      final List<String> cookieParts = [];
      for (final Row row in resultSet) {
        final String name = row['name'] as String;
        String? value = row['value'] as String?;
        
        if (value == null || value.isEmpty) {
          final List<int>? encryptedBytes = row['encrypted_value'] as List<int>?;
          if (encryptedBytes != null && encryptedBytes.isNotEmpty) {
            final decryptedBytes = _decryptDpapi(Uint8List.fromList(encryptedBytes));
            if (decryptedBytes != null) {
              value = utf8.decode(decryptedBytes);
            }
          }
        }

        if (value != null && value.isNotEmpty) {
          cookieParts.add('$name=$value');
        }
      }

      if (cookieParts.isNotEmpty) {
        final resultCookies = cookieParts.join('; ');
        DALogger.info('WebviewCookieReader: Successfully read ${cookieParts.length} cookies natively.');
        return resultCookies;
      }
    } catch (e) {
      DALogger.error('WebviewCookieReader: Error parsing SQLite cookies database', e);
    } finally {
      db?.dispose();
      try {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      } catch (_) {}
    }

    return null;
  }
}
