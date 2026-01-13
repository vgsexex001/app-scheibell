# Arquitetura da Home Dinâmica Inteligente

## Visão Geral

A Home do paciente deve funcionar como um **resumo inteligente do dia**, mostrando apenas o que é relevante no momento atual. Ela é o coração da experiência do usuário e deve parecer **viva, personalizada e contextual**.

---

## 1. Modelagem de Entidades

### 1.1 Entidades Existentes (Já no Prisma)

```prisma
// Já existem no schema atual:
- MedicationLog      // Registro de medicações tomadas
- ClinicContent      // Conteúdos (medicações, vídeos, tarefas)
- PatientContentAdjustment  // Ajustes por paciente
- TrainingProtocol   // Protocolo de treino
- PatientSessionCompletion  // Sessões completadas
```

### 1.2 Novas Entidades Necessárias

```prisma
// =============================================
// PROGRESSO DE VÍDEO (Nova entidade)
// =============================================
model VideoProgress {
  id            String   @id @default(uuid())
  patientId     String
  contentId     String   // Referência ao ClinicContent do vídeo

  // Progresso
  watchedSeconds    Int      @default(0)    // Segundos assistidos
  totalSeconds      Int                      // Duração total do vídeo
  progressPercent   Float    @default(0)    // 0-100%
  isCompleted       Boolean  @default(false)

  // Timestamps
  lastWatchedAt DateTime @default(now())
  completedAt   DateTime?
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  // Relações
  patient       Patient       @relation(fields: [patientId], references: [id])
  content       ClinicContent @relation(fields: [contentId], references: [id])

  @@unique([patientId, contentId])
  @@index([patientId])
  @@index([contentId])
}

// =============================================
// TAREFAS DO PACIENTE (Nova entidade)
// =============================================
model PatientTask {
  id            String   @id @default(uuid())
  patientId     String
  clinicId      String

  // Dados da tarefa
  title         String
  description   String?
  category      TaskCategory  @default(CARE)
  priority      TaskPriority  @default(MEDIUM)

  // Agendamento
  scheduledDate DateTime?     // Data específica (null = recorrente)
  scheduledTime String?       // Horário "HH:mm"
  dueDate       DateTime?     // Prazo final

  // Recorrência
  isRecurring   Boolean  @default(false)
  recurrenceRule String?  // "DAILY", "WEEKLY:MON,WED,FRI", etc

  // Validade por dia pós-op (como ClinicContent)
  validFromDay  Int?
  validUntilDay Int?

  // Status
  status        TaskStatus @default(PENDING)
  completedAt   DateTime?
  completedNote String?

  // Origem
  sourceType    TaskSource @default(CLINIC)
  sourceId      String?    // ID do ClinicContent ou TrainingSession

  // Timestamps
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  // Relações
  patient       Patient  @relation(fields: [patientId], references: [id])
  clinic        Clinic   @relation(fields: [clinicId], references: [id])

  @@index([patientId, status])
  @@index([patientId, scheduledDate])
  @@index([clinicId])
}

// =============================================
// LOG DE TAREFAS COMPLETADAS (Histórico)
// =============================================
model TaskCompletionLog {
  id            String   @id @default(uuid())
  taskId        String
  patientId     String

  completedAt   DateTime @default(now())
  scheduledFor  DateTime // Para qual dia foi completada
  notes         String?

  task          PatientTask @relation(fields: [taskId], references: [id])
  patient       Patient     @relation(fields: [patientId], references: [id])

  @@index([patientId, scheduledFor])
}

// =============================================
// ENUMS NOVOS
// =============================================
enum TaskCategory {
  CARE          // Cuidados pós-operatórios
  MEDICATION    // Relacionado a medicação
  EXERCISE      // Exercícios/Fisioterapia
  DIET          // Alimentação
  HYGIENE       // Higiene
  REST          // Descanso
  APPOINTMENT   // Lembrete de consulta
  CUSTOM        // Personalizado
}

enum TaskPriority {
  LOW
  MEDIUM
  HIGH
  URGENT
}

enum TaskStatus {
  PENDING       // Aguardando
  IN_PROGRESS   // Em andamento
  COMPLETED     // Concluída
  SKIPPED       // Pulada
  OVERDUE       // Atrasada
}

enum TaskSource {
  CLINIC        // Criada pela clínica
  SYSTEM        // Gerada automaticamente
  PATIENT       // Criada pelo paciente
  TRAINING      // Derivada do protocolo de treino
}
```

