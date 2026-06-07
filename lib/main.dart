import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'database/database.dart';
import 'database/repositories/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  await initializeDateFormatting();

  final dir = await getApplicationDocumentsDirectory();
  final dbFile = p.join(dir.path, AppConfig.dbName);

  final database = AuraDatabase(NativeDatabase(File(dbFile)));

  runApp(
    ProviderScope(
      overrides: [
        auraDatabaseProvider.overrideWithValue(database),
      ],
      child: const AuraApp(),
    ),
  );
}