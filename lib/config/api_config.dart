import 'package:flutter/foundation.dart';

class ApiConfig {
  /// URL base da API.
  /// Em desenvolvimento (debug) aponta para localhost.
  /// Em produção, usa a variável de ambiente API_BASE_URL definida no build
  /// ou no index.html (via JavaScript).
  static String get baseUrl {
    // 1. Tenta ler a variável de ambiente passada no build:
    //    flutter build web --dart-define=API_BASE_URL=https://meuservidor.com:3000
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    // 2. Se estiver em modo debug, usa localhost
    if (kDebugMode) return 'http://localhost:3000';

    // 3. Produção sem variável definida: usa caminho relativo
    //    (funciona se a API estiver no mesmo domínio/servidor)
    return '';
  }

  // Rotas da API
  static String get empresas => '$baseUrl/api/empresas';
  static String get apartmentTypes => '$baseUrl/api/apartment-types';
  static String get config => '$baseUrl/api/config';
  static String hospedagemTypes(String tipoApId) =>
      '$baseUrl/api/hospedagem-types?tipoApId=$tipoApId';
  static String cep(String cep) => '$baseUrl/api/cep/$cep';
  static String cnpj(String cnpj) => '$baseUrl/api/cnpj/$cnpj';
  static String pessoa(String cpfCnpj) => '$baseUrl/api/pessoa/$cpfCnpj';
  static String availableApartments(String checkin, String checkout,
      {String? tipoApId, String? hospedagemTipoId}) {
    var url =
        '$baseUrl/api/available-apartments?checkin=$checkin&checkout=$checkout';
    if (tipoApId != null && tipoApId.isNotEmpty) url += '&tipoApId=$tipoApId';
    if (hospedagemTipoId != null && hospedagemTipoId.isNotEmpty) {
      url += '&hospedagemTipoId=$hospedagemTipoId';
    }
    return url;
  }

  static String get reservation => '$baseUrl/api/reservation';
}
