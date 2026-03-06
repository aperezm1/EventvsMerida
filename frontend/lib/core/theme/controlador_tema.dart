import 'package:flutter/material.dart';

class ControladorTema extends ValueNotifier<ThemeMode> {
  ControladorTema() : super(ThemeMode.system);
}

final themeController = ControladorTema();