import 'package:flutter/material.dart';
import 'package:story_project/config/flavor_config.dart';
import 'main.dart' as app;

void main() {
  FlavorConfig(flavor: Flavor.paid, name: 'Story App Paid');
  app.main();
}
