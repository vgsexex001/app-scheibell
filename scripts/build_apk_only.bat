@echo off
REM ============================================
REM Script para gerar APK de producao
REM ============================================

echo.
echo ========================================
echo    Build APK App Scheibell
echo ========================================
echo.

REM Navegar para o diretório do projeto
cd /d "%~dp0.."

echo [1/3] Limpando build anterior...
call flutter clean

echo.
echo [2/3] Obtendo dependencias...
call flutter pub get

echo.
echo [3/3] Gerando APK de producao...
call flutter build apk --release --dart-define=PROD=true

if %ERRORLEVEL% neq 0 (
    echo [ERRO] Falha ao gerar APK!
    exit /b 1
)

echo.
echo ========================================
echo    APK gerado com sucesso!
echo ========================================
echo.
echo Localizacao do APK:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
echo Tamanho do arquivo:
for %%A in (build\app\outputs\flutter-apk\app-release.apk) do echo   %%~zA bytes

echo.
echo Abrindo pasta do APK...
start "" "build\app\outputs\flutter-apk"

pause
