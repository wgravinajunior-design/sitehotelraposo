import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class DateDMYFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) text = text.substring(0, 8);
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) {
        buffer.write('/');
      }
    }
    var newText = buffer.toString();
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class GuestData {
  TextEditingController name = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  FocusNode cpfFocusNode = FocusNode();
  bool hasVehicle = false;
  TextEditingController placa = TextEditingController();
  bool isChild = false;
  TextEditingController age = TextEditingController();
  String? lastSearchedCpf;
  
  // FNRH Fields
  String? nacionalidade = 'BR';
  String? profissao;
  String? genero;
  String? dataNascimento;
  String? filiacao;
  String? rg;
  String? orgaoExpedidor;
  String? passaporte;
  String? paisResidencia = 'BR';
  String? raca;
  String? deficiencia;
  String? tipoDeficiencia;
  String? cep;
  String? logradouro;
  String? numero;
  String? bairro;
  String? cidade;
  String? uf;
  String? telefone;
  String? email;
  String? motivoViagem;
  String? metodoViagem;
  
  Map<String, dynamic> toJson() => {
    'nome': name.text,
    'placa': placa.text,
    'isCrianca': isChild,
    'idade': int.tryParse(age.text),
    'nacionalidade': nacionalidade,
    'profissao': profissao,
    'genero': genero,
    'dataNascimento': dataNascimento,
    'filiacao': filiacao,
    'cpf': cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    'rg': rg,
    'orgaoExpedidor': orgaoExpedidor,
    'passaporte': passaporte,
    'paisResidencia': paisResidencia,
    'raca': raca,
    'deficiencia': deficiencia,
    'tipoDeficiencia': tipoDeficiencia,
    'cep': cep,
    'logradouro': logradouro,
    'numero': numero,
    'bairro': bairro,
    'cidade': cidade,
    'uf': uf,
    'telefone': telefone,
    'email': email,
    'motivoViagem': motivoViagem,
    'metodoViagem': metodoViagem,
  };
}

class ReservationForm extends StatefulWidget {
  final DateTime? initialCheckin;
  final DateTime? initialCheckout;
  final int? initialAdults;
  final int? initialChildren;

  const ReservationForm({
    super.key,
    this.initialCheckin,
    this.initialCheckout,
    this.initialAdults,
    this.initialChildren,
  });

  @override
  State<ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends State<ReservationForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Dados do Responsável
  final _cpfCnpjController = TextEditingController();
  final _nomeResponsavelController = TextEditingController();
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _observacaoController = TextEditingController();

  final _qtdeHospedesController = TextEditingController(text: "1");
  final _placaPrincipalController = TextEditingController();
  bool _isFirstGuestResponsavel = true; // Default to true for better UX
  List<GuestData> _hospedes = [GuestData()];

  final FocusNode _cpfCnpjFocus = FocusNode();
  final FocusNode _cepFocus = FocusNode();

  DateTime? _checkin;
  DateTime? _checkout;

  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  bool _obrigarFNRH = false;

  List<Map<String, dynamic>> _empresas = [];
  int? _selectedEmpresaId;

  List<Map<String, dynamic>> _tiposAp = [];
  int? _selectedTipoApId;

  List<Map<String, dynamic>> _tiposHospedagem = [];
  int? _selectedHospedagemTipoId;

  List<Map<String, dynamic>> _quartosLivres = [];
  int? _selectedApartamentoId;

  String? _lastSearchedCpfCnpj;

  @override
  void initState() {
    super.initState();
    
    // Set initial values from BookingBar if available
    _checkin = widget.initialCheckin;
    _checkout = widget.initialCheckout;
    int totalGuests = (widget.initialAdults ?? 1) + (widget.initialChildren ?? 0);
    _qtdeHospedesController.text = totalGuests.toString();
    
    _fetchInitialData();
    _updateHospedesFields();
    
    _qtdeHospedesController.addListener(_updateHospedesFields);
    
    _cpfCnpjFocus.addListener(() {
      if (!_cpfCnpjFocus.hasFocus) _fetchPessoaByCpfCnpj();
    });

    _cepFocus.addListener(() {
      if (!_cepFocus.hasFocus) _fetchCEP();
    });
    
    _nomeResponsavelController.addListener(() {
      if (_isFirstGuestResponsavel && _hospedes.isNotEmpty) {
        _hospedes[0].name.text = _nomeResponsavelController.text;
      }
    });

    _cpfCnpjController.addListener(() {
      if (_isFirstGuestResponsavel && _hospedes.isNotEmpty) {
        _hospedes[0].cpfController.text = _cpfCnpjController.text;
      }
      _fetchPessoaByCpfCnpj();
    });

    if (_hospedes.isNotEmpty) {
      _hospedes[0].cpfFocusNode.addListener(() {
        if (!_hospedes[0].cpfFocusNode.hasFocus) {
          _fetchGuestByCpf(0);
        }
      });
      _hospedes[0].cpfController.addListener(() {
        _fetchGuestByCpf(0);
      });
    }

    if (_checkin != null && _checkout != null) {
      _checkAvailability();
    }
  }

