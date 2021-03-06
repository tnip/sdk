// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.embedder_tests;

import 'dart:core' hide Resource;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:path/path.dart' as path;

import 'resource_utils.dart';
import 'utils.dart';

abstract class EmbedderRelatedTest {
  TestPathTranslator pathTranslator;
  ResourceProvider resourceProvider;

  buildResourceProvider() {
    MemoryResourceProvider rawProvider =
        new MemoryResourceProvider(isWindows: isWindows);
    resourceProvider = new TestResourceProvider(rawProvider);
    pathTranslator = new TestPathTranslator(rawProvider)
      ..newFolder('/empty')
      ..newFolder('/tmp')
      ..newFile(
          '/tmp/_embedder.yaml',
          r'''
embedded_libs:
  "dart:core" : "core.dart"
  "dart:fox": "slippy.dart"
  "dart:bear": "grizzly.dart"
  "dart:relative": "../relative.dart"
  "dart:deep": "deep/directory/file.dart"
  "fart:loudly": "nomatter.dart"
''');
  }

  clearResourceProvider() {
    resourceProvider = null;
    pathTranslator = null;
  }

  void setUp() {
    initializeTestEnvironment(path.context);
    buildResourceProvider();
  }

  void tearDown() {
    initializeTestEnvironment();
    clearResourceProvider();
  }
}