---

## 2. Estado e Persistência

### 2.1 Medicações

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUXO DE MEDICAÇÕES                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ClinicContent (type=MEDICATIONS)                           │
│  ┌─────────────────────────────────────┐                    │
│  │ id: "med-123"                        │                    │
│  │ title: "Dipirona 500mg"              │                    │
│  │ description: "Horários: 08:00,14:00" │                    │
│  │ validFromDay: 1                      │                    │
│  │ validUntilDay: 7                     │                    │
│  └─────────────────────────────────────┘                    │
│                       │                                      │
│                       ▼                                      │
│  MedicationLog (quando tomado)                              │
│  ┌─────────────────────────────────────┐                    │
│  │ contentId: "med-123"                 │                    │
│  │ patientId: "patient-456"             │                    │
│  │ scheduledTime: "08:00"               │                    │
│  │ takenAt: "2026-01-13T08:15:00"       │                    │
│  └─────────────────────────────────────┘                    │
│                                                              │
│  Estado calculado em runtime:                                │
│  - TOMADO: existe log para hoje+horário                     │
│  - PENDENTE: horário futuro hoje                            │
│  - PERDIDO: horário passado sem log                         │
│  - N/A: não aplicável ao dia atual                          │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Vídeos

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUXO DE VÍDEOS                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ClinicContent (type=CARE, com videoUrl)                    │
│  ┌─────────────────────────────────────┐                    │
│  │ id: "video-789"                      │                    │
│  │ title: "Como limpar o nariz"         │                    │
│  │ videoUrl: "https://..."              │                    │
│  │ videoDuration: 180                   │ (3 minutos)       │
│  │ validFromDay: 3                      │                    │
│  │ validUntilDay: 14                    │                    │
│  └─────────────────────────────────────┘                    │
│                       │                                      │
│                       ▼                                      │
│  VideoProgress (progresso salvo)                            │
│  ┌─────────────────────────────────────┐                    │
│  │ contentId: "video-789"               │                    │
│  │ patientId: "patient-456"             │                    │
│  │ watchedSeconds: 95                   │                    │
│  │ totalSeconds: 180                    │                    │
│  │ progressPercent: 52.7                │                    │
│  │ isCompleted: false                   │                    │
│  │ lastWatchedAt: "2026-01-12T..."      │                    │
│  └─────────────────────────────────────┘                    │
│                                                              │
│  Regra: Vídeo é "completo" quando progressPercent >= 90%    │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Tarefas

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUXO DE TAREFAS                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PatientTask                                                 │
│  ┌─────────────────────────────────────┐                    │
│  │ id: "task-001"                       │                    │
│  │ title: "Aplicar gelo no nariz"       │                    │
│  │ category: CARE                       │                    │
│  │ scheduledTime: "10:00"               │                    │
│  │ isRecurring: true                    │                    │
│  │ recurrenceRule: "DAILY"              │                    │
│  │ validFromDay: 1                      │                    │
│  │ validUntilDay: 5                     │                    │
│  │ status: PENDING                      │                    │
│  └─────────────────────────────────────┘                    │
│                       │                                      │
│                       ▼                                      │
│  TaskCompletionLog (quando concluída)                       │
│  ┌─────────────────────────────────────┐                    │
│  │ taskId: "task-001"                   │                    │
│  │ patientId: "patient-456"             │                    │
│  │ scheduledFor: "2026-01-13"           │                    │
│  │ completedAt: "2026-01-13T10:05:00"   │                    │
│  └─────────────────────────────────────┘                    │
│                                                              │
│  Para tarefas recorrentes:                                   │
│  - PatientTask mantém definição                             │
│  - TaskCompletionLog registra cada conclusão                │
│  - Status calculado diariamente                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Lógica do Backend (Home Service)

### 3.1 Algoritmo de Decisão

