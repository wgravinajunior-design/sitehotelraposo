import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class HotelTypography {
  // Títulos e Cabeçalhos (Playfair Display)
  static TextStyle heroTitle(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double size = width > 800 ? 56 : 36;
    return GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: HotelColors.white,
      height: 1.2,
    );
  }

  static TextStyle sectionTitle(BuildContext context, {Color color = HotelColors.primaryGreen}) {
    double width = MediaQuery.of(context).size.width;
    double size = width > 800 ? 38 : 28;
    return GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle cardTitle = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: HotelColors.darkSlate,
  );

  static TextStyle cardSubtitle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: HotelColors.accentGold,
    letterSpacing: 1.2,
  );

  // Textos de Corpo e Legendas (Inter)
  static TextStyle bodyText({Color color = HotelColors.textGrey, double height = 1.6}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: color,
      height: height,
    );
  }

  static TextStyle bodyTextSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: HotelColors.textGrey,
    height: 1.5,
  );

  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  static TextStyle navItem = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: HotelColors.primaryGreen,
  );

  static TextStyle bookingLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: HotelColors.primaryGreen,
    letterSpacing: 0.5,
  );
}
