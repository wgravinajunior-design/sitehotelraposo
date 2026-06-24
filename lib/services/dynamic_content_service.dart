import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DynamicEvent {
  final String id;
  final String title;
  final String dateInfo;
  final String description;
  final String iconName;
  final String? image; // URL ou Base64 String

  DynamicEvent({
    required this.id,
    required this.title,
    required this.dateInfo,
    required this.description,
    required this.iconName,
    this.image,
  });

  IconData get icon => DynamicContentService.getIconByName(iconName);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dateInfo': dateInfo,
      'description': description,
      'iconName': iconName,
      'image': image,
    };
  }

  factory DynamicEvent.fromJson(Map<String, dynamic> json) {
    return DynamicEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      dateInfo: json['dateInfo'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String,
      image: json['image'] as String?,
    );
  }
}

class DynamicRoom {
  final String id;
  final String title;
  final String category;
  final String description;
  final String? image; // URL ou Base64 String
  final List<String> amenities;

  DynamicRoom({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.image,
    required this.amenities,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'image': image,
      'amenities': amenities,
    };
  }

  factory DynamicRoom.fromJson(Map<String, dynamic> json) {
    return DynamicRoom(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      image: json['image'] as String?,
      amenities: List<String>.from(json['amenities'] as List<dynamic>),
    );
  }
}

class GalleryPhoto {
  final String id;
  final String image; // URL ou Base64 String
  final String? title;
  final String sector; // 'gallery', 'hero', 'about', 'rooms', 'mineral', 'events'
  final String? subSector; // 'standard', 'luxo', 'familiar' ou ID do quarto/evento específico

  GalleryPhoto({
    required this.id,
    required this.image,
    this.title,
    this.sector = 'gallery',
    this.subSector,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'title': title,
      'sector': sector,
      'subSector': subSector,
    };
  }

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) {
    return GalleryPhoto(
      id: json['id'] as String,
      image: json['image'] as String,
      title: json['title'] as String?,
      sector: (json['sector'] as String?) ?? 'gallery',
      subSector: json['subSector'] as String?,
    );
  }
}

class DynamicContentService {
  static const String _eventsKey = 'raposo_dynamic_events';
  static const String _photosKey = 'raposo_dynamic_photos';
  static const String _roomsKey = 'raposo_dynamic_rooms';

  List<DynamicEvent> _events = [];
  List<GalleryPhoto> _photos = [];
  List<DynamicRoom> _rooms = [];
  SharedPreferences? _prefs;
  bool _initialized = false;

  List<DynamicEvent> get events => List.unmodifiable(_events);
  List<GalleryPhoto> get photos => List.unmodifiable(_photos);
  List<DynamicRoom> get rooms => List.unmodifiable(_rooms);

  // Mapeamento de nomes de ícones para IconData do Flutter
  static IconData getIconByName(String name) {
    switch (name) {
      case 'church':
        return Icons.church_outlined;
      case 'pool':
        return Icons.pool_rounded;
      case 'nature':
        return Icons.nature_people_outlined;
      case 'celebration':
        return Icons.celebration_outlined;
      case 'favorite':
        return Icons.favorite_border_rounded;
      case 'people':
        return Icons.people_outline_rounded;
      case 'sports':
        return Icons.emoji_events_outlined;
      case 'food':
        return Icons.restaurant_menu_rounded;
      case 'music':
        return Icons.music_note_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  // Lista com metadados dos ícones para exibição no painel administrativo
  static List<Map<String, dynamic>> get availableIcons => [
        {'name': 'church', 'icon': Icons.church_outlined, 'label': 'Igreja'},
        {'name': 'pool', 'icon': Icons.pool_rounded, 'label': 'Piscina / Lazer'},
        {'name': 'nature', 'icon': Icons.nature_people_outlined, 'label': 'Natureza'},
        {'name': 'celebration', 'icon': Icons.celebration_outlined, 'label': 'Celebração'},
        {'name': 'favorite', 'icon': Icons.favorite_border_rounded, 'label': 'Coração / Família'},
        {'name': 'people', 'icon': Icons.people_outline_rounded, 'label': 'Social / Idosos'},
        {'name': 'sports', 'icon': Icons.emoji_events_outlined, 'label': 'Esportes / Gincana'},
        {'name': 'food', 'icon': Icons.restaurant_menu_rounded, 'label': 'Gastronomia'},
        {'name': 'music', 'icon': Icons.music_note_outlined, 'label': 'Música'},
      ];

  // Comodidades sugeridas para quartos
  static List<String> get availableAmenities => [
        'Wi-Fi',
        'Ar-condicionado',
        'Frigobar',
        'TV',
        'Piscina',
        'Varanda',
        'Jacuzzi',
        'Cama King',
        'Vista para o Lago',
        'Cozinha Americana',
      ];

  // Singleton
  static final DynamicContentService _instance = DynamicContentService._internal();
  factory DynamicContentService() => _instance;
  DynamicContentService._internal();

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    await _loadEvents();
    await _loadPhotos();
    await _loadRooms();
    
    _initialized = true;
  }

  Future<void> _loadEvents() async {
    final String? eventsJson = _prefs?.getString(_eventsKey);
    if (eventsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(eventsJson) as List<dynamic>;
        _events = decoded
            .map((item) => DynamicEvent.fromJson(item as Map<String, dynamic>))
            .toList();
        return;
      } catch (e) {
        debugPrint('Erro ao decodificar eventos: $e');
      }
    }
    _events = _getDefaultEvents();
    await _saveEventsToPrefs();
  }

