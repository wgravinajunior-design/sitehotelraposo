import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'theme/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Fazenda Raposo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: HotelColors.primaryGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: HotelColors.primaryGreen,
          primary: HotelColors.primaryGreen,
          secondary: HotelColors.accentGold,
          surface: HotelColors.white,
        ),
      ),
      home: const HomePage(),
    );
  }
}
