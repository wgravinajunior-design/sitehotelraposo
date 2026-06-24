import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageHelper {
  /// Redimensiona a imagem para a largura máxima especificada (1024px por padrão)
  /// e a comprime no formato JPEG com a qualidade especificada (75% por padrão).
  /// Retorna os bytes resultantes (Uint8List).
  static Future<Uint8List> compressImageBytes(Uint8List bytes, {int maxWidth = 1024, int quality = 75}) async {
    try {
      // O decodificador do pacote image tenta identificar o formato automaticamente
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        debugPrint('ImageHelper: Não foi possível decodificar os bytes da imagem. Retornando bytes originais.');
        return bytes;
      }

      // Redimensiona proporcionalmente mantendo a proporção de aspecto original se exceder a largura máxima
      img.Image resizedImage = decodedImage;
      if (decodedImage.width > maxWidth) {
        resizedImage = img.copyResize(decodedImage, width: maxWidth);
      }

      // Codifica no formato JPEG com a qualidade informada
      final compressed = img.encodeJpg(resizedImage, quality: quality);
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('ImageHelper: Erro no processamento/compressão da imagem: $e');
      return bytes; // Caso falhe, retorna os bytes originais como fallback de segurança
    }
  }
}
