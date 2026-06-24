import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class RoomCard extends StatefulWidget {
  final String title;
  final String category;
  final String imagePath; // Pode ser Asset, URL ou String Base64
  final String description;
  final List<String> amenities;

  const RoomCard({
    super.key,
    required this.title,
    required this.category,
    required this.imagePath,
    required this.description,
    required this.amenities,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool _isHovered = false;

  IconData _getAmenityIcon(String name) {
    switch (name.toLowerCase()) {
      case 'wi-fi':
      case 'wifi':
        return Icons.wifi;
      case 'ar-condicionado':
      case 'ar':
        return Icons.ac_unit;
      case 'frigobar':
        return Icons.kitchen;
      case 'tv':
      case 'televisão':
        return Icons.tv;
      case 'piscina':
        return Icons.pool;
      case 'varanda':
        return Icons.balcony;
      case 'jacuzzi':
      case 'hidromassagem':
        return Icons.hot_tub;
      case 'cama king':
        return Icons.king_bed;
      case 'vista para o lago':
        return Icons.landscape;
      case 'cozinha americana':
        return Icons.countertops;
      default:
        return Icons.star_border;
    }
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      try {
        String base64Str = imagePath;
        if (imagePath.contains(',')) {
          base64Str = imagePath.split(',')[1];
        }
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: HotelColors.primaryGreen.withOpacity(0.05),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: HotelColors.accentGold,
        size: 32,
      ),
    );
  }

  void _bookRoom() async {
    String message = 'Olá! Vi o site do hotel e gostaria de consultar tarifas e disponibilidade '
        'especificamente para o quarto: ${widget.title} (${widget.category}). Como posso fazer a reserva?';
    
    String whatsappUrl = 'https://wa.me/5522999912144?text=${Uri.encodeComponent(message)}';
    final Uri url = Uri.parse(whatsappUrl);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o WhatsApp. Tente o número (22) 99991-2144.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _bookRoom,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -8.0 : 0.0),
          decoration: BoxDecoration(
            color: HotelColors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: HotelColors.primaryGreen.withOpacity(_isHovered ? 0.12 : 0.06),
                blurRadius: _isHovered ? 24 : 12,
                offset: Offset(0, _isHovered ? 12 : 6),
              ),
            ],
            border: Border.all(
              color: _isHovered ? HotelColors.accentGold.withOpacity(0.5) : HotelColors.lightGrey,
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Imagem do Quarto
                Stack(
                  children: [
                    AnimatedScale(
                      scale: _isHovered ? 1.03 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: _buildImage(widget.imagePath),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: HotelColors.primaryGreen,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          widget.category.toUpperCase(),
                          style: HotelTypography.bookingLabel.copyWith(
                            color: HotelColors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Conteúdo do Quarto
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: HotelTypography.cardTitle.copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: HotelTypography.bodyTextSmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      
                      // Comodidades com ícones
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: widget.amenities.map((amenity) {
                          return Tooltip(
                            message: amenity,
                            child: Container(
                              padding: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                color: HotelColors.bgLight,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getAmenityIcon(amenity),
                                    size: 14,
                                    color: HotelColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    amenity,
                                    style: HotelTypography.bodyTextSmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: HotelColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Botão Consultar Tarifa
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _bookRoom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isHovered ? HotelColors.accentGold : HotelColors.primaryGreen,
                            foregroundColor: HotelColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Text(
                            'Ver Tarifas & Reservar',
                            style: HotelTypography.buttonText.copyWith(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