```typescript
// home.service.ts

interface HomeItem {
  id: string;
  type: 'MEDICATION' | 'VIDEO' | 'TASK' | 'APPOINTMENT';
  priority: number; // 1-100 (maior = mais importante)
  status: 'PENDING' | 'IN_PROGRESS' | 'OVERDUE' | 'UPCOMING';
  title: string;
  subtitle?: string;
  scheduledTime?: string;
  action?: {
    type: 'TAKE' | 'WATCH' | 'COMPLETE' | 'VIEW';
    label: string;
  };
  metadata?: Record<string, any>;
}

interface HomeResponse {
  greeting: string;
  dayPostOp: number;
  summary: {
    medicationsPending: number;
    tasksPending: number;
    videosIncomplete: number;
  };
  items: HomeItem[];
  nextAppointment?: {
    id: string;
    date: string;
    type: string;
  };
}

async function getHomeData(patientId: string): Promise<HomeResponse> {
  const now = new Date();
  const currentHour = now.getHours();
  const today = startOfDay(now);

  // 1. Buscar dados do paciente
  const patient = await getPatientWithClinic(patientId);
  const dayPostOp = calculateDayPostOp(patient.surgeryDate);

  // 2. Coletar itens de todas as fontes
  const items: HomeItem[] = [];

  // 2.1 MEDICAÇÕES
  const medications = await getMedicationsForHome(patient, dayPostOp, currentHour);
  items.push(...medications);

  // 2.2 VÍDEOS
  const videos = await getVideosForHome(patient, dayPostOp);
  items.push(...videos);

  // 2.3 TAREFAS
  const tasks = await getTasksForHome(patient, dayPostOp, today);
  items.push(...tasks);

  // 3. Ordenar por prioridade
  items.sort((a, b) => {
    // Primeiro por status (OVERDUE > PENDING > IN_PROGRESS > UPCOMING)
    const statusOrder = { OVERDUE: 0, PENDING: 1, IN_PROGRESS: 2, UPCOMING: 3 };
    const statusDiff = statusOrder[a.status] - statusOrder[b.status];
    if (statusDiff !== 0) return statusDiff;

    // Depois por prioridade numérica
    return b.priority - a.priority;
  });

  // 4. Limitar quantidade (não poluir Home)
  const maxItems = 8;
  const limitedItems = items.slice(0, maxItems);

  // 5. Buscar próximo agendamento
  const nextAppointment = await getNextAppointment(patientId);

  // 6. Calcular sumário
  const summary = {
    medicationsPending: medications.filter(m => m.status === 'PENDING').length,
    tasksPending: tasks.filter(t => t.status === 'PENDING').length,
    videosIncomplete: videos.length,
  };

  return {
    greeting: getGreeting(currentHour, patient.user.name),
    dayPostOp,
    summary,
    items: limitedItems,
    nextAppointment,
  };
}
```

### 3.2 Filtros por Tipo