  Future<void> _fetchInitialData() async {
    try {
      final resEmpresas = await http.get(Uri.parse(ApiConfig.empresas));
      if (resEmpresas.statusCode == 200) {
        setState(() {
          _empresas = List<Map<String, dynamic>>.from(json.decode(resEmpresas.body));
          if (_empresas.isNotEmpty) {
            _selectedEmpresaId = _empresas.first['id'];
          }
        });
      }

      final resTiposAp = await http.get(Uri.parse(ApiConfig.apartmentTypes));
      if (resTiposAp.statusCode == 200) {
        setState(() => _tiposAp = List<Map<String, dynamic>>.from(json.decode(resTiposAp.body)));
      }

      final resConfig = await http.get(Uri.parse(ApiConfig.config));
      if (resConfig.statusCode == 200) {
        final configData = json.decode(resConfig.body);
        setState(() {
          _obrigarFNRH = configData['obrigarFNRH'] == true;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados iniciais: $e');
    }
  }

  Future<void> _fetchTiposHospedagem() async {
    if (_selectedTipoApId == null) {
      setState(() {
        _tiposHospedagem = [];
        _selectedHospedagemTipoId = null;
      });
      return;
    }
    try {
      final res = await http.get(Uri.parse(ApiConfig.hospedagemTypes('$_selectedTipoApId')));
      if (res.statusCode == 200) {
        setState(() {
          _tiposHospedagem = List<Map<String, dynamic>>.from(json.decode(res.body));
          if (_selectedHospedagemTipoId != null && !_tiposHospedagem.any((e) => e['id'] == _selectedHospedagemTipoId)) {
            _selectedHospedagemTipoId = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar tipos de hospedagem: $e');
    }
  }

  void _updateHospedesFields() {
    int total = int.tryParse(_qtdeHospedesController.text) ?? 1;
    if (total < 1) total = 1;

    setState(() {
      if (_hospedes.length < total) {
        for (int i = _hospedes.length; i < total; i++) {
          final newGuest = GuestData();
          final index = i;
          newGuest.cpfFocusNode.addListener(() {
            if (!newGuest.cpfFocusNode.hasFocus) {
              _fetchGuestByCpf(index);
            }
          });
          newGuest.cpfController.addListener(() {
            _fetchGuestByCpf(index);
          });
          _hospedes.add(newGuest);
        }
      } else if (_hospedes.length > total) {
        for (int i = total; i < _hospedes.length; i++) {
          _hospedes[i].name.dispose();
          _hospedes[i].cpfController.dispose();
          _hospedes[i].cpfFocusNode.dispose();
          _hospedes[i].placa.dispose();
          _hospedes[i].age.dispose();
        }
        _hospedes = _hospedes.sublist(0, total);
      }
      
      if (_isFirstGuestResponsavel && _hospedes.isNotEmpty) {
        _hospedes[0].name.text = _nomeResponsavelController.text;
        _hospedes[0].cpfController.text = _cpfCnpjController.text;
      }
    });
  }

  Future<void> _fetchCEP() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length == 8) {
      try {
        final res = await http.get(Uri.parse(ApiConfig.cep(cep)));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['erro'] == null) {
            setState(() {
              _enderecoController.text = "${data['logradouro']}, ${data['bairro']}, ${data['localidade']} - ${data['uf']}".toUpperCase();
            });
          }
        }
      } catch (e) {
        debugPrint('Erro ao buscar CEP: $e');
      }
    }
  }

  Future<void> _fetchCNPJ() async {
    final cnpj = _cpfCnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cnpj.length >= 14) {
      try {
        final res = await http.get(Uri.parse(ApiConfig.cnpj(cnpj)));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          setState(() {
            _nomeResponsavelController.text = (data['razao_social'] ?? '').toString().toUpperCase();
            _cepController.text = data['cep'] ?? '';
          });
          Future.delayed(const Duration(milliseconds: 300), () => _fetchCEP());
        }
      } catch (e) {
        debugPrint('Erro ao buscar CNPJ: $e');
      }
    }
  }

  Future<void> _fetchPessoaByCpfCnpj() async {
    final cleanVal = _cpfCnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanVal.length != 11 && cleanVal.length != 14) {
      _lastSearchedCpfCnpj = null;
      return;
    }
    if (_lastSearchedCpfCnpj == cleanVal) return;
    _lastSearchedCpfCnpj = cleanVal;

    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.pessoa(cleanVal)));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data != null && data['PES_ID'] != null) {
          setState(() {
            _nomeResponsavelController.text = (data['PES_RSOCIAL_NOME'] ?? '').toString().toUpperCase();
            _cepController.text = (data['PES_CEP'] ?? '').toString();
            _enderecoController.text = (data['PES_ENDERECO'] ?? '').toString().toUpperCase();
            _telefoneController.text = (data['PES_CELULAR'] ?? data['PES_TELEFONE'] ?? '').toString();
            
            if (_isFirstGuestResponsavel && _hospedes.isNotEmpty) {
              _hospedes[0].name.text = _nomeResponsavelController.text;
            }
            
            // Preenche a FNRH do Hóspede Responsável
            if (_hospedes.isNotEmpty) {
              final guest = _hospedes[0];
              guest.nacionalidade = (data['PES_PAIS_NACIONALIDADE']?.toString() ?? '').trim();
              if (guest.nacionalidade!.isEmpty && data['PES_OBSERVACAO'] != null && data['PES_OBSERVACAO'].toString().contains('Nac/Nat:')) {
                guest.nacionalidade = data['PES_OBSERVACAO'].toString().split('Nac/Nat:').last.split('|').first.trim();
              }
              if (guest.nacionalidade!.isEmpty || guest.nacionalidade!.toLowerCase() == 'brasil') guest.nacionalidade = 'BR';
              guest.paisResidencia = (data['PES_PAIS_RESIDENCIA']?.toString() ?? '').trim();
              if (guest.paisResidencia!.isEmpty || guest.paisResidencia!.toLowerCase() == 'brasil') guest.paisResidencia = 'BR';
              
              if (guest.nacionalidade!.length > 2) guest.nacionalidade = guest.nacionalidade!.substring(0, 2).toUpperCase();
              if (guest.paisResidencia!.length > 2) guest.paisResidencia = guest.paisResidencia!.substring(0, 2).toUpperCase();
              guest.raca = (data['PES_RACA']?.toString() ?? '').trim();
              guest.deficiencia = (data['PES_DEFICIENCIA']?.toString() ?? '').trim();
              guest.tipoDeficiencia = (data['PES_TIPO_DEFICIENCIA']?.toString() ?? '').trim();
              guest.profissao = (data['PES_PROFISSAO'] ?? '').toString();
              guest.genero = data['PES_SEXO'] == 'F' ? 'Feminino' : (data['PES_SEXO'] == 'M' ? 'Masculino' : null);
              var dtNasc = (data['PES_DT_NASCIMENTO'] ?? '').toString();
              if (dtNasc.contains('-') && dtNasc.length >= 10) {
                var parts = dtNasc.substring(0, 10).split('-');
                if (parts.length == 3 && parts[0].length == 4) {
                  dtNasc = '${parts[2]}/${parts[1]}/${parts[0]}';
                }
              }
              guest.dataNascimento = dtNasc;
              guest.filiacao = data['PES_OBSERVACAO'] != null && data['PES_OBSERVACAO'].toString().contains('Filiação:')
                  ? data['PES_OBSERVACAO'].toString().split('Filiação:').last.split('|').first.trim()
                  : '';
              guest.cpfController.text = cleanVal.length == 11 ? cleanVal : '';
              guest.rg = (data['PES_IE_RG'] ?? '').toString();
              guest.passaporte = (data['PES_DOC_EXTERIOR'] ?? '').toString();
              guest.cep = (data['PES_CEP'] ?? '').toString();
              guest.logradouro = (data['PES_ENDERECO'] ?? '').toString().toUpperCase();
              guest.numero = (data['PES_NUMERO'] ?? '').toString();
              guest.bairro = (data['PES_BAIRRO'] ?? '').toString();
              guest.cidade = (data['PES_CIDADE'] ?? '').toString();
              guest.telefone = (data['PES_CELULAR'] ?? data['PES_TELEFONE'] ?? '').toString();
              guest.email = (data['PES_EMAIL'] ?? '').toString();
            }
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Cadastro existente encontrado! Dados preenchidos.'),
                backgroundColor: HotelColors.primaryGreen,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar hóspede local: $e');
    } finally {
      setState(() => _isLoading = false);
    }
    
    // Fallback para buscar CNPJ externo
    if (cleanVal.length == 14) {
      _fetchCNPJ();
    }
  }

  Future<void> _fetchGuestByCpf(int index) async {
    if (index >= _hospedes.length) return;
    final guest = _hospedes[index];
    final cleanVal = guest.cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanVal.length != 11) {
      guest.lastSearchedCpf = null;
      return;
    }
    if (guest.lastSearchedCpf == cleanVal) return;
    guest.lastSearchedCpf = cleanVal;

    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.pessoa(cleanVal)));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data != null && data['PES_ID'] != null) {
          setState(() {
            guest.name.text = (data['PES_RSOCIAL_NOME'] ?? '').toString().toUpperCase();
            
            // Preenche os outros campos da FNRH no objeto do hóspede
            guest.nacionalidade = (data['PES_PAIS_NACIONALIDADE']?.toString() ?? '').trim();
            if (guest.nacionalidade!.isEmpty && data['PES_OBSERVACAO'] != null && data['PES_OBSERVACAO'].toString().contains('Nac/Nat:')) {
              guest.nacionalidade = data['PES_OBSERVACAO'].toString().split('Nac/Nat:').last.split('|').first.trim();
            }
            if (guest.nacionalidade!.isEmpty || guest.nacionalidade!.toLowerCase() == 'brasil') guest.nacionalidade = 'BR';
            
            guest.paisResidencia = (data['PES_PAIS_RESIDENCIA']?.toString() ?? '').trim();
            if (guest.paisResidencia!.isEmpty || guest.paisResidencia!.toLowerCase() == 'brasil') guest.paisResidencia = 'BR';
            
            if (guest.nacionalidade!.length > 2) guest.nacionalidade = guest.nacionalidade!.substring(0, 2).toUpperCase();
            if (guest.paisResidencia!.length > 2) guest.paisResidencia = guest.paisResidencia!.substring(0, 2).toUpperCase();
            guest.raca = (data['PES_RACA']?.toString() ?? '').trim();
            guest.deficiencia = (data['PES_DEFICIENCIA']?.toString() ?? '').trim();
            guest.tipoDeficiencia = (data['PES_TIPO_DEFICIENCIA']?.toString() ?? '').trim();
            guest.profissao = (data['PES_PROFISSAO'] ?? '').toString();
            guest.genero = data['PES_SEXO'] == 'F' ? 'Feminino' : (data['PES_SEXO'] == 'M' ? 'Masculino' : null);
            var dtNasc = (data['PES_DT_NASCIMENTO'] ?? '').toString();
            if (dtNasc.contains('-') && dtNasc.length >= 10) {
              var parts = dtNasc.substring(0, 10).split('-');
              if (parts.length == 3 && parts[0].length == 4) {
                dtNasc = '${parts[2]}/${parts[1]}/${parts[0]}';
              }
            }
            guest.dataNascimento = dtNasc;
            guest.filiacao = data['PES_OBSERVACAO'] != null && data['PES_OBSERVACAO'].toString().contains('Filiação:')
                ? data['PES_OBSERVACAO'].toString().split('Filiação:').last.split('|').first.trim()
                : '';
            guest.rg = (data['PES_IE_RG'] ?? '').toString();
            guest.passaporte = (data['PES_DOC_EXTERIOR'] ?? '').toString();
            guest.cep = (data['PES_CEP'] ?? '').toString();
            guest.logradouro = (data['PES_ENDERECO'] ?? '').toString().toUpperCase();
            guest.numero = (data['PES_NUMERO'] ?? '').toString();
            guest.bairro = (data['PES_BAIRRO'] ?? '').toString();
            guest.cidade = (data['PES_CIDADE'] ?? '').toString();
            guest.telefone = (data['PES_CELULAR'] ?? data['PES_TELEFONE'] ?? '').toString();
            guest.email = (data['PES_EMAIL'] ?? '').toString();
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Cadastro do Hóspede ${index + 1} encontrado! Dados preenchidos.'),
                backgroundColor: HotelColors.primaryGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar hóspede: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAvailability() async {
    if (_checkin == null || _checkout == null) return;
    
    setState(() {
      _isCheckingAvailability = true;
      _quartosLivres = [];
      _selectedApartamentoId = null;
    });

    try {
      final cin = DateFormat('yyyy-MM-dd').format(_checkin!);
      final cout = DateFormat('yyyy-MM-dd').format(_checkout!);
      
      String url = ApiConfig.availableApartments(cin, cout, tipoApId: _selectedTipoApId?.toString(), hospedagemTipoId: _selectedHospedagemTipoId?.toString());

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _quartosLivres = data.map((e) => e as Map<String, dynamic>).toList();
          if (_quartosLivres.isNotEmpty) {
            _selectedApartamentoId = _quartosLivres.first['id'] as int;
          }
        });
      }
    } catch (e) {
      debugPrint("Erro ao checar disponibilidade: $e");
    } finally {
      setState(() {
        _isCheckingAvailability = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isCheckin) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckin 
          ? (_checkin ?? DateTime.now().add(const Duration(days: 1))) 
          : (_checkout ?? (_checkin?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 2)))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: HotelColors.primaryGreen,
              onPrimary: HotelColors.white,
              onSurface: HotelColors.darkSlate,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isCheckin) {
          _checkin = picked;
          if (_checkout != null && !_checkout!.isAfter(_checkin!)) {
            _checkout = _checkin!.add(const Duration(days: 1));
          }
        } else {
          _checkout = picked;
        }
      });
      _checkAvailability();
    }
  }

  bool _isFNRHComplete(GuestData guest) {
    if (guest.isChild) return true;
    
    final cleanCpf = guest.cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return guest.name.text.trim().isNotEmpty && cleanCpf.isNotEmpty;
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_obrigarFNRH) {
      for (int i = 0; i < _hospedes.length; i++) {
        if (!_isFNRHComplete(_hospedes[i])) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Por favor, preencha todos os campos obrigatórios da FNRH do Hóspede ${i + 1}.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }
    }
    
    if (_checkin == null || _checkout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione as datas de estadia.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> hospedesData = _hospedes.map((g) => g.toJson()).toList();

      final body = {
        'empresaId': _selectedEmpresaId,
        'nomeResponsavel': _nomeResponsavelController.text.toUpperCase(),
        'cpfCnpj': _cpfCnpjController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'cep': _cepController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'endereco': _enderecoController.text.toUpperCase(),
        'telefone': _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'checkin': DateFormat('yyyy-MM-dd').format(_checkin!),
        'checkout': DateFormat('yyyy-MM-dd').format(_checkout!),
        'qtdeHospedes': int.tryParse(_qtdeHospedesController.text) ?? 1,
        'hospedes': hospedesData,
        'observacao': _observacaoController.text,
        'tipoApartamentoId': _selectedApartamentoId,
        'hospedagemTipoId': _selectedHospedagemTipoId,
        'placaPrincipal': _placaPrincipalController.text.toUpperCase(),
      };

      final response = await http.post(
        Uri.parse(ApiConfig.reservation),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        final resData = json.decode(utf8.decode(response.bodyBytes));
        
        final phone = resData['hotelWhatsApp'] ?? '';
        final message = resData['whatsappMessage'] ?? '';
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
        
        final Uri whatsappUri = Uri.parse(
          'https://api.whatsapp.com/send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}'
        );
        
        // Dispara o WhatsApp em segundo plano
        canLaunchUrl(whatsappUri).then((canLaunch) {
          if (canLaunch) {
            launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          }
        }).catchError((_) {});

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: HotelColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                Text('Sucesso!', style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resData['message'] ?? 'Reserva confirmada com sucesso!',
                  style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sua Reserva foi enviada e em breve o Hotel irá entrar em contato para Efetivá-la',
                  style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.darkSlate.withOpacity(0.7)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Clique no botão abaixo para enviar os detalhes pelo WhatsApp para o número do hotel.',
                  style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // fecha modal de sucesso
                  Navigator.of(context).pop(); // fecha formulário
                },
                child: Text('CONCLUIR', style: HotelTypography.buttonText.copyWith(color: HotelColors.darkSlate.withOpacity(0.5))),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (await canLaunchUrl(whatsappUri)) {
                    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text('ABRIR WHATSAPP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HotelColors.primaryGreen,
                  foregroundColor: HotelColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      } else {
        final errBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errBody['details'] ?? errBody['error'] ?? 'Falha ao registrar.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'), 
          backgroundColor: Colors.red, 
          duration: const Duration(seconds: 6)
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cpfCnpjFocus.dispose();
    _cepFocus.dispose();
    _cpfCnpjController.dispose();
    _nomeResponsavelController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    _observacaoController.dispose();
    _qtdeHospedesController.dispose();
    _placaPrincipalController.dispose();
    
    for (var guest in _hospedes) {
      guest.name.dispose();
      guest.cpfController.dispose();
      guest.cpfFocusNode.dispose();
      guest.placa.dispose();
      guest.age.dispose();
    }
    super.dispose();
  }

  Future<void> _showFNRHDialog(int index) async {
    final guest = _hospedes[index];
    
    bool formSubmittedWithErrors = false;

    InputDecoration getDeco(String label, {bool isRequired = false, bool isEmpty = false, String? counterText}) {
      final bool showError = formSubmittedWithErrors && isRequired && isEmpty;
      return InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelText: label + (isRequired ? ' *' : ''),
        labelStyle: HotelTypography.bodyTextSmall.copyWith(fontSize: 13),
        counterText: counterText,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: showError ? Colors.redAccent : HotelColors.accentGold, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: showError ? Colors.redAccent : HotelColors.lightGrey, width: showError ? 1.5 : 1.0),
        ),
        filled: true,
        fillColor: showError ? Colors.redAccent.withOpacity(0.05) : HotelColors.bgLight,
      );
    }

    
    // Temp controllers for modal
    final cNac = TextEditingController(text: guest.nacionalidade);
    final cPaisRes = TextEditingController(text: guest.paisResidencia);
    final cRaca = TextEditingController(text: guest.raca);
    String? sDeficiencia = (guest.deficiencia?.toLowerCase() == 'sim' || guest.deficiencia?.toLowerCase() == 's') ? 'Sim' : 'Não';
    final cTipoDef = TextEditingController(text: guest.tipoDeficiencia);
    final cProf = TextEditingController(text: guest.profissao);
    String? sGen = guest.genero;
    final cNasc = TextEditingController(text: guest.dataNascimento);
    final cFil = TextEditingController(text: guest.filiacao);
    final cCpf = TextEditingController(text: guest.cpfController.text);
    final cRg = TextEditingController(text: guest.rg);
    final cOrgao = TextEditingController(text: guest.orgaoExpedidor);
    final cPass = TextEditingController(text: guest.passaporte);
    final cCep = TextEditingController(text: guest.cep);
    final cEnd = TextEditingController(text: guest.logradouro);
    final cNum = TextEditingController(text: guest.numero);
    final cBairro = TextEditingController(text: guest.bairro);
    final cCidade = TextEditingController(text: guest.cidade);
    final cUf = TextEditingController(text: guest.uf);
    final cTel = TextEditingController(text: guest.telefone);
    final cEmail = TextEditingController(text: guest.email);

    final motivos = ['Lazer / Turismo', 'Negócios', 'Congresso / Convenção', 'Parentes / Amigos', 'Estudos / Cursos', 'Saúde', 'Outro'];
    final metodos = ['Avião', 'Automóvel', 'Ônibus', 'Trem', 'Embarcação', 'Outro'];

    String? sMotivo = motivos.contains(guest.motivoViagem) ? guest.motivoViagem : (guest.motivoViagem?.isNotEmpty == true ? 'Outro' : 'Lazer / Turismo');
    String? sMetodo = metodos.contains(guest.metodoViagem) ? guest.metodoViagem : (guest.metodoViagem?.isNotEmpty == true ? 'Outro' : 'Automóvel');
    String? modalError;

    StateSetter? modalStateSetter;
    String? lastSearchedModalCpf;

    cCpf.addListener(() async {
      final cleanVal = cCpf.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanVal.length != 11) {
        lastSearchedModalCpf = null;
        return;
      }
      if (lastSearchedModalCpf == cleanVal) return;
      lastSearchedModalCpf = cleanVal;

      try {
        final res = await http.get(Uri.parse(ApiConfig.pessoa(cleanVal)));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data != null && data['PES_ID'] != null) {
            if (modalStateSetter != null) {
              modalStateSetter!(() {
                cNac.text = (data['PES_PAIS_NACIONALIDADE']?.toString() ?? '').trim();
                if (cNac.text.isEmpty && data['PES_OBSERVACAO'] != null && data['PES_OBSERVACAO'].toString().contains('Nac/Nat:')) {
                  cNac.text = data['PES_OBSERVACAO'].toString().split('Nac/Nat:').last.split('|').first.trim();
                }
                if (cNac.text.isEmpty || cNac.text.toLowerCase() == 'brasil') cNac.text = 'BR';
                
                cPaisRes.text = (data['PES_PAIS_RESIDENCIA']?.toString() ?? '').trim();
                if (cPaisRes.text.isEmpty || cPaisRes.text.toLowerCase() == 'brasil') cPaisRes.text = 'BR';
                
                if (cNac.text.length > 2) cNac.text = cNac.text.substring(0, 2).toUpperCase();
                if (cPaisRes.text.length > 2) cPaisRes.text = cPaisRes.text.substring(0, 2).toUpperCase();
                cRaca.text = (data['PES_RACA']?.toString() ?? '').trim();
                final def = (data['PES_DEFICIENCIA']?.toString() ?? '').trim().toLowerCase();
                sDeficiencia = (def == 'sim' || def == 's') ? 'Sim' : 'Não';
                cTipoDef.text = (data['PES_TIPO_DEFICIENCIA']?.toString() ?? '').trim();
                cProf.text = (data['PES_PROFISSAO'] ?? '').toString();
                sGen = data['PES_SEXO'] == 'F' ? 'Feminino' : (data['PES_SEXO'] == 'M' ? 'Masculino' : null);
                var dtNasc = (data['PES_DT_NASCIMENTO'] ?? '').toString();
                if (dtNasc.contains('-') && dtNasc.length >= 10) {
                  var parts = dtNasc.substring(0, 10).split('-');
                  if (parts.length == 3 && parts[0].length == 4) {
                    dtNasc = '${parts[2]}/${parts[1]}/${parts[0]}';
                  }
                }
                cNasc.text = dtNasc;
                cFil.text = data['PES_OBSERVACAO'] != null && data['PES_OBSERVACAO'].toString().contains('Filiação:')
                    ? data['PES_OBSERVACAO'].toString().split('Filiação:').last.split('|').first.trim()
                    : '';
                cUf.text = (data['PES_UF']?.toString() ?? '').trim();
                if (cUf.text.isEmpty && data['PES_OBSERVACAO'] != null && data['PES_OBSERVACAO'].toString().contains('UF:')) {
                  cUf.text = data['PES_OBSERVACAO'].toString().split('UF:').last.split('|').first.trim();
                }
                final parsedMetodo = data['PES_OBSERVACAO'] != null && data['PES_OBSERVACAO'].toString().contains('Metodo:')
                    ? data['PES_OBSERVACAO'].toString().split('Metodo:').last.split('|').first.trim()
                    : '';
                if (metodos.contains(parsedMetodo)) {
                  sMetodo = parsedMetodo;
                } else if (parsedMetodo.isNotEmpty) {
                  sMetodo = 'Outro';
                }
                cRg.text = (data['PES_IE_RG'] ?? '').toString();
                cPass.text = (data['PES_DOC_EXTERIOR'] ?? '').toString();
                cCep.text = (data['PES_CEP'] ?? '').toString();
                cEnd.text = (data['PES_ENDERECO'] ?? '').toString().toUpperCase();
                cNum.text = (data['PES_NUMERO'] ?? '').toString();
                cBairro.text = (data['PES_BAIRRO'] ?? '').toString();
                cCidade.text = (data['PES_CIDADE'] ?? '').toString();
                cTel.text = (data['PES_CELULAR'] ?? data['PES_TELEFONE'] ?? '').toString();
                cEmail.text = (data['PES_EMAIL'] ?? '').toString();
                
                guest.name.text = (data['PES_RSOCIAL_NOME'] ?? '').toString().toUpperCase();
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Erro ao buscar hóspede no modal FNRH: $e');
      }
    });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          modalStateSetter = setModalState;
          return AlertDialog(
            backgroundColor: HotelColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ficha de Hóspede (FNRH)', 
                  style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen)
                ),
                const SizedBox(height: 4),
                Text(
                  'Hóspede ${index + 1}: ${guest.name.text.isEmpty ? "Acompanhante" : guest.name.text}', 
                  style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.textGrey, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text('Legislação (FNRH)', style: HotelTypography.cardTitle.copyWith(color: HotelColors.primaryGreen, fontSize: 18)),
                        content: const SingleChildScrollView(
                          child: Text(
                            'Lei do Turismo nº 11.771/2008:\n'
                            'Art. 23. Os meios de hospedagem deverão fornecer ao Ministério do Turismo, em perfil e periodicidade por ele determinados, informações sobre o seu perfil de hóspedes e sobre o seu funcionamento...\n\n'
                            'Decreto nº 7.381/2010:\n'
                            'Art. 18. Para fins do disposto no art. 23 da Lei nº 11.771, de 2008, os meios de hospedagem deverão preencher e manter arquivada a Ficha Nacional de Registro de Hóspedes - FNRH e remeter as informações ao Ministério do Turismo.\n\n'
                            'O não preenchimento ou preenchimento incorreto de dados está sujeito a multas e penalidades aplicáveis aos estabelecimentos e clientes.',
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Entendi', style: HotelTypography.buttonText.copyWith(color: HotelColors.primaryGreen)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Atenção: O preenchimento da FNRH é obrigatório por lei (Lei do Turismo nº 11.771/2008 e Decreto nº 7.381/2010). '
                            'Clique aqui para ver a lei na íntegra.',
                            style: HotelTypography.bodyTextSmall.copyWith(color: Colors.black87, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (modalError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      modalError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            content: SizedBox(
              width: 800,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: HotelColors.lightGrey),
                    const SizedBox(height: 8),
                    Text('1. Dados Pessoais', style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cNac, maxLength: 2, textCapitalization: TextCapitalization.characters, decoration: getDeco('País Nacionalidade', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cPaisRes, maxLength: 2, textCapitalization: TextCapitalization.characters, decoration: getDeco('País de Residência', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cProf, decoration: getDeco('Profissão', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: sGen,
                            dropdownColor: Colors.white,
                            style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                            items: ['Masculino', 'Feminino'].map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (v) { setModalState(() { sGen = v; }); },
                            decoration: getDeco('Gênero', isRequired: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(flex: 2, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cRaca, decoration: getDeco('Raça / Etnia', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cNasc, inputFormatters: [DateDMYFormatter()], keyboardType: TextInputType.number, decoration: getDeco('Data Nasc. (DD/MM/AAAA)', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: sDeficiencia,
                            dropdownColor: Colors.white,
                            style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                            items: ['Não', 'Sim'].map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (v) { setModalState(() { sDeficiencia = v; }); },
                            decoration: getDeco('Deficiência?', isRequired: false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cTipoDef, decoration: getDeco('Tipo Deficiência', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(flex: 3, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cFil, decoration: getDeco('Filiação (Mãe/Pai)', isRequired: false))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('2. Documentos', style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cCpf, decoration: getDeco('CPF', isRequired: true, isEmpty: cCpf.text.trim().isEmpty))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cRg, decoration: getDeco('RG', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cOrgao, decoration: getDeco('Órgão Expedidor', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cPass, decoration: getDeco('Passaporte', isRequired: false))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('3. Dados de Contato e Endereço', style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(flex: 2, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cCep, decoration: getDeco('CEP', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(flex: 4, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cEnd, decoration: getDeco('Logradouro', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cNum, decoration: getDeco('Número', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(flex: 3, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cBairro, decoration: getDeco('Bairro', isRequired: false))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(flex: 3, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cCidade, decoration: getDeco('Cidade', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(flex: 1, child: TextFormField(
                          style: HotelTypography.bodyText(color: HotelColors.darkSlate), 
                          controller: cUf, 
                          decoration: getDeco('UF', isRequired: false, counterText: ''),
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 2,
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        )),
                        const SizedBox(width: 8),
                        Expanded(flex: 3, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cTel, decoration: getDeco('Telefone', isRequired: false))),
                        const SizedBox(width: 8),
                        Expanded(flex: 4, child: TextFormField(style: HotelTypography.bodyText(color: HotelColors.darkSlate), controller: cEmail, decoration: getDeco('E-mail', isRequired: false))),
                      ],
                    ),
 
                    const SizedBox(height: 16),
                    Text('4. Informações da Viagem', style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: sMotivo,
                            dropdownColor: Colors.white,
                            style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                            items: motivos.map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (v) { setModalState(() { sMotivo = v; }); },
                            decoration: getDeco('Motivo da Viagem', isRequired: false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: sMetodo,
                            dropdownColor: Colors.white,
                            style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                            items: metodos.map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (v) { setModalState(() { sMetodo = v; }); },
                            decoration: getDeco('Método de Viagem', isRequired: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar', style: HotelTypography.buttonText.copyWith(color: Colors.redAccent)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HotelColors.primaryGreen,
                  foregroundColor: HotelColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final cleanCpf = cCpf.text.replaceAll(RegExp(r'[^0-9]'), '');
                  final isBr = cNac.text.trim().isEmpty || 
                               cNac.text.trim().toUpperCase() == 'BR' || 
                               cNac.text.trim().toUpperCase() == 'BRASILEIRA' || 
                               cNac.text.trim().toUpperCase() == 'BRASIL' || 
                               cNac.text.trim().toUpperCase() == 'BRASILEIRO';
                  
                  if (_obrigarFNRH && !guest.isChild) {
                    List<String> missing = [];
                    if (cCpf.text.trim().isEmpty) missing.add('CPF');

                    if (missing.isNotEmpty) {
                      setModalState(() {
                        formSubmittedWithErrors = true;
                        modalError = 'Campos vazios: ${missing.join(', ')}';
                      });
                      return;
                    }
                  }

                  guest.nacionalidade = cNac.text;
                  guest.paisResidencia = cPaisRes.text;
                  guest.raca = cRaca.text;
                  guest.deficiencia = sDeficiencia;
                  guest.tipoDeficiencia = cTipoDef.text;
                  guest.profissao = cProf.text;
                  guest.genero = sGen;
                  guest.dataNascimento = cNasc.text;
                  guest.filiacao = cFil.text;
                  guest.cpfController.text = cCpf.text;
                  guest.rg = cRg.text;
                  guest.orgaoExpedidor = cOrgao.text;
                  guest.passaporte = cPass.text;
                  guest.cep = cCep.text;
                  guest.logradouro = cEnd.text;
                  guest.numero = cNum.text;
                  guest.bairro = cBairro.text;
                  guest.cidade = cCidade.text;
                  guest.uf = cUf.text.toUpperCase();
                  guest.telefone = cTel.text;
                  guest.email = cEmail.text;
                  guest.motivoViagem = sMotivo;
                  guest.metodoViagem = sMetodo;
                  Navigator.pop(context);
                },
                child: Text('Salvar Ficha', style: HotelTypography.buttonText),
              ),
            ],
          );
        });
      },
    );
 
    cNac.dispose();
    cProf.dispose();
    cNasc.dispose();
    cFil.dispose();
    cCpf.dispose();
    cRg.dispose();
    cOrgao.dispose();
    cPass.dispose();
    cCep.dispose();
    cEnd.dispose();
    cNum.dispose();
    cBairro.dispose();
    cCidade.dispose();
    cUf.dispose();
    cTel.dispose();
    cEmail.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: HotelColors.lightGrey, width: 1.0),
    );
    final focusBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: HotelColors.accentGold, width: 1.5),
    );

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: HotelColors.white,
      labelStyle: HotelTypography.bodyTextSmall.copyWith(fontSize: 13),
      enabledBorder: borderStyle,
      focusedBorder: focusBorderStyle,
      errorBorder: borderStyle.copyWith(borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: focusBorderStyle.copyWith(borderSide: const BorderSide(color: Colors.redAccent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: HotelColors.bgLight,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: HotelColors.lightGrey),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header do Modal
                Container(
                  color: HotelColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bookmark_add_outlined, color: HotelColors.accentGold, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Formulário de Reserva Online',
                            style: HotelTypography.cardTitle.copyWith(color: HotelColors.white, fontSize: 20),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: HotelColors.white, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                ),
                
                // Formulário Rolável
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. HOTEL/EMPRESA
                          if (_empresas.isNotEmpty) ...[
                            Text('1. Selecione a Unidade', style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: _selectedEmpresaId,
                              decoration: inputDecoration.copyWith(labelText: 'Hotel / Unidade'),
                              dropdownColor: Colors.white,
                              style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                              items: _empresas.map((e) => DropdownMenuItem<int>(value: e['id'], child: Text(e['name']))).toList(),
                              onChanged: (val) => setState(() => _selectedEmpresaId = val),
                              validator: (v) => v == null ? 'Por favor, selecione a unidade' : null,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Ocultado a pedido do usuário: Tipo de Acomodação

                          // 3. DATAS E DISPONIBILIDADE
                          Text('3. Período da Estadia', style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, true),
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: InputDecorator(
                                    decoration: inputDecoration.copyWith(labelText: 'Data Check-in'),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _checkin == null ? 'Selecionar' : DateFormat('dd/MM/yyyy').format(_checkin!), 
                                          style: HotelTypography.bodyText(color: _checkin == null ? HotelColors.textGrey.withOpacity(0.5) : HotelColors.darkSlate),
                                        ),
                                        const Icon(Icons.calendar_today, color: HotelColors.accentGold, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, false),
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: InputDecorator(
                                    decoration: inputDecoration.copyWith(labelText: 'Data Check-out'),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _checkout == null ? 'Selecionar' : DateFormat('dd/MM/yyyy').format(_checkout!), 
                                          style: HotelTypography.bodyText(color: _checkout == null ? HotelColors.textGrey.withOpacity(0.5) : HotelColors.darkSlate),
                                        ),
                                        const Icon(Icons.calendar_today_outlined, color: HotelColors.accentGold, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Ocultado a pedido do usuário: Busca e Seleção de Apartamentos Livres
                          const SizedBox(height: 20),

                          // 4. DADOS DO RESPONSÁVEL
                          Text('4. Dados Pessoais do Responsável', style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                                  controller: _cpfCnpjController,
                                  focusNode: _cpfCnpjFocus,
                                  decoration: inputDecoration.copyWith(labelText: 'CPF / CNPJ'),
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                                  controller: _nomeResponsavelController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: inputDecoration.copyWith(labelText: 'Nome Completo'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                                  controller: _cepController,
                                  focusNode: _cepFocus,
                                  decoration: inputDecoration.copyWith(labelText: 'CEP'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                                  controller: _enderecoController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: inputDecoration.copyWith(labelText: 'Endereço Completo'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                                  controller: _telefoneController,
                                  decoration: inputDecoration.copyWith(labelText: 'Telefone (WhatsApp)'),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                                  controller: _qtdeHospedesController,
                                  decoration: inputDecoration.copyWith(labelText: 'Qtd. Hóspedes'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                            controller: _placaPrincipalController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: inputDecoration.copyWith(labelText: 'Placa Principal do Veículo (Opcional)'),
                          ),
                          const SizedBox(height: 20),

                          // 5. RELAÇÃO DE HÓSPEDES
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('5. Identificação dos Hóspedes', style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Text('1º hóspede é o responsável?', style: HotelTypography.bodyTextSmall.copyWith(fontSize: 12)),
                                  Checkbox(
                                    value: _isFirstGuestResponsavel,
                                    activeColor: HotelColors.primaryGreen,
                                    onChanged: (val) {
                                      setState(() {
                                        _isFirstGuestResponsavel = val ?? true;
                                        if (_isFirstGuestResponsavel && _hospedes.isNotEmpty) {
                                          _hospedes[0].name.text = _nomeResponsavelController.text;
                                          _hospedes[0].cpfController.text = _cpfCnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
                                          _hospedes[0].cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
                                          _hospedes[0].logradouro = _enderecoController.text.toUpperCase();
                                          _hospedes[0].telefone = _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
                                        } else if (_hospedes.isNotEmpty) {
                                          _hospedes[0].name.clear();
                                          _hospedes[0].cpfController.text = '';
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _hospedes.length,
                            itemBuilder: (context, index) {
                              final guest = _hospedes[index];
                              return Card(
                                color: HotelColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: HotelColors.lightGrey),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: HotelColors.accentGold,
                                            child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                                              controller: guest.cpfController,
                                              focusNode: guest.cpfFocusNode,
                                              decoration: inputDecoration.copyWith(
                                                labelText: 'CPF',
                                              ),
                                              keyboardType: TextInputType.number,
                                              enabled: !(index == 0 && _isFirstGuestResponsavel),
                                              validator: (v) {
                                                if (index == 0) {
                                                  if (v == null || v.trim().isEmpty) return 'CPF obrigatório';
                                                } else {
                                                  if (guest.isChild) return null;
                                                  if (v == null || v.trim().isEmpty) return 'CPF obrigatório';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 3,
                                            child: TextFormField(
                                              style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                                              controller: guest.name,
                                              textCapitalization: TextCapitalization.characters,
                                              decoration: inputDecoration.copyWith(
                                                labelText: index == 0 ? 'Nome do Responsável' : 'Nome Completo',
                                              ),
                                              enabled: !(index == 0 && _isFirstGuestResponsavel),
                                              validator: (v) => v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showFNRHDialog(index),
                                          icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                                          label: const Text('Preencher Ficha de Hóspede (FNRH)'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: HotelColors.primaryGreen,
                                            side: const BorderSide(color: HotelColors.primaryGreen),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: guest.hasVehicle,
                                            activeColor: HotelColors.primaryGreen,
                                            onChanged: (val) => setState(() => guest.hasVehicle = val ?? false),
                                          ),
                                          Text('Possui veículo?', style: HotelTypography.bodyTextSmall),
                                          if (guest.hasVehicle) ...[
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                                                controller: guest.placa,
                                                textCapitalization: TextCapitalization.characters,
                                                decoration: inputDecoration.copyWith(labelText: 'Placa'),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(width: 16),
                                          Checkbox(
                                            value: guest.isChild,
                                            activeColor: HotelColors.primaryGreen,
                                            onChanged: (val) => setState(() => guest.isChild = val ?? false),
                                          ),
                                          Text('Menor?', style: HotelTypography.bodyTextSmall),
                                          if (guest.isChild) ...[
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                                                controller: guest.age,
                                                keyboardType: TextInputType.number,
                                                decoration: inputDecoration.copyWith(labelText: 'Idade'),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // 6. OBSERVAÇÕES
                          Text('6. Informações Adicionais', style: HotelTypography.bodyTextSmall.copyWith(color: HotelColors.accentGold, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            style: HotelTypography.bodyText(color: HotelColors.darkSlate),
                            controller: _observacaoController,
                            decoration: inputDecoration.copyWith(labelText: 'Observações Extras (Ex: Berço, Restrições Alimentares)'),
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 32),
                          
                          // 7. CONFIRMAÇÃO
                          Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: HotelColors.goldGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: HotelColors.accentGold.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitReservation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: HotelColors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('CONFIRMAR RESERVA', style: HotelTypography.buttonText.copyWith(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
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
