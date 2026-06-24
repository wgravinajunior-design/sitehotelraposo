@echo off
echo ============================================
echo   DEPLOY - Hotel Fazenda Raposo (Frontend)
echo ============================================
echo.

REM --- Configuracao ---
REM Altere a URL abaixo para o endereco publico da sua API Delphi
REM Exemplo: http://seuip:3000  ou  https://api.hotelfazendaraposo.com.br
SET API_URL=%1
IF "%API_URL%"=="" (
    echo [ERRO] Informe a URL da API como parametro.
    echo.
    echo Uso: deploy.bat http://seuip:3000
    echo.
    pause
    exit /b 1
)

echo [1/3] Limpando build anterior...
call flutter clean

echo.
echo [2/3] Buildando Flutter Web (Release)...
echo       API_BASE_URL = %API_URL%
call flutter build web --release --dart-define=API_BASE_URL=%API_URL%

IF ERRORLEVEL 1 (
    echo.
    echo [ERRO] Falha no build do Flutter. Verifique os erros acima.
    pause
    exit /b 1
)

echo.
echo [3/3] Build concluido com sucesso!
echo.
echo Os arquivos estaticos estao em: build\web
echo.
echo ============================================
echo   PROXIMOS PASSOS:
echo ============================================
echo.
echo   1. Para deploy na Vercel (primeira vez):
echo      cd build\web
echo      npx vercel --prod
echo.
echo   2. Para deploy na Vercel (atualizacoes):
echo      cd build\web
echo      npx vercel --prod
echo.
echo   3. Para subir no GitHub:
echo      git add .
echo      git commit -m "deploy: frontend v1.0"
echo      git push origin main
echo.
pause