```typescript
// =============================================
// MEDICAÇÕES PARA HOME
// =============================================
async function getMedicationsForHome(
  patient: Patient,
  dayPostOp: number,
  currentHour: number
): Promise<HomeItem[]> {
  const items: HomeItem[] = [];

  // 1. Buscar medicações ativas para o dia pós-op atual
  const medications = await prisma.clinicContent.findMany({
    where: {
      clinicId: patient.clinicId,
      type: 'MEDICATIONS',
      isActive: true,
      validFromDay: { lte: dayPostOp },
      validUntilDay: { gte: dayPostOp },
    },
  });

  // 2. Aplicar ajustes do paciente (DISABLE, MODIFY)
  const adjustedMedications = await applyPatientAdjustments(
    medications,
    patient.id
  );

  // 3. Buscar logs de hoje
  const todayLogs = await prisma.medicationLog.findMany({
    where: {
      patientId: patient.id,
      takenAt: { gte: startOfDay(new Date()) },
    },
  });

  // 4. Processar cada medicação
  for (const med of adjustedMedications) {
    const schedules = parseSchedules(med.description); // ["08:00", "14:00", "20:00"]

    for (const schedule of schedules) {
      const scheduleHour = parseInt(schedule.split(':')[0]);

      // Verificar se já foi tomado
      const wasTaken = todayLogs.some(
        log => log.contentId === med.id && log.scheduledTime === schedule
      );

      if (wasTaken) {
        // Já tomado - NÃO mostrar na Home
        continue;
      }

      // Calcular status e prioridade
      let status: 'PENDING' | 'OVERDUE' | 'UPCOMING';
      let priority: number;

      if (scheduleHour < currentHour) {
        // Horário passou e não tomou = ATRASADO
        status = 'OVERDUE';
        priority = 95; // Alta prioridade
      } else if (scheduleHour === currentHour) {
        // É agora!
        status = 'PENDING';
        priority = 90;
      } else if (scheduleHour <= currentHour + 2) {
        // Próximas 2 horas
        status = 'UPCOMING';
        priority = 70;
      } else {
        // Muito futuro - não mostrar
        continue;
      }

      items.push({
        id: `med-${med.id}-${schedule}`,
        type: 'MEDICATION',
        priority,
        status,
        title: med.title,
        subtitle: status === 'OVERDUE'
          ? `Atrasado - era às ${schedule}`
          : `Tomar às ${schedule}`,
        scheduledTime: schedule,
        action: {
          type: 'TAKE',
          label: 'Tomar agora',
        },
        metadata: {
          contentId: med.id,
          scheduledTime: schedule,
        },
      });
    }
  }

  return items;
}

// =============================================
// VÍDEOS PARA HOME
// =============================================
async function getVideosForHome(
  patient: Patient,
  dayPostOp: number
): Promise<HomeItem[]> {
  const items: HomeItem[] = [];

  // 1. Buscar vídeos válidos para o dia atual
  const videos = await prisma.clinicContent.findMany({
    where: {
      clinicId: patient.clinicId,
      type: { in: ['CARE', 'TRAINING'] },
      isActive: true,
      videoUrl: { not: null },
      validFromDay: { lte: dayPostOp },
      validUntilDay: { gte: dayPostOp },
    },
  });

  // 2. Buscar progresso do paciente
  const progress = await prisma.videoProgress.findMany({
    where: {
      patientId: patient.id,
      contentId: { in: videos.map(v => v.id) },
    },
  });

  const progressMap = new Map(progress.map(p => [p.contentId, p]));

  // 3. Filtrar apenas vídeos incompletos
  for (const video of videos) {
    const videoProgress = progressMap.get(video.id);

    // Se completo, não mostrar
    if (videoProgress?.isCompleted) {
      continue;
    }

    // Se nunca assistiu ou está em andamento
    const hasStarted = videoProgress && videoProgress.watchedSeconds > 0;

    items.push({
      id: `video-${video.id}`,
      type: 'VIDEO',
      priority: hasStarted ? 75 : 50, // Em andamento tem prioridade maior
      status: hasStarted ? 'IN_PROGRESS' : 'PENDING',
      title: video.title,
      subtitle: hasStarted
        ? `${Math.round(videoProgress.progressPercent)}% assistido`
        : 'Vídeo importante',
      action: {
        type: 'WATCH',
        label: hasStarted ? 'Continuar' : 'Assistir',
      },
      metadata: {
        contentId: video.id,
        videoUrl: video.videoUrl,
        progress: videoProgress?.progressPercent || 0,
        watchedSeconds: videoProgress?.watchedSeconds || 0,
      },
    });
  }

  return items;
}

// =============================================
// TAREFAS PARA HOME
// =============================================
async function getTasksForHome(
  patient: Patient,
  dayPostOp: number,
  today: Date
): Promise<HomeItem[]> {
  const items: HomeItem[] = [];
  const currentHour = new Date().getHours();

  // 1. Buscar tarefas válidas para hoje
  const tasks = await prisma.patientTask.findMany({
    where: {
      patientId: patient.id,
      OR: [
        // Tarefas com data específica = hoje
        { scheduledDate: today },
        // Tarefas recorrentes válidas para o dia pós-op
        {
          isRecurring: true,
          validFromDay: { lte: dayPostOp },
          validUntilDay: { gte: dayPostOp },
        },
      ],
    },
  });

  // 2. Buscar logs de conclusão de hoje
  const completionLogs = await prisma.taskCompletionLog.findMany({
    where: {
      patientId: patient.id,
      scheduledFor: today,
    },
  });

  const completedTaskIds = new Set(completionLogs.map(l => l.taskId));

  // 3. Filtrar tarefas pendentes
  for (const task of tasks) {
    // Se já completou hoje, não mostrar
    if (completedTaskIds.has(task.id)) {
      continue;
    }

    // Calcular status
    let status: 'PENDING' | 'OVERDUE' | 'UPCOMING';
    let priority: number;

    if (task.scheduledTime) {
      const taskHour = parseInt(task.scheduledTime.split(':')[0]);

      if (taskHour < currentHour) {
        status = 'OVERDUE';
        priority = task.priority === 'URGENT' ? 98 : 85;
      } else if (taskHour === currentHour) {
        status = 'PENDING';
        priority = task.priority === 'URGENT' ? 95 : 80;
      } else {
        status = 'UPCOMING';
        priority = 60;
      }
    } else {
      // Sem horário específico
      status = 'PENDING';
      priority = task.priority === 'URGENT' ? 90 : 65;
    }

    items.push({
      id: `task-${task.id}`,
      type: 'TASK',
      priority,
      status,
      title: task.title,
      subtitle: task.scheduledTime
        ? `${status === 'OVERDUE' ? 'Era' : 'Fazer'} às ${task.scheduledTime}`
        : task.description,
      scheduledTime: task.scheduledTime,
      action: {
        type: 'COMPLETE',
        label: 'Concluir',
      },
      metadata: {
        taskId: task.id,
        category: task.category,
      },
    });
  }

  return items;
}
```

