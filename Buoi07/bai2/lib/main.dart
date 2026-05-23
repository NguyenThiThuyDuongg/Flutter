import 'package:flutter/material.dart';
import 'maps_screen.dart';
void main() {
runApp(MapNavigatorApp());
}
class MapNavigatorApp extends StatelessWidget {
const MapNavigatorApp({super.key});
@override
Widget build(BuildContext context) {
return MaterialApp(title: 'Map Navigator', home: MapScreen());
}
}