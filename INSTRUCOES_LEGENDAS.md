# Instruções para Ativar Legendas Automáticas

## 1. Adicionar colunas no Supabase

Acesse o Supabase Dashboard > SQL Editor e execute:

```sql
ALTER TABLE clinic_videos
ADD COLUMN IF NOT EXISTS "subtitleStatus" text DEFAULT 'PENDING',
ADD COLUMN IF NOT EXISTS "subtitleUrl" text,
ADD COLUMN IF NOT EXISTS "subtitleError" text,
ADD COLUMN IF NOT EXISTS "subtitleLanguage" text DEFAULT 'pt';

-- Atualizar vídeos existentes
UPDATE clinic_videos SET "subtitleStatus" = 'PENDING' WHERE "subtitleStatus" IS NULL;
```

## 2. Configurar o Backend

O backend precisa ter a variável de ambiente OPENAI_API_KEY configurada no arquivo `.env`:

```env
OPENAI_API_KEY=sua-chave-openai-aqui
```

## 3. Instalar ffmpeg (necessário para extrair áudio)

No macOS:
```bash
brew install ffmpeg
```

## 4. Gerar legendas para um vídeo

O backend tem um endpoint para iniciar a transcrição:

```bash
POST /api/transcription/start/{videoId}
```

Ou você pode gerar legendas clicando em "Gerar Legendas" no menu do vídeo na Biblioteca de Mídia (admin).

## 5. Como funciona

1. O vídeo é baixado do Supabase Storage
2. O áudio é extraído usando ffmpeg
3. O áudio é enviado para a API Whisper da OpenAI
4. O resultado é convertido para formato VTT (WebVTT)
5. O arquivo VTT é salvo no Supabase Storage
6. O campo `subtitleUrl` é atualizado com a URL do arquivo VTT
7. O campo `subtitleStatus` é atualizado para 'COMPLETED'

## 6. Status possíveis

- `PENDING`: Aguardando processamento
- `PROCESSING`: Processando transcrição
- `COMPLETED`: Legendas prontas
- `FAILED`: Erro na transcrição (ver campo `subtitleError`)

## 7. No App

Quando `subtitleStatus` = 'COMPLETED' e `subtitleUrl` existe:
- O botão CC aparece no player de vídeo
- O paciente pode ativar/desativar legendas