---

## 4. Endpoints da API

### 4.1 Endpoint Principal da Home

```typescript
// GET /api/patient/home
// Retorna todos os dados necessários para a Home em uma única chamada

@Controller('api/patient')
export class HomeController {

  @Get('home')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('PATIENT')
  async getHome(
    @CurrentUser('patientId') patientId: string,
  ): Promise<HomeResponse> {
    return this.homeService.getHomeData(patientId);
  }

  // Ação: Marcar medicação como tomada
  @Post('home/medication/take')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('PATIENT')
  async takeMedication(
    @CurrentUser('patientId') patientId: string,
    @Body() dto: TakeMedicationDto,
  ) {
    return this.homeService.takeMedication(patientId, dto);
  }

  // Ação: Completar tarefa
  @Post('home/task/complete')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('PATIENT')
  async completeTask(
    @CurrentUser('patientId') patientId: string,
    @Body() dto: CompleteTaskDto,
  ) {
    return this.homeService.completeTask(patientId, dto);
  }

  // Ação: Atualizar progresso de vídeo
  @Post('home/video/progress')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('PATIENT')
  async updateVideoProgress(
    @CurrentUser('patientId') patientId: string,
    @Body() dto: UpdateVideoProgressDto,
  ) {
    return this.homeService.updateVideoProgress(patientId, dto);
  }
}
```

### 4.2 DTOs

```typescript
// take-medication.dto.ts
class TakeMedicationDto {
  @IsString()
  contentId: string;

  @IsString()
  @Matches(/^\d{2}:\d{2}$/)
  scheduledTime: string;
}

// complete-task.dto.ts
class CompleteTaskDto {
  @IsString()
  taskId: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

// update-video-progress.dto.ts
class UpdateVideoProgressDto {
  @IsString()
  contentId: string;

  @IsNumber()
  @Min(0)
  watchedSeconds: number;

  @IsNumber()
  @Min(0)
  totalSeconds: number;

  @IsOptional()
  @IsBoolean()
  isCompleted?: boolean;
}
```

### 4.3 Resposta do Endpoint

```json
{
  "greeting": "Boa tarde, Maria!",
  "dayPostOp": 5,
  "summary": {
    "medicationsPending": 2,
    "tasksPending": 3,
    "videosIncomplete": 1
  },
  "items": [
    {
      "id": "med-123-14:00",
      "type": "MEDICATION",
      "priority": 95,
      "status": "OVERDUE",
      "title": "Dipirona 500mg",
      "subtitle": "Atrasado - era às 14:00",
      "scheduledTime": "14:00",
      "action": {
        "type": "TAKE",
        "label": "Tomar agora"
      },
      "metadata": {
        "contentId": "123",
        "scheduledTime": "14:00"
      }
    },
    {
      "id": "task-456",
      "type": "TASK",
      "priority": 80,
      "status": "PENDING",
      "title": "Aplicar gelo no nariz",
      "subtitle": "Fazer às 16:00",
      "scheduledTime": "16:00",
      "action": {
        "type": "COMPLETE",
        "label": "Concluir"
      }
    },
    {
      "id": "video-789",
      "type": "VIDEO",
      "priority": 75,
      "status": "IN_PROGRESS",
      "title": "Como limpar o nariz",
      "subtitle": "52% assistido",
      "action": {
        "type": "WATCH",
        "label": "Continuar"
      },
      "metadata": {
        "progress": 52.7,
        "watchedSeconds": 95
      }
    }
  ],
  "nextAppointment": {
    "id": "apt-999",
    "date": "2026-01-15T10:00:00Z",
    "type": "Retorno"
  }
}
```

