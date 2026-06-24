import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class EventCard extends StatefulWidget {
  final String title;
  final String dateInfo;
  final String description;
  final IconData icon;
  final String? image; // Pode ser path de Asset, URL ou String Base64

  const EventCard({
    super.key,
    required this.title,
    required this.dateInfo,
    required this.description,
    required this.icon,
    this.image,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isHovered = false;

  Widget _buildImage(String image) {
    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    } else if (image.startsWith('data:image') || !image.contains('/')) {
      // É uma string Base64
      try {
        String base64Str = image;
        if (image.contains(',')) {
          base64Str = image.split(',')[1];
        }
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        );
      } catch (e) {
        return _buildImagePlaceholder();
      }
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      color: HotelColors.primaryGreen.withOpacity(0.05),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: HotelColors.accentGold,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.image != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: hasImage ? EdgeInsets.zero : const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: HotelColors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: HotelColors.primaryGreen.withOpacity(_isHovered ? 0.1 : 0.04),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
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
              if (hasImage) ...[
                AnimatedScale(
                  scale: _isHovered ? 1.03 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildImage(widget.image!),
                ),
                const SizedBox(height: 16),
              ],
              Padding(
                padding: hasImage
                    ? const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0)
                    : EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: _isHovered
                                ? HotelColors.accentGold.withOpacity(0.15)
                                : HotelColors.bgLight,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Icon(
                            widget.icon,
                            color: _isHovered ? HotelColors.accentGold : HotelColors.primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.dateInfo,
                                style: HotelTypography.cardSubtitle.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.title,
                                style: HotelTypography.cardTitle.copyWith(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.description,
                      style: HotelTypography.bodyTextSmall.copyWith(
                        color: HotelColors.textGrey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: hasImage ? 3 : 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
