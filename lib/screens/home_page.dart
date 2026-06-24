import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/navbar.dart';
import '../widgets/booking_bar.dart';
import '../widgets/room_card.dart';
import '../widgets/event_card.dart';
import '../widgets/footer.dart';
import '../widgets/reservation_form.dart';
import '../services/dynamic_content_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  
  // Chaves globais para scroll das seções
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _roomsKey = GlobalKey();
  final GlobalKey _mineralWaterKey = GlobalKey();
  final GlobalKey _leisureKey = GlobalKey();
  final GlobalKey _galleryKey = GlobalKey();
  final GlobalKey _eventsKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  int _activeIndex = 0;

  // Serviço de conteúdo dinâmico
  final DynamicContentService _contentService = DynamicContentService();
  List<DynamicEvent> _dynamicEvents = [];
  List<GalleryPhoto> _dynamicPhotos = [];
  List<DynamicRoom> _dynamicRooms = [];
  bool _contentLoading = true;

  // Controladores do Formulário de Contato
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDynamicContent();
  }

  Future<void> _loadDynamicContent() async {
    setState(() {
      _contentLoading = true;
    });
    await _contentService.init();
    if (mounted) {
      setState(() {
        _dynamicEvents = _contentService.events;
        _dynamicPhotos = _contentService.photos;
        _dynamicRooms = _contentService.rooms;
        _contentLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Detecta qual seção está visível na tela
  void _onScroll() {
    if (!mounted) return;
    double scrollOffset = _scrollController.offset;
    
    // Obter offsets aproximados de cada seção
    double aboutOffset = _getOffsetFor(context, _aboutKey) - 120;
    double roomsOffset = _getOffsetFor(context, _roomsKey) - 120;
    double mineralOffset = _getOffsetFor(context, _mineralWaterKey) - 120;
    double leisureOffset = _getOffsetFor(context, _leisureKey) - 120;
    double galleryOffset = _getOffsetFor(context, _galleryKey) - 120;
    double eventsOffset = _getOffsetFor(context, _eventsKey) - 120;
    double contactOffset = _getOffsetFor(context, _contactKey) - 120;

    int newIndex = 0;
    if (scrollOffset >= contactOffset) {
      newIndex = 7;
    } else if (scrollOffset >= eventsOffset) {
      newIndex = 6;
    } else if (scrollOffset >= galleryOffset) {
      newIndex = 5;
    } else if (scrollOffset >= leisureOffset) {
      newIndex = 4;
    } else if (scrollOffset >= mineralOffset) {
      newIndex = 3;
    } else if (scrollOffset >= roomsOffset) {
      newIndex = 2;
    } else if (scrollOffset >= aboutOffset) {
      newIndex = 1;
    }

    if (newIndex != _activeIndex) {
      setState(() {
        _activeIndex = newIndex;
      });
    }
  }

  double _getOffsetFor(BuildContext context, GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      return renderBox.localToGlobal(Offset.zero).dy + _scrollController.offset;
    }
    return 0.0;
  }

  void _scrollToSection(int index) {
    if (index == -1) {
      _loadDynamicContent();
      return;
    }
    GlobalKey targetKey;
    switch (index) {
      case 0:
        targetKey = _heroKey;
        break;
      case 1:
        targetKey = _aboutKey;
        break;
      case 2:
        targetKey = _roomsKey;
        break;
      case 3:
        targetKey = _mineralWaterKey;
        break;
      case 4:
        targetKey = _leisureKey;
        break;
      case 5:
        targetKey = _galleryKey;
        break;
      case 6:
        targetKey = _eventsKey;
        break;
      case 7:
        targetKey = _contactKey;
        break;
      default:
        targetKey = _heroKey;
    }

    final context = targetKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openGoogleMaps() async {
    final Uri url = Uri.parse('https://maps.google.com/?q=Hotel+Fazenda+Raposo+Itaperuna+RJ');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _submitContactForm() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: HotelColors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Mensagem Enviada!',
                style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen),
              ),
            ],
          ),
          content: Text(
            'Obrigado pelo seu contato, ${_nameController.text}! Nossa equipe responderá em breve no seu e-mail.',
            style: HotelTypography.bodyText(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _nameController.clear();
                  _emailController.clear();
                  _subjectController.clear();
                  _messageController.clear();
                });
              },
              child: Text(
                'Fechar',
                style: HotelTypography.buttonText.copyWith(color: HotelColors.accentGold),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: HotelColors.bgLight,
      drawer: isMobile ? _buildDrawer() : null,
      body: Stack(
        children: [
          // Conteúdo rolável principal
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Top Padding para não cobrir o conteúdo inicial com o navbar
                const SizedBox(height: 80),
                
                // Seções
                _buildHeroSection(screenWidth),
                _buildAboutSection(screenWidth),
                _buildRoomsSection(screenWidth),
                _buildMineralWaterSection(screenWidth),
                _buildLeisureSection(screenWidth),
                _buildGallerySection(screenWidth),
                _buildEventsSection(screenWidth),
                _buildContactSection(screenWidth),
                Footer(onNavItemTap: (index) {
                  _scrollToSection(index);
                }),
              ],
            ),
          ),

          // Navbar Superior Fixa (Frosted Glass)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Navbar(
              activeIndex: _activeIndex,
              onNavItemTap: (index) {
                if (isMobile && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                _scrollToSection(index);
              },
              onReserveTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const ReservationForm(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Drawer para navegação mobile
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: HotelColors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
            color: HotelColors.primaryGreen,
            child: Row(
              children: [
                const Icon(Icons.nature_people_rounded, color: HotelColors.accentGold, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hotel Fazenda Raposo',
                    style: HotelTypography.cardTitle.copyWith(color: HotelColors.white, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildDrawerItem('O Hotel', 1),
                _buildDrawerItem('Acomodações', 2),
                _buildDrawerItem('Água Mineral', 3),
                _buildDrawerItem('Lazer', 4),
                _buildDrawerItem('Galeria', 5),
                _buildDrawerItem('Eventos', 6),
                _buildDrawerItem('Contato', 7),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: HotelColors.lightGrey)),
            ),
            child: Text(
              'A Central de Reservas\n(22) 99991-2144',
              style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.primaryGreen, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String label, int index) {
    return ListTile(
      leading: Icon(
        index == 1
            ? Icons.info_outline
            : index == 2
                ? Icons.bed_outlined
                : index == 3
                    ? Icons.water_drop_outlined
                    : index == 4
                        ? Icons.pool
                        : index == 5
                            ? Icons.photo_library_outlined
                            : index == 6
                                ? Icons.event_note
                                : Icons.phone_callback,
        color: _activeIndex == index ? HotelColors.accentGold : HotelColors.primaryGreen,
      ),
      title: Text(
        label,
        style: HotelTypography.navItem.copyWith(
          color: _activeIndex == index ? HotelColors.accentGold : HotelColors.primaryGreen,
          fontWeight: _activeIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        _scrollToSection(index);
      },
    );
  }

  // 1. HERO SECTION
  Widget _buildHeroSection(double screenWidth) {
    bool isSmallScreen = screenWidth < 800;

    return Container(
      key: _heroKey,
      height: isSmallScreen ? 500 : 680,
      width: double.infinity,
      child: Stack(
        children: [
          // Imagem de Fundo (Drone do Hotel)
          _buildSectorImage(
            'hero',
            fallbackAssetPath: 'assets/images/hero_resort.png',
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          // Overlay Degradê Escuro
          Container(
            decoration: const BoxDecoration(
              gradient: HotelColors.heroGradient,
            ),
          ),
          // Texto e Booking Widget
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: HotelColors.accentGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(color: HotelColors.accentGold, width: 1.0),
                    ),
                    child: Text(
                      'CONHEÇA O PARAÍSO DAS ÁGUAS TERMAIS',
                      style: HotelTypography.cardSubtitle.copyWith(
                        color: HotelColors.accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Hotel Fazenda Raposo',
                    style: HotelTypography.heroTitle(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seu refúgio de paz, lazer e águas terapêuticas no interior do Rio de Janeiro',
                    style: HotelTypography.bodyText(color: HotelColors.white.withOpacity(0.9)).copyWith(
                      fontSize: isSmallScreen ? 16 : 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Simulador de Reserva acoplado na base do Hero
                  const BookingBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. ABOUT SECTION (O Hotel)
  Widget _buildAboutSection(double screenWidth) {
    bool isSmallScreen = screenWidth < 900;

    return Container(
      key: _aboutKey,
      color: HotelColors.white,
      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isSmallScreen
              ? Column(
                  children: [
                    _buildAboutText(),
                    const SizedBox(height: 40),
                    _buildAboutImage(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildAboutText()),
                    const SizedBox(width: 80),
                    Expanded(child: _buildAboutImage()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAboutText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O HOTEL FAZENDA RAPOSO',
          style: HotelTypography.cardSubtitle,
        ),
        const SizedBox(height: 12),
        Text(
          'Um refúgio verde integrado à natureza',
          style: HotelTypography.sectionTitle(context),
        ),
        const SizedBox(height: 24),
        Text(
          'O Hotel Fazenda Raposo integra-se à natureza numa área de 1.500.000 m² de muito verde, com lago natural e fonte própria de água mineral reconhecida por suas qualidades terapêuticas.',
          style: HotelTypography.bodyText(),
        ),
        const SizedBox(height: 16),
        Text(
          'Com uma vasta área de lazer, recreação e eventos para todos os finais de semana, somos o destino perfeito para quem busca escapar da rotina urbana. Aqui, a atmosfera é de paz, tranquilidade e harmonia absoluta entre o homem e o verde.',
          style: HotelTypography.bodyText(),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _buildStatItem('1.5M m²', 'Área Verde'),
            const SizedBox(width: 32),
            _buildStatItem('+10', 'Atividades Lazer'),
            const SizedBox(width: 32),
            _buildStatItem('100%', 'Água Mineral'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: HotelTypography.cardTitle.copyWith(
            color: HotelColors.accentGold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAboutImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: HotelColors.primaryGreen.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: _buildSectorImage(
          'about',
          fallbackAssetPath: 'assets/images/lazer_resort.png',
          height: 400,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // 3. ACCOMMODATIONS SECTION
  Widget _buildRoomsSection(double screenWidth) {
    bool isSmallScreen = screenWidth < 900;
    bool isTablet = screenWidth >= 600 && screenWidth < 1000;

    return Container(
      key: _roomsKey,
      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'ACOMODAÇÕES CONFORTÁVEIS',
                style: HotelTypography.cardSubtitle,
              ),
              const SizedBox(height: 12),
              Text(
                'Encontre o Quarto Ideal para o seu Descanso',
                style: HotelTypography.sectionTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Grid de Quartos
              isSmallScreen
                  ? Column(
                      children: _buildRoomCards(),
                    )
                  : GridView.count(
                      crossAxisCount: isTablet ? 2 : 3,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.65,
                      children: _buildRoomCards(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoomCards() {
    if (_contentLoading) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(color: HotelColors.primaryGreen),
          ),
        ),
      ];
    }
    if (_dynamicRooms.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              'Nenhuma acomodação cadastrada no momento.',
              style: HotelTypography.bodyText(),
            ),
          ),
        ),
      ];
    }

    List<Widget> cards = _dynamicRooms.map((room) {
      String imagePath = room.image ?? '';
      
      if (imagePath.isEmpty) {
        imagePath = _contentService.getImageForSector('rooms', subSector: room.id) ?? '';
      }
      
      if (imagePath.isEmpty) {
        if (room.id == 'room_standard') {
          imagePath = 'assets/images/hero_resort.png';
        } else if (room.id == 'room_luxo') {
          imagePath = 'assets/images/suite_luxo.png';
        } else if (room.id == 'room_familiar') {
          imagePath = 'assets/images/lazer_resort.png';
        } else {
          imagePath = 'assets/images/hero_resort.png';
        }
      }

      return RoomCard(
        title: room.title,
        category: room.category,
        imagePath: imagePath,
        description: room.description,
        amenities: room.amenities,
      );
    }).toList();

    // Adiciona padding no mobile para separar os cards empilhados
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 900) {
      return cards.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: c,
        ),
      )).toList();
    }
    return cards;
  }

  // 4. ÁGUA MINERAL RAPOSO
  Widget _buildMineralWaterSection(double screenWidth) {
    bool isSmallScreen = screenWidth < 900;

    return Container(
      key: _mineralWaterKey,
      decoration: const BoxDecoration(
        gradient: HotelColors.mineralGradient,
      ),
      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isSmallScreen
              ? Column(
                  children: [
                    _buildMineralImage(),
                    const SizedBox(height: 40),
                    _buildMineralText(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildMineralImage()),
                    const SizedBox(width: 80),
                    Expanded(child: _buildMineralText()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMineralImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: _buildSectorImage(
          'mineral',
          fallbackAssetPath: 'assets/images/fontanario.png',
          height: 400,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMineralText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ÁGUA MINERAL TERAPÊUTICA',
          style: HotelTypography.cardSubtitle.copyWith(color: Colors.blueGrey),
        ),
        const SizedBox(height: 12),
        Text(
          'Fontanário Próprio com Benefícios à Saúde',
          style: HotelTypography.sectionTitle(context, color: Colors.blueGrey.shade800),
        ),
        const SizedBox(height: 24),
        Text(
          'Em parceria histórica com a tradicional Água Mineral Raposo, o Hotel Fazenda Raposo oferece a seus hóspedes o privilégio único de usufruir de um fontanário próprio dentro do nosso complexo.',
          style: HotelTypography.bodyText(color: Colors.blueGrey.shade700),
        ),
        const SizedBox(height: 16),
        Text(
          'A famosa Água de Raposo possui propriedades terapêuticas cientificamente comprovadas, sendo indicada para tratamentos renais, do fígado, distúrbios digestivos, além de dermatoses. Um banho de saúde e relaxamento no seu final de semana.',
          style: HotelTypography.bodyText(color: Colors.blueGrey.shade700),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => _scrollToSection(6), // Rola para contato
          icon: const Icon(Icons.arrow_downward, size: 18),
          label: Text('Consulte nossas tarifas e viva essa experiência', style: HotelTypography.buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: HotelColors.primaryGreen,
            foregroundColor: HotelColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
          ),
        ),
      ],
    );
  }

  // 5. LEISURE SECTION
  Widget _buildLeisureSection(double screenWidth) {
    bool isSmallScreen = screenWidth < 800;

    return Container(
      key: _leisureKey,
      color: HotelColors.white,
      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'LAZER COMPLETO PARA A FAMÍLIA',
                style: HotelTypography.cardSubtitle,
              ),
              const SizedBox(height: 12),
              Text(
                'Atividades no Campo para Todas as Idades',
                style: HotelTypography.sectionTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Grid de Lazer
              isSmallScreen
                  ? Column(
                      children: _buildLeisureItems(),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 32,
                      mainAxisSpacing: 32,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.6,
                      children: _buildLeisureItems(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLeisureItems() {
    return [
      _buildLeisureCard(
        title: 'Lago com Pedalinhos',
        description: 'Um belíssimo lago natural onde os hóspedes podem passear de pedalinho e contemplar a natureza.',
        icon: Icons.sailing,
        subSector: 'lago',
        fallbackImage: 'assets/images/hero_resort.png',
      ),
      _buildLeisureCard(
        title: 'Piscinas Externas',
        description: 'Piscinas de águas cristalinas com deck integrado para aproveitar os dias de sol no interior fluminense.',
        icon: Icons.pool_rounded,
        subSector: 'piscina',
        fallbackImage: 'assets/images/lazer_resort.png',
      ),
      _buildLeisureCard(
        title: 'Cavalgada & Trilhas',
        description: 'Passeios a cavalo orientados por monitores experientes pelas nossas trilhas ecológicas.',
        icon: Icons.pets_rounded,
        subSector: 'cavalgada',
        fallbackImage: 'assets/images/hero_resort.png',
      ),
      _buildLeisureCard(
        title: 'Recreação aos Finais de Semana',
        description: 'Equipe de recreadores animando as crianças e adultos com gincanas, desafios esportivos e diversão.',
        icon: Icons.celebration,
        subSector: 'recreacao',
        fallbackImage: 'assets/images/lazer_resort.png',
      ),
    ];
  }

  Widget _buildLeisureCard({
    required String title,
    required String description,
    required IconData icon,
    required String subSector,
    required String fallbackImage,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;
    
    final customImage = _contentService.getImageForSector('leisure', subSector: subSector);
    final imageToShow = customImage ?? fallbackImage;
    
    // Elemento de Imagem com Ícone flutuante sobreposto
    Widget imageWidget = Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: _buildLeisureItemImage(
            imageToShow,
            height: isMobile ? 180 : 130,
            width: isMobile ? double.infinity : 180,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: HotelColors.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: HotelColors.white, size: 16),
          ),
        ),
      ],
    );

    Widget card = Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: HotelColors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: HotelColors.lightGrey, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: HotelColors.primaryGreen.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageWidget,
                const SizedBox(height: 16),
                Text(title, style: HotelTypography.cardTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: HotelTypography.bodyTextSmall.copyWith(fontSize: 13, height: 1.4),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                imageWidget,
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: HotelTypography.cardTitle.copyWith(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: HotelTypography.bodyTextSmall.copyWith(fontSize: 13, height: 1.4),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: card,
      );
    }
    return card;
  }

  // 6. EVENTS SECTION
  Widget _buildEventsSection(double screenWidth) {
    bool isSmallScreen = screenWidth < 900;
    bool isTablet = screenWidth >= 600 && screenWidth < 1000;

    return Container(
      key: _eventsKey,
      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'PROGRAMAÇÃO & EVENTOS',
                style: HotelTypography.cardSubtitle,
              ),
              const SizedBox(height: 12),
              Text(
                'Momentos Marcantes do Hotel Fazenda',
                style: HotelTypography.sectionTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Grid de Eventos
              isSmallScreen
                  ? Column(
                      children: _buildEventCards(),
                    )
                  : GridView.count(
                      crossAxisCount: isTablet ? 2 : 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.68,
                      children: _buildEventCards(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEventCards() {
    if (_contentLoading) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(color: HotelColors.primaryGreen),
          ),
        ),
      ];
    }
    if (_dynamicEvents.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              'Nenhum evento agendado no momento.',
              style: HotelTypography.bodyText(),
            ),
          ),
        ),
      ];
    }

    List<Widget> cards = _dynamicEvents.map((event) {
      return EventCard(
        title: event.title,
        dateInfo: event.dateInfo,
        description: event.description,
        icon: event.icon,
        image: event.image,
      );
    }).toList();

    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 900) {
      return cards.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: c,
        ),
      )).toList();
    }
    return cards;
  }

  // 7. CONTACT & MAP SECTION
  Widget _buildContactSection(double screenWidth) {
    bool isSmallScreen = screenWidth < 900;

    return Container(
      key: _contactKey,
      color: HotelColors.white,
      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isSmallScreen
              ? Column(
                  children: [
                    _buildContactForm(),
                    const SizedBox(height: 48),
                    _buildMapCard(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildContactForm()),
                    const SizedBox(width: 80),
                    Expanded(flex: 4, child: _buildMapCard()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENVIE UMA MENSAGEM',
            style: HotelTypography.cardSubtitle,
          ),
          const SizedBox(height: 12),
          Text(
            'Entre em contato com nossa equipe',
            style: HotelTypography.sectionTitle(context),
          ),
          const SizedBox(height: 32),
          
          // Nome Campo
          TextFormField(
            controller: _nameController,
            style: HotelTypography.bodyText(color: HotelColors.darkSlate),
            decoration: _getInputDecoration('Nome Completo', Icons.person_outline),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Por favor, informe seu nome.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // E-mail Campo
          TextFormField(
            controller: _emailController,
            style: HotelTypography.bodyText(color: HotelColors.darkSlate),
            decoration: _getInputDecoration('Seu E-mail', Icons.mail_outline),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Por favor, informe seu e-mail.';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Insira um e-mail válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Assunto Campo
          TextFormField(
            controller: _subjectController,
            style: HotelTypography.bodyText(color: HotelColors.darkSlate),
            decoration: _getInputDecoration('Assunto', Icons.info_outline),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Por favor, informe o assunto.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Mensagem Campo
          TextFormField(
            controller: _messageController,
            style: HotelTypography.bodyText(color: HotelColors.darkSlate),
            decoration: _getInputDecoration('Mensagem', Icons.message_outlined).copyWith(
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Por favor, digite sua mensagem.';
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Botão Enviar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitContactForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: HotelColors.primaryGreen,
                foregroundColor: HotelColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                elevation: 0,
              ),
              child: Text('ENVIAR MENSAGEM', style: HotelTypography.buttonText),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: HotelTypography.bodyTextSmall,
      prefixIcon: Icon(icon, color: HotelColors.accentGold, size: 20),
      filled: true,
      fillColor: HotelColors.bgLight,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: HotelColors.accentGold, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: HotelColors.lightGrey, width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      decoration: BoxDecoration(
        color: HotelColors.bgLight,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: HotelColors.lightGrey, width: 1.0),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOSSA LOCALIZAÇÃO',
            style: HotelTypography.cardSubtitle,
          ),
          const SizedBox(height: 12),
          Text(
            'Venha nos Visitar',
            style: HotelTypography.sectionTitle(context),
          ),
          const SizedBox(height: 20),
          Text(
            'Estamos localizados no coração de Raposo, distrito de Itaperuna - RJ. Uma localidade famosa em todo o país por seu clima de calmaria e suas excelentes estâncias de águas minerais hidrotermais.',
            style: HotelTypography.bodyText(),
          ),
          const SizedBox(height: 32),
          
          // Container Simulando o Mapa com Imagem do Resort ou Ilustração
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              image: const DecorationImage(
                image: AssetImage('assets/images/fontanario.png'),
                fit: BoxFit.cover,
                opacity: 0.6,
              ),
              border: Border.all(color: HotelColors.lightGrey),
            ),
            child: Stack(
              children: [
                Container(
                  color: HotelColors.primaryGreen.withOpacity(0.35),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: HotelColors.accentGold, size: 48),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: HotelColors.white,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          'Avenida Augusto Maria Martinez Toja, 224',
                          style: HotelTypography.bodyTextSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: HotelColors.primaryGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Botão Ver no Google Maps
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _openGoogleMaps,
              icon: const Icon(Icons.map_outlined),
              label: Text('ABRIR NO GOOGLE MAPS', style: HotelTypography.buttonText),
              style: OutlinedButton.styleFrom(
                foregroundColor: HotelColors.primaryGreen,
                side: const BorderSide(color: HotelColors.primaryGreen, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS E WIDGETS DA GALERIA DINÂMICA ---

  Widget _buildGalleryImage(String image, {required double height, required BoxFit fit}) {
    if (image.startsWith('assets/')) {
      return Image.asset(image, height: height, width: double.infinity, fit: fit);
    } else if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildGalleryPlaceholder(height),
      );
    } else {
      try {
        String base64Str = image;
        if (image.contains(',')) {
          base64Str = image.split(',')[1];
        }
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, height: height, width: double.infinity, fit: fit);
      } catch (e) {
        return _buildGalleryPlaceholder(height);
      }
    }
  }

  Widget _buildGalleryPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: HotelColors.primaryGreen.withOpacity(0.05),
      child: const Icon(Icons.image_not_supported_outlined, color: HotelColors.accentGold, size: 32),
    );
  }

  void _openLightbox(int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        int currentIndex = initialIndex;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final photo = _dynamicPhotos[currentIndex];
            return Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: _buildGalleryImage(photo.image, height: double.infinity, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ),
                if (photo.title != null && photo.title!.isNotEmpty)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            photo.title!,
                            style: HotelTypography.bodyText(color: Colors.white).copyWith(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (currentIndex > 0)
                  Positioned(
                    left: 24,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 40),
                          onPressed: () {
                            setDialogState(() {
                              currentIndex--;
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.3),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (currentIndex < _dynamicPhotos.length - 1)
                  Positioned(
                    right: 24,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white, size: 40),
                          onPressed: () {
                            setDialogState(() {
                              currentIndex++;
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.3),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGallerySection(double screenWidth) {
    bool isSmallScreen = screenWidth < 600;
    bool isTablet = screenWidth >= 600 && screenWidth < 900;
    
    return Container(
      key: _galleryKey,
      color: HotelColors.bgLight,
      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'VEJA NOSSAS FOTOS',
                style: HotelTypography.cardSubtitle,
              ),
              const SizedBox(height: 12),
              Text(
                'Galeria de Fotos do Hotel Fazenda',
                style: HotelTypography.sectionTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _contentLoading
                  ? const Center(child: CircularProgressIndicator(color: HotelColors.primaryGreen))
                  : _dynamicPhotos.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Text('Nenhuma foto cadastrada na galeria.', style: HotelTypography.bodyText()),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _dynamicPhotos.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isSmallScreen ? 2 : (isTablet ? 3 : 4),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemBuilder: (context, index) {
                            final photo = _dynamicPhotos[index];
                            return _GalleryCard(
                              photo: photo,
                              onTap: () => _openLightbox(index),
                              buildImage: (img) => _buildGalleryImage(img, height: double.infinity, fit: BoxFit.cover),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectorImage(
    String sector, {
    required String fallbackAssetPath,
    required double height,
    required double width,
    required BoxFit fit,
  }) {
    final customImage = _contentService.getImageForSector(sector);
    if (customImage == null || customImage.isEmpty) {
      return Image.asset(
        fallbackAssetPath,
        height: height,
        width: width,
        fit: fit,
      );
    }

    if (customImage.startsWith('assets/')) {
      return Image.asset(
        customImage,
        height: height,
        width: width,
        fit: fit,
      );
    } else if (customImage.startsWith('http://') || customImage.startsWith('https://')) {
      return Image.network(
        customImage,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          fallbackAssetPath,
          height: height,
          width: width,
          fit: fit,
        ),
      );
    } else {
      try {
        String base64Str = customImage;
        if (customImage.contains(',')) {
          base64Str = customImage.split(',')[1];
        }
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            fallbackAssetPath,
            height: height,
            width: width,
            fit: fit,
          ),
        );
      } catch (e) {
        return Image.asset(
          fallbackAssetPath,
          height: height,
          width: width,
          fit: fit,
        );
      }
    }
  }

  Widget _buildLeisureItemImage(
    String imagePath, {
    required double height,
    required double width,
    required BoxFit fit,
  }) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: height,
        width: width,
        fit: fit,
      );
    } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          width: width,
          color: HotelColors.primaryGreen.withOpacity(0.05),
          child: const Icon(Icons.image_not_supported_outlined, color: HotelColors.accentGold),
        ),
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
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height,
            width: width,
            color: HotelColors.primaryGreen.withOpacity(0.05),
            child: const Icon(Icons.image_not_supported_outlined, color: HotelColors.accentGold),
          ),
        );
      } catch (e) {
        return Container(
          height: height,
          width: width,
          color: HotelColors.primaryGreen.withOpacity(0.05),
          child: const Icon(Icons.image_not_supported_outlined, color: HotelColors.accentGold),
        );
      }
    }
  }
}

class _GalleryCard extends StatefulWidget {
  final GalleryPhoto photo;
  final VoidCallback onTap;
  final Widget Function(String) buildImage;

  const _GalleryCard({
    required this.photo,
    required this.onTap,
    required this.buildImage,
  });

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: HotelColors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: HotelColors.primaryGreen.withOpacity(_isHovered ? 0.12 : 0.04),
                blurRadius: _isHovered ? 24 : 12,
                offset: Offset(0, _isHovered ? 10 : 5),
              ),
            ],
            border: Border.all(
              color: _isHovered ? HotelColors.accentGold.withOpacity(0.5) : HotelColors.lightGrey,
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: widget.buildImage(widget.photo.image),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(_isHovered ? 0.7 : 0.4),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                if (widget.photo.title != null && widget.photo.title!.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      widget.photo.title!,
                      style: HotelTypography.bodyTextSmall.copyWith(
                        color: Colors.white,
                        fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
