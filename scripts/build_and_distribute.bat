@echo off
REM ============================================
REM Script para build e distribuição do App
REM ============================================

echo.
echo ========================================
echo    Build App Scheibell para Producao
echo ========================================
echo.

REM Verificar se Firebase CLI está instalado
where firebase >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERRO] Firebase CLI nao encontrado!
    echo Instale com: npm install -g firebase-tools
    echo Depois faca login: firebase login
    exit /b 1
)

REM Navegar para o diretório do projeto
cd /d "%~dp0.."

echo [1/4] Limpando build anterior...
call flutter clean

echo.
echo [2/4] Obtendo dependencias...
call flutter pub get

echo.
echo [3/4] Gerando APK de producao...
call flutter build apk --release --dart-define=PROD=true

if %ERRORLEVEL% neq 0 (
    echo [ERRO] Falha ao gerar APK!
    exit /b 1
)

echo.
echo [4/4] Enviando para Firebase App Distribution...
echo.

REM Substitua YOUR_APP_ID pelo ID do seu app Firebase
REM Encontre em: Firebase Console > Project Settings > Your apps > App ID
set FIREBASE_APP_ID=1:XXXXXXXXXX:android:XXXXXXXXXX

REM Grupos de testadores (crie no Firebase Console)
set TESTERS_GROUP=testers

firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk ^
    --app %FIREBASE_APP_ID% ^
    --groups "%TESTERS_GROUP%" ^
    --release-notes "Build de teste - %date% %time%"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [AVISO] Falha ao enviar para Firebase.
    echo O APK foi gerado com sucesso em:
    echo   build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Voce pode enviar manualmente pelo Firebase Console.
    exit /b 0
)

echo.
echo ========================================
echo    Build e distribuicao concluidos!
echo ========================================
echo.
echo Os testadores receberao um email/notificacao
echo para baixar a nova versao do app.
echo.

pause