---

## 5. Fluxo Completo

### 5.1 Diagrama de Sequência

```
┌─────────┐          ┌─────────┐          ┌──────────┐          ┌─────────┐
│  Flutter│          │  API    │          │  Service │          │   DB    │
│   Home  │          │  /home  │          │   Home   │          │ Prisma  │
└────┬────┘          └────┬────┘          └────┬─────┘          └────┬────┘
     │                    │                    │                     │
     │ GET /patient/home  │                    │                     │
     │ ─────────────────> │                    │                     │
     │                    │                    │                     │
     │                    │ getHomeData()      │                     │
     │                    │ ─────────────────> │                     │
     │                    │                    │                     │
     │                    │                    │ getPatient()        │
     │                    │                    │ ──────────────────> │
     │                    │                    │ <────────────────── │
     │                    │                    │                     │
     │                    │                    │ getMedications()    │
     │                    │                    │ ──────────────────> │
     │                    │                    │ <────────────────── │
     │                    │                    │                     │
     │                    │                    │ getTodayLogs()      │
     │                    │                    │ ──────────────────> │
     │                    │                    │ <────────────────── │
     │                    │                    │                     │
     │                    │                    │ getVideos()         │
     │                    │                    │ ──────────────────> │
     │                    │                    │ <────────────────── │
     │                    │                    │                     │
     │                    │                    │ getVideoProgress()  │
     │                    │                    │ ──────────────────> │
     │                    │                    │ <────────────────── │
     │                    │                    │                     │
     │                    │                    │ getTasks()          │
     │                    │                    │ ──────────────────> │
     │                    │                    │ <────────────────── │
     │                    │                    │                     │
     │                    │                    │ getCompletionLogs() │
     │                    │                    │ ──────────────────> │
     │                    │                    │ <────────────────── │
     │                    │                    │                     │
     │                    │ HomeResponse       │                     │
     │                    │ <───────────────── │                     │
     │                    │                    │                     │
     │  JSON Response     │                    │                     │
     │ <───────────────── │                    │                     │
     │                    │                    │                     │
     │ Renderiza itens    │                    │                     │
     │ dinâmicos          │                    │                     │
     └────────────────────┴────────────────────┴─────────────────────┘
```

### 5.2 Fluxo de Interação

