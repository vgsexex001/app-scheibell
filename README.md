# App Scheibell

Sistema de gerenciamento clínico/saúde para acompanhamento de pacientes pós-operatórios.

## Stack Tecnológica

- **Frontend**: Flutter (iOS, Android, Web)
- **Backend**: NestJS + Prisma ORM
- **Banco de Dados**: PostgreSQL
- **Deploy**: Google Cloud (Cloud Run + Cloud SQL)

## Estrutura do Projeto

```
app-scheibell/
├── lib/                    # Flutter app
│   ├── core/              # Providers, models, routes
│   ├── features/          # Funcionalidades (patient, clinic, third_party)
│   ├── shared/            # Componentes e telas compartilhadas
│   └── config/            # Configurações de tema
├── backend/               # NestJS API
│   ├── src/
│   │   ├── modules/       # Módulos (auth, content, health)
│   │   ├── prisma/        # Serviço do banco de dados
│   │   └── common/        # Guards e decorators
│   └── prisma/            # Schema e migrations
└── docker-compose.yml     # Ambiente de desenvolvimento
```

## Setup Local

### Pré-requisitos

- Node.js 18+
- Flutter 3.10+
- Docker e Docker Compose
- PostgreSQL (ou use Docker)

### Backend

```bash
# 1. Entrar na pasta do backend
cd backend

# 2. Instalar dependências
npm install

# 3. Copiar variáveis de ambiente
cp .env.example .env

# 4. Editar .env com suas configurações locais

# 5. Iniciar banco de dados (via Docker)
docker-compose up -d postgres

# 6. Executar migrations
npx prisma migrate deploy

# 7. Popular banco com dados iniciais
npm run prisma:seed

# 8. Iniciar servidor de desenvolvimento
npm run start:dev
```

O backend estará disponível em `http://localhost:3000/api`

### Frontend (Flutter)

```bash
# 1. Instalar dependências
flutter pub get

# 2. Executar app
flutter run
```

## Endpoints da API

### Autenticação
- `POST /api/auth/register` - Criar conta                             
- `POST /api/auth/login` - Login
- `GET /api/auth/me` - Perfil do usuário autenticado
- `GET /api/auth/validate` - Validar token

### Conteúdo (requer autenticação)
- `GET /api/content/clinic` - Listar conteúdos da clínica
- `POST /api/content/clinic` - Criar conteúdo
- `PUT /api/content/clinic/:id` - Atualizar conteúdo
- `DELETE /api/content/clinic/:id` - Remover conteúdo

### Health Check
- `GET /api/health` - Status geral
- `GET /api/health/live` - Liveness probe
- `GET /api/health/ready` - Readiness probe

## Variáveis de Ambiente

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `DATABASE_URL` | URL de conexão PostgreSQL | `postgresql://user:pass@localhost:5432/db` |
| `JWT_SECRET` | Chave secreta para tokens JWT | `sua-chave-secreta` |
| `JWT_EXPIRATION` | Tempo de expiração do token | `24h` |
| `PORT` | Porta do servidor | `3000` |
| `CORS_ORIGINS` | Origins permitidos (CORS) | `http://localhost:3000` |

## Deploy (Google Cloud)

### Cloud Run

```bash
# Build da imagem
docker build -t gcr.io/PROJECT_ID/app-scheibell-api ./backend

# Push para Container Registry
docker push gcr.io/PROJECT_ID/app-scheibell-api

# Deploy no Cloud Run
gcloud run deploy app-scheibell-api \
  --image gcr.io/PROJECT_ID/app-scheibell-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### Cloud SQL

1. Criar instância PostgreSQL no Cloud SQL
2. Configurar conexão no Cloud Run via Cloud SQL Connector
3. Atualizar `DATABASE_URL` nas variáveis de ambiente

## Roles de Usuário

| Role | Descrição |
|------|-----------|
| `PATIENT` | Paciente - visualiza conteúdo personalizado |
| `CLINIC_ADMIN` | Administrador da clínica - gerencia tudo |
| `CLINIC_STAFF` | Funcionário da clínica - gerencia pacientes |
| `THIRD_PARTY` | Terceiros (acompanhantes, familiares) |

## Licença

Proprietary - Todos os direitos reservados.
