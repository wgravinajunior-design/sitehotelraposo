import 'package:flutter/material.dart';

class HotelColors {
  // Cores Principais
  static const Color primaryGreen = Color(0xFF1B3B22);  // Verde Floresta Profundo
  static const Color accentGold = Color(0xFFC5A059);    // Ouro Imperial / Bronze
  static const Color bgLight = Color(0xFFF5F7F4);       // Off-White Suave
  static const Color darkSlate = Color(0xFF1A221E);     // Grafite Carbono (Texto)
  
  // Cores de Apoio
  static const Color textGrey = Color(0xFF5A6560);      // Cinza Neutro Escuro
  static const Color lightGrey = Color(0xFFE5E9E6);     // Cinza Claro para Divisores
  static const Color white = Colors.white;
  
  // Gradientes
  static const Gradient heroGradient = LinearGradient(
    colors: [
      Color(0x991B3B22),
      Color(0x661B3B22),
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const Gradient goldGradient = LinearGradient(
    colors: [
      Color(0xFFC5A059),
      Color(0xFFE2C48D),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient darkGradient = LinearGradient(
    colors: [
      Color(0xFF1B3B22),
      Color(0xFF102414),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient mineralGradient = LinearGradient(
    colors: [
      Color(0xFFE3EDEE),
      Color(0xFFF5F7F4),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
