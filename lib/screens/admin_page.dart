import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../services/dynamic_content_service.dart';
import '../services/image_helper.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DynamicContentService _contentService = DynamicContentService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _contentService.init();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper para renderizar miniaturas de imagens (URL, Asset, Base64)
  Widget _buildThumbnail(String imagePath, {double height = 80, double width = 80}) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, height: height, width: width, fit: BoxFit.cover);
    } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(height, width),
      );
    } else {
      try {
        String base64Str = imagePath;
        if (imagePath.contains(',')) {
          base64Str = imagePath.split(',')[1];
        }
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, height: height, width: width, fit: BoxFit.cover);
      } catch (e) {
        return _buildPlaceholder(height, width);
      }
    }
  }

  Widget _buildPlaceholder(double height, double width) {
    return Container(
      height: height,
      width: width,
      color: HotelColors.primaryGreen.withOpacity(0.05),
      child: const Icon(Icons.image_not_supported_outlined, color: HotelColors.accentGold, size: 24),
    );
  }

  // Métodos de adição
  void _openAddPhotoDialog() {
    String url = '';
    String? base64Data;
    String fileName = '';
    String? title;
    bool isUploading = false;
    String selectedSector = 'gallery';
    String? selectedSubSector;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickLocalFile() async {
              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                  withData: true, // Crucial para Web (carrega os bytes em memória)
                );

                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  if (file.bytes != null) {
                    setDialogState(() {
                      isUploading = true;
                      fileName = file.name;
                    });
                    
                    final compressedBytes = await ImageHelper.compressImageBytes(file.bytes!);
                    final base64String = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
                    
                    setDialogState(() {
                      base64Data = base64String;
                      url = ''; // Limpa URL se escolheu arquivo
                      isUploading = false;
                    });
                  }
                }
              } catch (e) {
                setDialogState(() {
                  isUploading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
                );
              }
            }

            final hasImageSelected = base64Data != null || url.isNotEmpty;

            return AlertDialog(
              backgroundColor: HotelColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Text(
                'Adicionar Foto no Site',
                style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        decoration: _getInputDecoration('Título / Legenda (Opcional)', Icons.title),
                        onChanged: (val) => title = val,
                      ),
                      const SizedBox(height: 16),
                      
                      // Seleção de Setor
                      DropdownButtonFormField<String>(
                        value: selectedSector,
                        decoration: _getInputDecoration('Setor do Site', Icons.category),
                        items: const [
                          DropdownMenuItem(value: 'gallery', child: Text('Galeria Geral')),
                          DropdownMenuItem(value: 'hero', child: Text('Banner Principal (Hero)')),
                          DropdownMenuItem(value: 'about', child: Text('O Hotel (Sobre)')),
                          DropdownMenuItem(value: 'rooms', child: Text('Acomodações')),
                          DropdownMenuItem(value: 'mineral', child: Text('Água Mineral')),
                          DropdownMenuItem(value: 'events', child: Text('Programação & Eventos')),
                        ],
                        onChanged: (val) {
                          setDialogState(() {
                            selectedSector = val ?? 'gallery';
                            selectedSubSector = null; // reseta subgrupo
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Recomendação de formato
                      Text(
                        _getRecommendationText(selectedSector),
                        style: HotelTypography.bodyTextSmall.copyWith(
                          color: HotelColors.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Sub-grupo condicional para Acomodações
                      if (selectedSector == 'rooms') ...[
                        DropdownButtonFormField<String?>(
                          value: selectedSubSector,
                          decoration: _getInputDecoration('Quarto Específico (Opcional)', Icons.bed),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Geral (Todas as Acomodações)')),
                            ..._contentService.rooms.map((room) => DropdownMenuItem<String?>(
                              value: room.id,
                              child: Text(room.title),
                            )),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              selectedSubSector = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Sub-grupo condicional para Eventos
                      if (selectedSector == 'events') ...[
                        DropdownButtonFormField<String?>(
                          value: selectedSubSector,
                          decoration: _getInputDecoration('Evento Específico (Opcional)', Icons.event_available),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Geral (Todos os Eventos)')),
                            ..._contentService.events.map((event) => DropdownMenuItem<String?>(
                              value: event.id,
                              child: Text(event.title),
                            )),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              selectedSubSector = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      Text(
                        'Escolha uma das formas de adicionar a imagem:',
                        style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      // Opção 1: Upload de Arquivo
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: isUploading ? null : pickLocalFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Carregar Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HotelColors.primaryGreen,
                              foregroundColor: HotelColors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              base64Data != null 
                                  ? '✓ $fileName' 
                                  : (isUploading ? 'Carregando...' : 'Sem arquivo'),
                              style: HotelTypography.bodyTextSmall.copyWith(
                                color: base64Data != null ? Colors.green : HotelColors.textGrey,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Center(
                        child: Text(
                          '— OU —',
                          style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.textGrey.withOpacity(0.5)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Opção 2: URL
                      TextField(
                        enabled: base64Data == null, // Desabilita se já tem upload local
                        decoration: _getInputDecoration(
                          'URL da Imagem na Internet',
                          Icons.link,
                          hintText: 'https://exemplo.com/foto.jpg',
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            url = val;
                          });
                        },
                      ),
                      
                      // Preview
                      if (hasImageSelected) ...[
                        const SizedBox(height: 20),
                        Text('Pré-visualização:', style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: _buildThumbnail(
                              base64Data ?? url,
                              height: 150,
                              width: 300,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar', style: HotelTypography.buttonText.copyWith(color: HotelColors.textGrey)),
                ),
                ElevatedButton(
                  onPressed: !hasImageSelected
                      ? null
                      : () async {
                          final photo = GalleryPhoto(
                            id: 'photo_${DateTime.now().millisecondsSinceEpoch}',
                            image: base64Data ?? url,
                            title: title,
                            sector: selectedSector,
                            subSector: selectedSubSector,
                          );
                          
                          setState(() => _isLoading = true);
                          try {
                            await _contentService.addPhoto(photo);
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Foto adicionada com sucesso!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao salvar foto: O limite de armazenamento do navegador foi atingido.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HotelColors.accentGold,
                    foregroundColor: HotelColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Publicar Foto', style: HotelTypography.buttonText),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAddEventDialog() {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    String dateInfo = '';
    String description = '';
    String selectedIconName = 'celebration';
    String url = '';
    String? base64Data;
    String fileName = '';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickLocalFile() async {
              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                  withData: true,
                );

                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  if (file.bytes != null) {
                    setDialogState(() {
                      isUploading = true;
                      fileName = file.name;
                    });
                    
                    final compressedBytes = await ImageHelper.compressImageBytes(file.bytes!);
                    final base64String = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
                    
                    setDialogState(() {
                      base64Data = base64String;
                      url = '';
                      isUploading = false;
                    });
                  }
                }
              } catch (e) {
                setDialogState(() {
                  isUploading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
                );
              }
            }

            final hasImageSelected = base64Data != null || url.isNotEmpty;

            return AlertDialog(
              backgroundColor: HotelColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Text(
                'Criar Novo Evento',
                style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: 500,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        TextFormField(
                          decoration: _getInputDecoration('Título do Evento', Icons.event),
                          validator: (value) => value == null || value.isEmpty ? 'Informe o título do evento.' : null,
                          onChanged: (val) => title = val,
                        ),
                        const SizedBox(height: 16),
                        
                        // Data
                        TextFormField(
                          decoration: _getInputDecoration('Data / Programação (Ex: Todo Sábado)', Icons.date_range),
                          validator: (value) => value == null || value.isEmpty ? 'Informe a data do evento.' : null,
                          onChanged: (val) => dateInfo = val,
                        ),
                        const SizedBox(height: 16),
                        
                        // Descrição
                        TextFormField(
                          decoration: _getInputDecoration('Descrição do Evento', Icons.description),
                          maxLines: 3,
                          validator: (value) => value == null || value.isEmpty ? 'Escreva uma breve descrição.' : null,
                          onChanged: (val) => description = val,
                        ),
                        const SizedBox(height: 20),
                        
                        // Ícone do Evento
                        Text(
                          'Escolha o Ícone Representativo:',
                          style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DynamicContentService.availableIcons.map((iconMeta) {
                            final name = iconMeta['name'] as String;
                            final icon = iconMeta['icon'] as IconData;
                            final label = iconMeta['label'] as String;
                            final isSelected = selectedIconName == name;
                            
                            return Tooltip(
                              message: label,
                              child: ChoiceChip(
                                label: Icon(icon, size: 20, color: isSelected ? HotelColors.white : HotelColors.primaryGreen),
                                selected: isSelected,
                                selectedColor: HotelColors.accentGold,
                                backgroundColor: HotelColors.bgLight,
                                onSelected: (selected) {
                                  if (selected) {
                                    setDialogState(() {
                                      selectedIconName = name;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Imagem do Evento
                        Text(
                          'Adicionar Foto ao Evento (Opcional):',
                          style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: isUploading ? null : pickLocalFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Escolher do Computador'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HotelColors.primaryGreen,
                                foregroundColor: HotelColors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                base64Data != null 
                                    ? '✓ $fileName' 
                                    : (isUploading ? 'Carregando...' : 'Sem arquivo'),
                                style: HotelTypography.bodyTextSmall.copyWith(
                                  color: base64Data != null ? Colors.green : HotelColors.textGrey,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            '— OU —',
                            style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.textGrey.withOpacity(0.4)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          enabled: base64Data == null,
                          decoration: _getInputDecoration('Ou cole a URL da Imagem', Icons.link),
                          onChanged: (val) {
                            setDialogState(() {
                              url = val;
                            });
                          },
                        ),
                        
                        if (hasImageSelected) ...[
                          const SizedBox(height: 20),
                          Text('Pré-visualização da Imagem:', style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: _buildThumbnail(
                                base64Data ?? url,
                                height: 120,
                                width: 250,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar', style: HotelTypography.buttonText.copyWith(color: HotelColors.textGrey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final event = DynamicEvent(
                        id: 'event_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        dateInfo: dateInfo,
                        description: description,
                        iconName: selectedIconName,
                        image: hasImageSelected ? (base64Data ?? url) : null,
                      );
                      
                      setState(() => _isLoading = true);
                      try {
                        await _contentService.addEvent(event);
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Evento criado com sucesso!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao salvar evento: O limite de armazenamento do navegador foi atingido.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HotelColors.accentGold,
                    foregroundColor: HotelColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Publicar Evento', style: HotelTypography.buttonText),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _getInputDecoration(String labelText, IconData icon, {String? hintText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: HotelTypography.bodyTextSmall.copyWith(fontSize: 12),
      prefixIcon: Icon(icon, color: HotelColors.accentGold, size: 18),
      filled: true,
      fillColor: HotelColors.bgLight,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: HotelColors.accentGold, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: HotelColors.lightGrey, width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  // Ações de Exclusão ("Retirar")
  Future<void> _deletePhoto(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HotelColors.white,
        title: const Text('Excluir Foto'),
        content: const Text('Tem certeza que deseja retirar esta foto da galeria do site?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não', style: TextStyle(color: HotelColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Sim, Retirar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _contentService.removePhoto(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto removida da galeria!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover foto: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _deleteEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HotelColors.white,
        title: const Text('Excluir Evento'),
        content: const Text('Tem certeza que deseja retirar este evento da programação do site?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não', style: TextStyle(color: HotelColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Sim, Retirar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _contentService.removeEvent(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento removido do site!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover evento: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HotelColors.bgLight,
      appBar: AppBar(
        backgroundColor: HotelColors.primaryGreen,
        foregroundColor: HotelColors.white,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: HotelColors.accentGold, size: 28),
            const SizedBox(width: 12),
            Text(
              'Painel de Controle do Hotel',
              style: HotelTypography.cardTitle.copyWith(color: HotelColors.white, fontSize: 20),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(true), // Retorna informando se alterou dados
              icon: const Icon(Icons.exit_to_app, size: 16),
              label: const Text('Voltar ao Site'),
              style: OutlinedButton.styleFrom(
                foregroundColor: HotelColors.accentGold,
                side: const BorderSide(color: HotelColors.accentGold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: HotelColors.accentGold,
          unselectedLabelColor: HotelColors.white.withOpacity(0.7),
          indicatorColor: HotelColors.accentGold,
          tabs: const [
            Tab(icon: Icon(Icons.photo_library), text: 'Galeria de Fotos'),
            Tab(icon: Icon(Icons.event_note), text: 'Programação & Eventos'),
            Tab(icon: Icon(Icons.hotel), text: 'Acomodações'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: HotelColors.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGalleryManager(),
                _buildEventsManager(),
                _buildRoomsManager(),
              ],
            ),
    );
  }

  Widget _buildGalleryManager() {
    final photos = _contentService.photos;
    final generalPhotos = photos.where((p) => p.sector == 'gallery').toList();
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 800;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fotos do Site',
                    style: HotelTypography.sectionTitle(context, color: HotelColors.primaryGreen).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gerencie as fotos que aparecem na galeria principal e nos banners das seções do site.',
                    style: HotelTypography.bodyTextSmall,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openAddPhotoDialog,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Adicionar na Galeria'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HotelColors.primaryGreen,
                  foregroundColor: HotelColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Seção de Destaques
          Text(
            'Imagens de Capa / Destaque dos Setores',
            style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Estas fotos substituem os fundos e imagens de destaque das seções da página inicial.',
            style: HotelTypography.bodyTextSmall,
          ),
          const SizedBox(height: 16),
          isMobile
              ? Column(
                  children: [
                    _buildSectorOverrideCard('hero', 'Banner Principal (Hero)', 'assets/images/hero_resort.png', '1920x1080 px (16:9)'),
                    const SizedBox(height: 12),
                    _buildSectorOverrideCard('about', 'Sobre o Hotel (O Hotel)', 'assets/images/lazer_resort.png', '800x600 px (4:3)'),
                    const SizedBox(height: 12),
                    _buildSectorOverrideCard('mineral', 'Água Mineral', 'assets/images/fontanario.png', '800x600 px (4:3)'),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSectorOverrideCard('hero', 'Banner Principal (Hero)', 'assets/images/hero_resort.png', '1920x1080 px (16:9)')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSectorOverrideCard('about', 'Sobre o Hotel (O Hotel)', 'assets/images/lazer_resort.png', '800x600 px (4:3)')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSectorOverrideCard('mineral', 'Água Mineral', 'assets/images/fontanario.png', '800x600 px (4:3)')),
                  ],
                ),
          const SizedBox(height: 32),
          const Divider(color: HotelColors.lightGrey),
          const SizedBox(height: 20),
          
          Text(
            'Fotos das Atividades de Lazer',
            style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Estas fotos personalizam os cards exibidos na seção "Lazer Completo para a Família".',
            style: HotelTypography.bodyTextSmall,
          ),
          const SizedBox(height: 16),
          isMobile
              ? Column(
                  children: [
                    _buildLeisureOverrideCard('lago', 'Lago com Pedalinhos', 'assets/images/hero_resort.png'),
                    const SizedBox(height: 12),
                    _buildLeisureOverrideCard('piscina', 'Piscinas Externas', 'assets/images/lazer_resort.png'),
                    const SizedBox(height: 12),
                    _buildLeisureOverrideCard('cavalgada', 'Cavalgada & Trilhas', 'assets/images/hero_resort.png'),
                    const SizedBox(height: 12),
                    _buildLeisureOverrideCard('recreacao', 'Recreação aos Finais de Semana', 'assets/images/lazer_resort.png'),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildLeisureOverrideCard('lago', 'Lago com Pedalinhos', 'assets/images/hero_resort.png')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildLeisureOverrideCard('piscina', 'Piscinas Externas', 'assets/images/lazer_resort.png')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildLeisureOverrideCard('cavalgada', 'Cavalgada & Trilhas', 'assets/images/hero_resort.png')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildLeisureOverrideCard('recreacao', 'Recreação aos Finais de Semana', 'assets/images/lazer_resort.png')),
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 32),
          const Divider(color: HotelColors.lightGrey),
          const SizedBox(height: 20),
          
          Text(
            'Fotos de Lazer (Galeria Geral)',
            style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Fotos rotativas da área de lazer e arredores exibidas no carrossel/grade geral da home.',
            style: HotelTypography.bodyTextSmall,
          ),
          const SizedBox(height: 16),
          
          generalPhotos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 64, color: HotelColors.textGrey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('Nenhuma foto na galeria geral.', style: HotelTypography.bodyText()),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: generalPhotos.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    if (index >= generalPhotos.length) return const SizedBox.shrink();
                    final photo = generalPhotos[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: HotelColors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: HotelColors.lightGrey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildThumbnail(photo.image),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black87],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            if (photo.title != null && photo.title!.isNotEmpty)
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 40,
                                child: Text(
                                  photo.title!,
                                  style: HotelTypography.bodyTextSmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: IconButton(
                                onPressed: () => _deletePhoto(photo.id),
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.9),
                                  padding: const EdgeInsets.all(6),
                                ),
                              ),
                            ),
                            if (photo.image.startsWith('assets/'))
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: HotelColors.accentGold,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Padrão',
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEventsManager() {
    final events = _contentService.events;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programação de Eventos',
                    style: HotelTypography.sectionTitle(context, color: HotelColors.primaryGreen).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gerencie a grade de eventos que os hóspedes veem no site. Eles podem ter fotos e ícones.',
                    style: HotelTypography.bodyTextSmall,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openAddEventDialog,
                icon: const Icon(Icons.add_alert_rounded),
                label: const Text('Novo Evento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HotelColors.primaryGreen,
                  foregroundColor: HotelColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_outlined, size: 64, color: HotelColors.textGrey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('Nenhum evento agendado.', style: HotelTypography.bodyText()),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          color: HotelColors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: HotelColors.lightGrey),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: event.image != null
                                ? _buildThumbnail(event.image!, height: 60, width: 60)
                                : Container(
                                    height: 60,
                                    width: 60,
                                    color: HotelColors.bgLight,
                                    child: Icon(event.icon, color: HotelColors.primaryGreen),
                                  ),
                          ),
                          title: Text(
                            event.title,
                            style: HotelTypography.cardTitle.copyWith(fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.date_range, size: 14, color: HotelColors.accentGold),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.dateInfo,
                                    style: HotelTypography.bodyTextSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.description,
                                style: HotelTypography.bodyTextSmall.copyWith(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (event.id.startsWith('default_'))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: HotelColors.lightGrey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Padrão',
                                    style: HotelTypography.bodyTextSmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              IconButton(
                                onPressed: () => _deleteEvent(event.id),
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: 'Retirar Evento do Site',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getRecommendationText(String sector) {
    switch (sector) {
      case 'hero':
        return 'Recomendado: Proporção 16:9 ou 21:9 (Sugerido: 1920x1080 px)';
      case 'about':
        return 'Recomendado: Proporção 4:3 ou 16:10 (Sugerido: 800x600 px)';
      case 'rooms':
        return 'Recomendado: Proporção 3:2 ou 4:3 (Sugerido: 600x400 px)';
      case 'mineral':
        return 'Recomendado: Proporção 4:3 ou 16:10 (Sugerido: 800x600 px)';
      case 'events':
        return 'Recomendado: Proporção 16:9 ou 4:3 (Sugerido: 600x400 px)';
      case 'gallery':
      default:
        return 'Recomendado: Proporção 4:3 ou 1.2:1 (Sugerido: 800x600 px)';
    }
  }

  Future<void> _deleteRoom(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HotelColors.white,
        title: const Text('Excluir Quarto'),
        content: const Text('Tem certeza que deseja retirar esta acomodação do site?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não', style: TextStyle(color: HotelColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Sim, Retirar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _contentService.removeRoom(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acomodação removida do site!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover quarto: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _openAddRoomDialog() {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    String category = '';
    String description = '';
    List<String> selectedAmenities = [];
    String url = '';
    String? base64Data;
    String fileName = '';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickLocalFile() async {
              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                  withData: true,
                );

                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  if (file.bytes != null) {
                    setDialogState(() {
                      isUploading = true;
                      fileName = file.name;
                    });
                    
                    final compressedBytes = await ImageHelper.compressImageBytes(file.bytes!);
                    final base64String = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
                    
                    setDialogState(() {
                      base64Data = base64String;
                      url = '';
                      isUploading = false;
                    });
                  }
                }
              } catch (e) {
                setDialogState(() {
                  isUploading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
                );
              }
            }

            final hasImageSelected = base64Data != null || url.isNotEmpty;

            return AlertDialog(
              backgroundColor: HotelColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Text(
                'Cadastrar Novo Quarto',
                style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: 500,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          decoration: _getInputDecoration('Título do Quarto (Ex: Suíte Premium)', Icons.hotel),
                          validator: (value) => value == null || value.isEmpty ? 'Informe o título do quarto.' : null,
                          onChanged: (val) => title = val,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          decoration: _getInputDecoration('Ala / Categoria (Ex: Ala Lago)', Icons.category),
                          validator: (value) => value == null || value.isEmpty ? 'Informe a ala ou categoria.' : null,
                          onChanged: (val) => category = val,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          decoration: _getInputDecoration('Descrição do Quarto', Icons.description),
                          maxLines: 3,
                          validator: (value) => value == null || value.isEmpty ? 'Escreva uma breve descrição.' : null,
                          onChanged: (val) => description = val,
                        ),
                        const SizedBox(height: 20),
                        
                        Text(
                          'Comodidades (Selecione):',
                          style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DynamicContentService.availableAmenities.map((amenity) {
                            final isSelected = selectedAmenities.contains(amenity);
                            return FilterChip(
                              label: Text(
                                amenity,
                                style: TextStyle(
                                  color: isSelected ? HotelColors.white : HotelColors.primaryGreen,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: HotelColors.primaryGreen,
                              backgroundColor: HotelColors.bgLight,
                              checkmarkColor: HotelColors.white,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedAmenities.add(amenity);
                                  } else {
                                    selectedAmenities.remove(amenity);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        
                        Text(
                          'Foto do Quarto:',
                          style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Recomendado: Proporção 3:2 ou 4:3 (Sugerido: 600x400 px)',
                          style: HotelTypography.bodyTextSmall.copyWith(
                            color: HotelColors.accentGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: isUploading ? null : pickLocalFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Carregar Foto'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HotelColors.primaryGreen,
                                foregroundColor: HotelColors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                base64Data != null 
                                    ? '✓ $fileName' 
                                    : (isUploading ? 'Carregando...' : 'Sem arquivo'),
                                style: HotelTypography.bodyTextSmall.copyWith(
                                  color: base64Data != null ? Colors.green : HotelColors.textGrey,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            '— OU —',
                            style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.textGrey.withOpacity(0.4)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          enabled: base64Data == null,
                          decoration: _getInputDecoration('Ou cole a URL da foto', Icons.link),
                          onChanged: (val) {
                            setDialogState(() {
                              url = val;
                            });
                          },
                        ),
                        
                        if (hasImageSelected) ...[
                          const SizedBox(height: 20),
                          Text('Pré-visualização da Imagem:', style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: _buildThumbnail(
                                base64Data ?? url,
                                height: 120,
                                width: 250,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar', style: HotelTypography.buttonText.copyWith(color: HotelColors.textGrey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final room = DynamicRoom(
                        id: 'room_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        category: category,
                        description: description,
                        amenities: selectedAmenities,
                        image: hasImageSelected ? (base64Data ?? url) : null,
                      );
                      
                      setState(() => _isLoading = true);
                      try {
                        await _contentService.addRoom(room);
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quarto cadastrado com sucesso!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao salvar quarto: O limite de armazenamento do navegador foi atingido.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HotelColors.accentGold,
                    foregroundColor: HotelColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Publicar Quarto', style: HotelTypography.buttonText),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRoomsManager() {
    final rooms = _contentService.rooms;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cadastro de Acomodações',
                    style: HotelTypography.sectionTitle(context, color: HotelColors.primaryGreen).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gerencie os tipos de quartos exibidos no site. Adicione novos ou remova sem limites.',
                    style: HotelTypography.bodyTextSmall,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openAddRoomDialog,
                icon: const Icon(Icons.add_home_work_rounded),
                label: const Text('Novo Quarto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HotelColors.primaryGreen,
                  foregroundColor: HotelColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: rooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bed_outlined, size: 64, color: HotelColors.textGrey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('Nenhum quarto cadastrado.', style: HotelTypography.bodyText()),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      String imagePath = room.image ?? '';
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
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          color: HotelColors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: HotelColors.lightGrey),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: _buildThumbnail(imagePath, height: 60, width: 60),
                          ),
                          title: Row(
                            children: [
                              Text(
                                room.title,
                                style: HotelTypography.cardTitle.copyWith(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: HotelColors.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  room.category.toUpperCase(),
                                  style: TextStyle(
                                    color: HotelColors.primaryGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                room.description,
                                style: HotelTypography.bodyTextSmall.copyWith(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                children: room.amenities.map((amenity) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: HotelColors.bgLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    amenity,
                                    style: const TextStyle(fontSize: 10, color: HotelColors.primaryGreen),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (room.id.startsWith('room_standard') || room.id.startsWith('room_luxo') || room.id.startsWith('room_familiar'))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: HotelColors.lightGrey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Padrão',
                                    style: HotelTypography.bodyTextSmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              IconButton(
                                onPressed: () => _deleteRoom(room.id),
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: 'Excluir Quarto',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openChangeSectorPhotoDialog(String sector, String label) {
    String url = '';
    String? base64Data;
    String fileName = '';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickLocalFile() async {
              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                  withData: true,
                );

                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  if (file.bytes != null) {
                    setDialogState(() {
                      isUploading = true;
                      fileName = file.name;
                    });
                    
                    final compressedBytes = await ImageHelper.compressImageBytes(file.bytes!);
                    final base64String = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
                    
                    setDialogState(() {
                      base64Data = base64String;
                      url = '';
                      isUploading = false;
                    });
                  }
                }
              } catch (e) {
                setDialogState(() {
                  isUploading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
                );
              }
            }

            final hasImageSelected = base64Data != null || url.isNotEmpty;

            return AlertDialog(
              backgroundColor: HotelColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Text(
                'Alterar Imagem: $label',
                style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getRecommendationText(sector),
                        style: HotelTypography.bodyTextSmall.copyWith(
                          color: HotelColors.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Escolha uma das formas de adicionar a nova imagem:',
                        style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: isUploading ? null : pickLocalFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Carregar do Computador'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HotelColors.primaryGreen,
                              foregroundColor: HotelColors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              base64Data != null 
                                  ? '✓ $fileName' 
                                  : (isUploading ? 'Carregando...' : 'Sem arquivo'),
                              style: HotelTypography.bodyTextSmall.copyWith(
                                color: base64Data != null ? Colors.green : HotelColors.textGrey,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '— OU —',
                          style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.textGrey.withOpacity(0.4)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        enabled: base64Data == null,
                        decoration: _getInputDecoration(
                          'Cole a URL da Imagem',
                          Icons.link,
                          hintText: 'https://exemplo.com/foto.jpg',
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            url = val;
                          });
                        },
                      ),
                      
                      if (hasImageSelected) ...[
                        const SizedBox(height: 20),
                        Text('Pré-visualização:', style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: _buildThumbnail(
                              base64Data ?? url,
                              height: 120,
                              width: 250,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar', style: HotelTypography.buttonText.copyWith(color: HotelColors.textGrey)),
                ),
                ElevatedButton(
                  onPressed: !hasImageSelected
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            final photosToRemove = _contentService.photos.where((p) => p.sector == sector).toList();
                            for (var p in photosToRemove) {
                              await _contentService.removePhoto(p.id);
                            }

                            final photo = GalleryPhoto(
                              id: 'photo_sector_${sector}_${DateTime.now().millisecondsSinceEpoch}',
                              image: base64Data ?? url,
                              title: 'Imagem customizada do setor $label',
                              sector: sector,
                            );
                            
                            await _contentService.addPhoto(photo);
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Imagem do setor $label alterada com sucesso!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao alterar imagem do setor: O limite de armazenamento do navegador foi atingido.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HotelColors.accentGold,
                    foregroundColor: HotelColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Salvar Alteração', style: HotelTypography.buttonText),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectorOverrideCard(String sector, String label, String defaultAsset, String sizeRec) {
    final customImage = _contentService.getImageForSector(sector);
    final displayImage = customImage ?? defaultAsset;
    
    return Container(
      decoration: BoxDecoration(
        color: HotelColors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: HotelColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            child: _buildThumbnail(
              displayImage,
              height: 120,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: HotelTypography.cardTitle.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tamanho: $sizeRec',
                  style: TextStyle(
                    fontSize: 10,
                    color: HotelColors.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openChangeSectorPhotoDialog(sector, label),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HotelColors.primaryGreen,
                          side: const BorderSide(color: HotelColors.primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Alterar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (customImage != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: HotelColors.white,
                              title: const Text('Restaurar Padrão'),
                              content: Text('Deseja voltar a usar a foto padrão do site para o setor "$label"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Não', style: TextStyle(color: HotelColors.textGrey)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                  child: const Text('Sim, Restaurar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            setState(() => _isLoading = true);
                            try {
                              final photosToRemove = _contentService.photos.where((p) => p.sector == sector).toList();
                              for (var p in photosToRemove) {
                                await _contentService.removePhoto(p.id);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Foto padrão do setor $label restaurada!')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao restaurar imagem padrão: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.settings_backup_restore, color: Colors.redAccent, size: 18),
                        tooltip: 'Restaurar Padrão',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.05),
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeisureOverrideCard(String subSector, String label, String defaultAsset) {
    final customImage = _contentService.getImageForSector('leisure', subSector: subSector);
    final displayImage = customImage ?? defaultAsset;
    
    return Container(
      decoration: BoxDecoration(
        color: HotelColors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: HotelColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            child: _buildThumbnail(
              displayImage,
              height: 120,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: HotelTypography.cardTitle.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tamanho Recomendado: 600x400 px (3:2)',
                  style: TextStyle(
                    fontSize: 10,
                    color: HotelColors.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openChangeLeisurePhotoDialog(subSector, label),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HotelColors.primaryGreen,
                          side: const BorderSide(color: HotelColors.primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Alterar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (customImage != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: HotelColors.white,
                              title: const Text('Restaurar Padrão'),
                              content: Text('Deseja voltar a usar a foto padrão para "$label"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Não', style: TextStyle(color: HotelColors.textGrey)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                  child: const Text('Sim, Restaurar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            setState(() => _isLoading = true);
                            try {
                              final photosToRemove = _contentService.photos
                                  .where((p) => p.sector == 'leisure' && p.subSector == subSector)
                                  .toList();
                              for (var p in photosToRemove) {
                                await _contentService.removePhoto(p.id);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Foto padrão de "$label" restaurada!')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao restaurar imagem padrão: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.settings_backup_restore, color: Colors.redAccent, size: 18),
                        tooltip: 'Restaurar Padrão',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.05),
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openChangeLeisurePhotoDialog(String subSector, String label) {
    String url = '';
    String? base64Data;
    String fileName = '';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickLocalFile() async {
              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                  withData: true,
                );

                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  if (file.bytes != null) {
                    setDialogState(() {
                      isUploading = true;
                      fileName = file.name;
                    });
                    
                    final compressedBytes = await ImageHelper.compressImageBytes(file.bytes!);
                    final base64String = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
                    
                    setDialogState(() {
                      base64Data = base64String;
                      url = '';
                      isUploading = false;
                    });
                  }
                }
              } catch (e) {
                setDialogState(() {
                  isUploading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
                );
              }
            }

            final hasImageSelected = base64Data != null || url.isNotEmpty;

            return AlertDialog(
              backgroundColor: HotelColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Text(
                'Alterar Foto: $label',
                style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recomendado: Proporção 3:2 ou 4:3 (Sugerido: 600x400 px)',
                        style: HotelTypography.bodyTextSmall.copyWith(
                          color: HotelColors.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Escolha uma das formas de adicionar a nova imagem:',
                        style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: isUploading ? null : pickLocalFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Carregar do Computador'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HotelColors.primaryGreen,
                              foregroundColor: HotelColors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              base64Data != null 
                                  ? '✓ $fileName' 
                                  : (isUploading ? 'Carregando...' : 'Sem arquivo'),
                              style: HotelTypography.bodyTextSmall.copyWith(
                                color: base64Data != null ? Colors.green : HotelColors.textGrey,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '— OU —',
                          style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.textGrey.withOpacity(0.4)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        enabled: base64Data == null,
                        decoration: _getInputDecoration(
                          'Cole a URL da Imagem',
                          Icons.link,
                          hintText: 'https://exemplo.com/foto.jpg',
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            url = val;
                          });
                        },
                      ),
                      
                      if (hasImageSelected) ...[
                        const SizedBox(height: 20),
                        Text('Pré-visualização:', style: HotelTypography.bodyTextSmall.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: _buildThumbnail(
                              base64Data ?? url,
                              height: 120,
                              width: 250,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar', style: HotelTypography.buttonText.copyWith(color: HotelColors.textGrey)),
                ),
                ElevatedButton(
                  onPressed: !hasImageSelected
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            final photosToRemove = _contentService.photos
                                .where((p) => p.sector == 'leisure' && p.subSector == subSector)
                                .toList();
                            for (var p in photosToRemove) {
                              await _contentService.removePhoto(p.id);
                            }

                            final photo = GalleryPhoto(
                              id: 'photo_leisure_${subSector}_${DateTime.now().millisecondsSinceEpoch}',
                              image: base64Data ?? url,
                              title: 'Imagem customizada da atividade $label',
                              sector: 'leisure',
                              subSector: subSector,
                            );
                            
                            await _contentService.addPhoto(photo);
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Foto da atividade $label alterada com sucesso!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao salvar imagem: O limite de armazenamento foi excedido.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HotelColors.accentGold,
                    foregroundColor: HotelColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Salvar Alteração', style: HotelTypography.buttonText),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
