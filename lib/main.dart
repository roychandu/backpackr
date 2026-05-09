import 'package:backpackr/app/app.dart';
import 'package:backpackr/app/bootstrap.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(const MyApp());
}