  Future<void> _loadPhotos() async {
    final String? photosJson = _prefs?.getString(_photosKey);
    if (photosJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(photosJson) as List<dynamic>;
        _photos = decoded
            .map((item) => GalleryPhoto.fromJson(item as Map<String, dynamic>))
            .toList();
        return;
      } catch (e) {
        debugPrint('Erro ao decodificar fotos: $e');
      }
    }
    _photos = _getDefaultPhotos();
    await _savePhotosToPrefs();
  }

  Future<void> _loadRooms() async {
    final String? roomsJson = _prefs?.getString(_roomsKey);
    if (roomsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(roomsJson) as List<dynamic>;
        _rooms = decoded
            .map((item) => DynamicRoom.fromJson(item as Map<String, dynamic>))
            .toList();
        return;
      } catch (e) {
        debugPrint('Erro ao decodificar quartos: $e');
      }
    }
    _rooms = _getDefaultRooms();
    await _saveRoomsToPrefs();
  }

  Future<void> _saveEventsToPrefs() async {
    if (_prefs == null) return;
    final List<Map<String, dynamic>> jsonList = _events.map((e) => e.toJson()).toList();
    await _prefs!.setString(_eventsKey, jsonEncode(jsonList));
  }

  Future<void> _savePhotosToPrefs() async {
    if (_prefs == null) return;
    final List<Map<String, dynamic>> jsonList = _photos.map((p) => p.toJson()).toList();
    await _prefs!.setString(_photosKey, jsonEncode(jsonList));
  }

  Future<void> _saveRoomsToPrefs() async {
    if (_prefs == null) return;
    final List<Map<String, dynamic>> jsonList = _rooms.map((r) => r.toJson()).toList();
    await _prefs!.setString(_roomsKey, jsonEncode(jsonList));
  }

  // --- MÉTODOS DE GERENCIAMENTO ---

  // Eventos
  Future<void> addEvent(DynamicEvent event) async {
    _events.insert(0, event);
    await _saveEventsToPrefs();
  }

  Future<void> removeEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    await _saveEventsToPrefs();
  }

  // Quartos (Acomodações)
  Future<void> addRoom(DynamicRoom room) async {
    _rooms.insert(0, room);
    await _saveRoomsToPrefs();
  }

  Future<void> removeRoom(String id) async {
    _rooms.removeWhere((r) => r.id == id);
    await _saveRoomsToPrefs();
  }

  // Fotos da Galeria Setorial
  Future<void> addPhoto(GalleryPhoto photo) async {
    _photos.insert(0, photo);
    await _savePhotosToPrefs();
  }

  Future<void> removePhoto(String id) async {
    _photos.removeWhere((p) => p.id == id);
    await _savePhotosToPrefs();
  }

  // Busca a imagem customizada cadastrada pelo admin para um determinado setor/subsetor
  String? getImageForSector(String sector, {String? subSector}) {
    try {
      final matching = _photos.where((p) {
        if (subSector != null) {
          return p.sector == sector && p.subSector == subSector;
        }
        return p.sector == sector;
      }).toList();

      if (matching.isNotEmpty) {
        return matching.first.image; // Retorna a mais recente (primeira da lista)
      }
    } catch (e) {
      debugPrint('Erro ao buscar imagem para o setor $sector: $e');
    }
    return null;
  }

  // --- DADOS PADRÃO INICIAIS ---

  List<DynamicEvent> _getDefaultEvents() {
    return [
      DynamicEvent(
        id: 'default_event_1',
        title: 'Congresso da Igreja Batista',
        dateInfo: 'Agendado Anualmente',
        description: 'Um encontro abençoado com infraestrutura de auditório, hospedagem completa e momentos de profunda comunhão e paz espiritual.',
        iconName: 'church',
      ),
      DynamicEvent(
        id: 'default_event_2',
        title: 'Páscoa no Hotel Fazenda',
        dateInfo: 'Todo mês de Abril',
        description: 'Tempo de reflexão, paz em família e muita diversão com caça aos ovos de Páscoa, culinária especial e brincadeiras ao ar livre.',
        iconName: 'favorite',
      ),
      DynamicEvent(
        id: 'default_event_3',
        title: 'Semana da Melhor Idade',
        dateInfo: 'Outubro Especial',
        description: 'Com o lema de celebrar a vida, oferecemos bailes, ginástica de baixo impacto, bingo, banhos terapêuticos e muita alegria.',
        iconName: 'people',
      ),
      DynamicEvent(
        id: 'default_event_4',
        title: 'Gincanas e Atividades',
        dateInfo: 'Todos os Fins de Semana',
        description: 'Uma competição esportiva e divertida liderada por nossos recreadores para integração e união de todas as famílias.',
        iconName: 'sports',
      ),
    ];
  }

  List<DynamicRoom> _getDefaultRooms() {
    return [
      DynamicRoom(
        id: 'room_standard',
        title: 'Apartamento Standard',
        category: 'Ala Externa',
        description: 'Acomodações acolhedoras equipadas com TV, frigobar, ar-condicionado silencioso e banheiro privativo. Ideal para casais ou estadias econômicas.',
        amenities: ['Wi-Fi', 'Ar-condicionado', 'Frigobar', 'TV'],
      ),
      DynamicRoom(
        id: 'room_luxo',
        title: 'Suíte Luxo',
        category: 'Ala Interna',
        description: 'Quarto requintado com cama de casal king-size, enxoval premium, frigobar retrô, TV digital, varanda privativa com vista panorâmica para o lago e decoração rústica refinada.',
        amenities: ['Wi-Fi', 'Ar-condicionado', 'Frigobar', 'TV', 'Piscina'],
      ),
      DynamicRoom(
        id: 'room_familiar',
        title: 'Apartamento Familiar',
        category: 'Alas Integradas',
        description: 'Unidades amplas e confortáveis planejadas para até 5 pessoas. Possuem múltiplos ambientes, ar-condicionado de alta potência, frigobar familiar e TV inteligente.',
        amenities: ['Wi-Fi', 'Ar-condicionado', 'Frigobar', 'TV'],
      ),
    ];
  }

  List<GalleryPhoto> _getDefaultPhotos() {
    return [
      GalleryPhoto(
        id: 'default_photo_1',
        image: 'assets/images/hero_resort.png',
        title: 'Vista aérea do Hotel Fazenda Raposo',
        sector: 'gallery',
      ),
      GalleryPhoto(
        id: 'default_photo_2',
        image: 'assets/images/lazer_resort.png',
        title: 'Atividades de lazer e piscinas integradas',
        sector: 'gallery',
      ),
      GalleryPhoto(
        id: 'default_photo_3',
        image: 'assets/images/suite_luxo.png',
        title: 'Suíte Luxo com vista panorâmica',
        sector: 'gallery',
      ),
      GalleryPhoto(
        id: 'default_photo_4',
        image: 'assets/images/fontanario.png',
        title: 'Fontanário próprio de águas termais',
        sector: 'gallery',
      ),
    ];
  }
}
