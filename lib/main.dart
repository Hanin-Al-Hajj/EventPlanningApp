import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:event_planner/event_planning_app.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/db/vendor_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ REQUIRED for Windows / macOS / Linux
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await seedSampleVendors();

  runApp(const VendorPortalApp());
}

class VendorPortalApp extends StatelessWidget {
  const VendorPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,

      home: const EventPlanningApp(),
    );
  }
}
