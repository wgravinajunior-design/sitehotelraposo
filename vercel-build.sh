#!/bin/bash

# Baixar e instalar o SDK do Flutter na máquina da Vercel
echo "Clonando o Flutter..."
git clone https://github.com/flutter/flutter.git -b stable

# Adicionar o Flutter ao PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Habilitar suporte a Web
flutter config --enable-web

# Instalar as dependências
echo "Instalando dependências..."
flutter pub get

# Compilar o projeto para a Web
echo "Compilando para web com API: $API_BASE_URL"
if [ -z "$API_BASE_URL" ]; then
  flutter build web --release
else
  flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"
fi