```
┌──────────────────────────────────────────────────────────────────────┐
│                        FLUXO DE INTERAÇÃO                            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. PACIENTE ABRE O APP                                              │
│     │                                                                │
│     ▼                                                                │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  GET /api/patient/home                                       │    │
│  │  Response: { items: [...], summary: {...} }                  │    │
│  └─────────────────────────────────────────────────────────────┘    │
│     │                                                                │
│     ▼                                                                │
│  2. HOME RENDERIZA APENAS ITENS PENDENTES                           │
│     • Medicação atrasada (14:00 - não tomou)                        │
│     • Tarefa próxima (16:00 - gelo no nariz)                        │
│     • Vídeo em andamento (52%)                                       │
│     │                                                                │
│     ▼                                                                │
│  3. PACIENTE TOCA EM "TOMAR" NA MEDICAÇÃO                           │
│     │                                                                │
│     ▼                                                                │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  POST /api/patient/home/medication/take                      │    │
│  │  Body: { contentId: "123", scheduledTime: "14:00" }          │    │
│  │                                                               │    │
│  │  Backend:                                                     │    │
│  │  1. Cria MedicationLog                                        │    │
│  │  2. Retorna { success: true }                                 │    │
│  └─────────────────────────────────────────────────────────────┘    │
│     │                                                                │
│     ▼                                                                │
│  4. FLUTTER ATUALIZA ESTADO LOCAL                                   │
│     • Remove card da medicação da lista                             │
│     • Atualiza summary.medicationsPending                           │
│     • Animação de confirmação                                       │
│     │                                                                │
│     ▼                                                                │
│  5. (OPCIONAL) PULL-TO-REFRESH                                      │
│     • Chama GET /api/patient/home novamente                         │
│     • Sincroniza estado completo                                     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 5.3 Fluxo de Vídeo

```
┌──────────────────────────────────────────────────────────────────────┐
│                     FLUXO DE PROGRESSO DE VÍDEO                      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. PACIENTE CLICA "CONTINUAR" NO VÍDEO                             │
│     │                                                                │
│     ▼                                                                │
│  2. ABRE TELA DE VÍDEO                                              │
│     • Inicia no watchedSeconds salvo (95s)                          │
│     • Vídeo começa de onde parou                                    │
│     │                                                                │
│     ▼                                                                │
│  3. A CADA 10 SEGUNDOS (ou ao pausar):                              │
│     │                                                                │
│     ▼                                                                │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  POST /api/patient/home/video/progress                       │    │
│  │  Body: {                                                      │    │
│  │    contentId: "789",                                          │    │
│  │    watchedSeconds: 105,                                       │    │
│  │    totalSeconds: 180,                                         │    │
│  │    isCompleted: false                                         │    │
│  │  }                                                            │    │
│  │                                                               │    │
│  │  Backend:                                                     │    │
│  │  1. Upsert VideoProgress                                      │    │
│  │  2. Calcula progressPercent = (105/180) * 100 = 58.3%        │    │
│  │  3. Se progressPercent >= 90%, marca isCompleted = true       │    │
│  └─────────────────────────────────────────────────────────────┘    │
│     │                                                                │
│     ▼                                                                │
│  4. VÍDEO TERMINA (ou >= 90%)                                       │
│     │                                                                │
│     ▼                                                                │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  POST /api/patient/home/video/progress                       │    │
│  │  Body: {                                                      │    │
│  │    contentId: "789",                                          │    │
│  │    watchedSeconds: 180,                                       │    │
│  │    totalSeconds: 180,                                         │    │
│  │    isCompleted: true                                          │    │
│  │  }                                                            │    │
│  └─────────────────────────────────────────────────────────────┘    │
│     │                                                                │
│     ▼                                                                │
│  5. PRÓXIMA VEZ QUE ABRIR HOME                                      │
│     • Vídeo NÃO aparece mais (isCompleted = true)                   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 6. Regras de Negócio

### 6.1 Priorização de Itens

```
┌────────────────────────────────────────────────────────────────┐
│                   MATRIZ DE PRIORIDADE                          │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PRIORIDADE 95-100: URGENTE                                    │
│  ├── Medicação ATRASADA (perdeu horário)                       │
│  ├── Tarefa URGENTE atrasada                                   │
│  └── Alerta de emergência                                       │
│                                                                 │
│  PRIORIDADE 80-94: ALTA                                        │
│  ├── Medicação da hora atual                                   │
│  ├── Tarefa da hora atual                                       │
│  └── Vídeo em andamento (já começou)                           │
│                                                                 │
│  PRIORIDADE 60-79: MÉDIA                                       │
│  ├── Medicação próximas 2h                                     │
│  ├── Tarefa próximas 2h                                         │
│  └── Vídeo não iniciado (mas importante)                       │
│                                                                 │
│  PRIORIDADE 40-59: BAIXA                                       │
│  ├── Vídeo informativo                                          │
│  ├── Tarefa sem horário específico                              │
│  └── Lembrete futuro                                            │
│                                                                 │
│  PRIORIDADE < 40: NÃO MOSTRAR                                  │
│  ├── Itens concluídos                                           │
│  ├── Itens futuros (> 2h)                                       │
│  └── Itens de outros dias                                       │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### 6.2 Regras de Exibição

| Tipo | Condição | Aparece na Home? |
|------|----------|------------------|
| Medicação | Horário passou, não tomou | SIM (OVERDUE) |
| Medicação | Horário = agora | SIM (PENDING) |
| Medicação | Próximas 2h | SIM (UPCOMING) |
| Medicação | > 2h no futuro | NÃO |
| Medicação | Já tomou hoje | NÃO |
| Medicação | Dia pós-op fora do range | NÃO |
| Vídeo | Nunca assistiu, relevante hoje | SIM |
| Vídeo | Começou mas não terminou | SIM (IN_PROGRESS) |
| Vídeo | Completou (>= 90%) | NÃO |
| Vídeo | Dia pós-op fora do range | NÃO |
| Tarefa | Hoje, não concluída | SIM |
| Tarefa | Recorrente, válida hoje | SIM |
| Tarefa | Já concluída hoje | NÃO |
| Tarefa | Dia futuro | NÃO |

### 6.3 Limite de Itens

```typescript
const HOME_CONFIG = {
  maxItems: 8,           // Máximo de itens na Home
  maxMedications: 4,     // Máximo de medicações
  maxTasks: 3,           // Máximo de tarefas
  maxVideos: 2,          // Máximo de vídeos
  upcomingWindowHours: 2 // Janela de "próximo"
};
```

---

## 7. Cache e Performance

### 7.1 Estratégia de Cache

```typescript
// Cache no Redis (opcional)
const CACHE_CONFIG = {
  homeData: {
    ttl: 60, // 1 minuto
    key: (patientId) => `home:${patientId}`,
  },
  invalidateOn: [
    'medication.taken',
    'task.completed',
    'video.progress',
  ],
};
```

### 7.2 Otimização de Queries

```typescript
// Query otimizada com includes
const patientWithData = await prisma.patient.findUnique({
  where: { id: patientId },
  include: {
    user: { select: { name: true } },
    clinic: { select: { id: true, name: true } },
    medicationLogs: {
      where: { takenAt: { gte: startOfDay(new Date()) } },
    },
    videoProgress: {
      where: { isCompleted: false },
    },
    tasks: {
      where: { status: { not: 'COMPLETED' } },
    },
  },
});
```

---

## 8. Considerações de Multi-Tenancy

### 8.1 Isolamento por Clínica

```typescript
// TODAS as queries incluem clinicId
const medications = await prisma.clinicContent.findMany({
  where: {
    clinicId: patient.clinicId, // OBRIGATÓRIO
    type: 'MEDICATIONS',
    isActive: true,
  },
});

