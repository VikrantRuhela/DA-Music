import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:da_music/features/local_library/domain/local_metadata_parser.dart';

void main() {
  group('Local Music Library Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('da_music_test');
    });

    tearDown(() async {
      for (int i = 0; i < 5; i++) {
        try {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
          break;
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    });

    test('Extension and Directory Scan Filtering', () {
      final supported = ['a.mp3', 'b.flac', 'c.wav', 'd.m4a', 'e.opus', 'f.ogg'];
      final unsupported = ['x.txt', 'y.png', 'z.zip'];

      for (final name in supported) {
        File(p.join(tempDir.path, name)).writeAsStringSync('dummy content');
      }
      for (final name in unsupported) {
        File(p.join(tempDir.path, name)).writeAsStringSync('dummy content');
      }

      final files = tempDir.listSync().whereType<File>();
      final supportedExtensions = {
        '.mp3', '.flac', '.wav', '.m4a', '.aac', '.ogg', '.opus', '.aiff', '.aif'
      };

      final scanned = files.where((f) {
        final ext = p.extension(f.path).toLowerCase();
        return supportedExtensions.contains(ext);
      }).map((f) => p.basename(f.path)).toList();

      expect(scanned.length, equals(6));
      expect(scanned, contains('a.mp3'));
      expect(scanned, contains('b.flac'));
      expect(scanned, isNot(contains('x.txt')));
    });

    test('FLAC Binary Header Parser (24-bit / 96kHz Hi-Res)', () async {
      final flacFile = File(p.join(tempDir.path, 'test_hi_res.flac'));
      
      // Mock FLAC 42-byte header
      final header = Uint8List(42);
      // Byte 0-3: "fLaC" ASCII
      header[0] = 0x66; // 'f'
      header[1] = 0x4C; // 'L'
      header[2] = 0x61; // 'a'
      header[3] = 0x43; // 'C'
      
      // Byte 26-29 contains sample rate and bits per sample
      // For 96000 Hz: 96000 = 0x17700. In 20-bit format: 0x17, 0x70, 0x00
      // We will place 0x17700 into the first 20 bits of bytes 26, 27, 28.
      // Byte 26: 0x17 (sr1)
      // Byte 27: 0x70 (sr2)
      // Byte 28: 0x03 (first 4 bits of sr3)
      header[26] = 0x17;
      header[27] = 0x70;
      // Bits per sample: we want 24-bit.
      // In FLAC, bits per sample is stored as (bits_per_sample - 1) in 5 bits.
      // So 24-bit is stored as 23 = 0x17 (10111 in binary).
      // Bytes 28 last 4 bits, byte 29 first bit.
      // If byte 28 sr3 is 0, then we place 0x0B (first 4 bits of 23 = 1011) in byte 28.
      // Byte 28 = (sr3 >> 4) is placed at top, last 4 bits of byte 28 contains top 4 bits of bps = 0x0B
      header[28] = (0x0 << 4) | 0x0B;
      // Byte 29 first bit is last bit of bps (1). 1 << 7 = 0x80
      header[29] = 0x80;

      await flacFile.writeAsBytes(header);

      final info = await LocalMetadataParser.parseHiResAudioInfo(flacFile);

      expect(info['codec'], equals('FLAC'));
      expect(info['isLossless'], isTrue);
      expect(info['isHiRes'], isTrue);
      expect(info['bitDepth'], equals(24));
      expect(info['sampleRate'], equals(96000));
    });

    test('WAV Binary Header Parser (16-bit / 44.1kHz CD Quality)', () async {
      final wavFile = File(p.join(tempDir.path, 'test_cd.wav'));
      
      // Mock RIFF/WAVE header
      final header = Uint8List(44);
      // bytes 0-3: "RIFF"
      header[0] = 0x52; header[1] = 0x49; header[2] = 0x46; header[3] = 0x46;
      // bytes 8-11: "WAVE"
      header[8] = 0x57; header[9] = 0x41; header[10] = 0x56; header[11] = 0x45;
      // bytes 12-15: "fmt "
      header[12] = 0x66; header[13] = 0x6d; header[14] = 0x74; header[15] = 0x20;
      
      // Format subchunk size: 16 (little-endian)
      header[16] = 16;
      // Audio format: 1 (PCM)
      header[20] = 1;
      // Channels: 2
      header[22] = 2;
      // Sample rate: 44100 = 0xAC44 -> little endian: 0x44, 0xAC, 0x00, 0x00
      header[24] = 0x44;
      header[25] = 0xAC;
      // Bits per sample: 16 -> little endian: 0x10, 0x00
      header[34] = 0x10;

      await wavFile.writeAsBytes(header);

      final info = await LocalMetadataParser.parseHiResAudioInfo(wavFile);

      expect(info['codec'], equals('WAV'));
      expect(info['isLossless'], isTrue);
      expect(info['isHiRes'], isFalse); // 16-bit/44.1kHz is Lossless but not Hi-Res
      expect(info['bitDepth'], equals(16));
      expect(info['sampleRate'], equals(44100));
    });

    test('Metadata Fallback to Filename', () async {
      final dummyMp3 = File(p.join(tempDir.path, 'Amazing Song Title.mp3'));
      await dummyMp3.writeAsString('empty');

      final song = await LocalMetadataParser.parseFile(dummyMp3.path, tempDir.path);

      expect(song, isNotNull);
      expect(song!.title, equals('Amazing Song Title'));
      expect(song.artist, equals('Unknown Artist'));
      expect(song.album, equals('Local Album'));
      expect(song.source, equals('local'));
    });
  });
}
