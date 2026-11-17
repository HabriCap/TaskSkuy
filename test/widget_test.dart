import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/task.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    hiveDirectory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}task_skuy_test',
    );
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
    await hiveDirectory.create();
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Task>('tasks');
  });

  testWidgets('logs in, creates a task, completes it, and logs out', (
    tester,
  ) async {
    await tester.pumpWidget(const TaskSkuyApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'user123');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar tugas'), findsOneWidget);

    await tester.tap(find.text('Tambah tugas'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Belajar Flutter');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Membuat aplikasi',
    );
    await tester.tap(find.text('Tambah tugas').last);
    await tester.pumpAndSettle();
    expect(find.text('Belajar Flutter'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Selesai'), findsOneWidget);
    expect(Hive.box<Task>('tasks').values.single.isCompleted, isTrue);

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke akunmu'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getBool('loginData'),
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
