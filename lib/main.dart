import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:event_planner/event_planning_app.dart';
import 'package:flutter/material.dart';
import 'package:event_planner/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  ApiService.setToken('2|q7duE7GjdrGl0eygZq8e2AYqkKblIEKDXvonMcxY328f2a0c');
  runApp(const EventPlanningApp());
}