// Tarefas também isoladas
const tasks = await prisma.patientTask.findMany({
  where: {
    patientId: patient.id,
    clinicId: patient.clinicId, // REDUNDÂNCIA proposital para segurança
  },
});
```

### 8.2 Configuração por Clínica

```prisma
// Cada clínica pode ter configurações diferentes
model ClinicConfig {
  id            String  @id @default(uuid())
  clinicId      String  @unique

  // Configurações da Home
  homeMaxItems       Int @default(8)
  homeMaxMedications Int @default(4)
  homeMaxTasks       Int @default(3)
  homeMaxVideos      Int @default(2)

  // Janelas de tempo
  upcomingWindowHours Int @default(2)
  overdueGracePeriod  Int @default(30) // minutos

  clinic        Clinic  @relation(fields: [clinicId], references: [id])
}
```

---

## 9. Próximos Passos de Implementação

### Fase 1: Backend (Prioridade Alta)
1. [ ] Adicionar modelo `VideoProgress` ao Prisma
2. [ ] Adicionar modelo `PatientTask` ao Prisma
3. [ ] Criar módulo `home` no NestJS
4. [ ] Implementar `HomeService` com lógica de agregação
5. [ ] Criar endpoints `/api/patient/home/*`

### Fase 2: Frontend (Após Backend)
1. [ ] Criar provider `HomeProvider` no Flutter
2. [ ] Refatorar Home para usar dados da API
3. [ ] Implementar cards dinâmicos por tipo
4. [ ] Adicionar pull-to-refresh
5. [ ] Implementar ações (tomar, completar, etc)

### Fase 3: Refinamentos
1. [ ] Adicionar cache Redis
2. [ ] Implementar WebSocket para updates real-time
3. [ ] Adicionar notificações push
4. [ ] Analytics de uso

---

## 10. Conclusão

Esta arquitetura transforma a Home em um **dashboard inteligente e contextual** que:

- **Mostra apenas o relevante**: Itens pendentes, em andamento ou atrasados
- **Remove automaticamente**: Itens concluídos desaparecem
- **Prioriza corretamente**: Urgente primeiro, depois pendente, depois próximo
- **Respeita o contexto**: Dia pós-operatório, horário atual, histórico
- **É escalável**: Multi-tenancy, cache, performance

O paciente terá a sensação de um app **vivo**, **inteligente** e **personalizado** para sua jornada de recuperação.
