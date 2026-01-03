import { PrismaClient, ContentType, ContentCategory, AppointmentType, AppointmentStatus, TrainingWeekStatus, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

interface TemplateData {
  type: ContentType;
  category: ContentCategory;
  title: string;
  description?: string;
  sortOrder: number;
  validFromDay?: number;
  validUntilDay?: number;
}

async function main() {
  console.log('🌱 Criando templates padrão do sistema...\n');

  // ==================== SINTOMAS ====================
  const sintomas: TemplateData[] = [
    // NORMAIS (verde)
    { type: ContentType.SYMPTOMS, category: ContentCategory.NORMAL, title: 'Inchaço moderado', description: 'Normal até 14 dias após o procedimento', sortOrder: 1 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.NORMAL, title: 'Sensibilidade local', description: 'Pode durar até 30 dias', sortOrder: 2 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.NORMAL, title: 'Pequenos hematomas', description: 'Desaparecem gradualmente em 2-3 semanas', sortOrder: 3 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.NORMAL, title: 'Desconforto ao movimentar', description: 'Normal nos primeiros dias', sortOrder: 4 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.NORMAL, title: 'Coceira leve na cicatriz', description: 'Sinal de cicatrização adequada', sortOrder: 5 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.NORMAL, title: 'Dormência temporária', description: 'A sensibilidade retorna gradualmente', sortOrder: 6 },

    // AVISOS (amarelo)
    { type: ContentType.SYMPTOMS, category: ContentCategory.WARNING, title: 'Febre acima de 38°C', description: 'Entre em contato com a clínica', sortOrder: 10 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.WARNING, title: 'Vermelhidão intensa', description: 'Pode indicar inflamação - avise a clínica', sortOrder: 11 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.WARNING, title: 'Secreção com odor', description: 'Entre em contato imediatamente', sortOrder: 12 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.WARNING, title: 'Dor que não melhora com medicação', description: 'Avise a equipe médica', sortOrder: 13 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.WARNING, title: 'Inchaço que aumenta após 7 dias', description: 'Precisa de avaliação', sortOrder: 14 },

    // EMERGÊNCIA (vermelho)
    { type: ContentType.SYMPTOMS, category: ContentCategory.EMERGENCY, title: 'Sangramento intenso', description: 'Procure atendimento imediato', sortOrder: 20 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.EMERGENCY, title: 'Dificuldade para respirar', description: 'Ligue 192 (SAMU) imediatamente', sortOrder: 21 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.EMERGENCY, title: 'Dor intensa no peito', description: 'Procure emergência imediatamente', sortOrder: 22 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.EMERGENCY, title: 'Inchaço súbito nas pernas', description: 'Pode indicar trombose - emergência', sortOrder: 23 },
    { type: ContentType.SYMPTOMS, category: ContentCategory.EMERGENCY, title: 'Desmaio ou confusão mental', description: 'Procure emergência imediatamente', sortOrder: 24 },
  ];

  // ==================== DIETA ====================
  const dieta: TemplateData[] = [
    // PERMITIDOS (verde)
    { type: ContentType.DIET, category: ContentCategory.ALLOWED, title: 'Proteínas magras', description: 'Frango, peixe, ovos - essenciais para cicatrização', sortOrder: 1 },
    { type: ContentType.DIET, category: ContentCategory.ALLOWED, title: 'Frutas e verduras', description: 'Ricas em vitaminas e antioxidantes', sortOrder: 2 },
    { type: ContentType.DIET, category: ContentCategory.ALLOWED, title: 'Água (2L/dia)', description: 'Manter hidratação adequada', sortOrder: 3 },
    { type: ContentType.DIET, category: ContentCategory.ALLOWED, title: 'Alimentos ricos em zinco', description: 'Castanhas, sementes - ajudam na cicatrização', sortOrder: 4 },
    { type: ContentType.DIET, category: ContentCategory.ALLOWED, title: 'Chás naturais', description: 'Camomila, erva-doce (sem açúcar)', sortOrder: 5 },
    { type: ContentType.DIET, category: ContentCategory.ALLOWED, title: 'Fibras', description: 'Aveia, legumes - evitam constipação', sortOrder: 6 },

    // EVITAR (amarelo)
    { type: ContentType.DIET, category: ContentCategory.RESTRICTED, title: 'Alimentos muito salgados', description: 'Aumentam o inchaço', sortOrder: 10 },
    { type: ContentType.DIET, category: ContentCategory.RESTRICTED, title: 'Açúcar em excesso', description: 'Prejudica a cicatrização', sortOrder: 11 },
    { type: ContentType.DIET, category: ContentCategory.RESTRICTED, title: 'Cafeína em excesso', description: 'Máximo 1 xícara de café por dia', sortOrder: 12 },
    { type: ContentType.DIET, category: ContentCategory.RESTRICTED, title: 'Alimentos industrializados', description: 'Contêm muito sódio e conservantes', sortOrder: 13 },
    { type: ContentType.DIET, category: ContentCategory.RESTRICTED, title: 'Refrigerantes', description: 'Causam inchaço e desidratação', sortOrder: 14 },

    // PROIBIDOS (vermelho)
    { type: ContentType.DIET, category: ContentCategory.PROHIBITED, title: 'Bebidas alcoólicas', description: 'Proibido por pelo menos 30 dias', sortOrder: 20 },
    { type: ContentType.DIET, category: ContentCategory.PROHIBITED, title: 'Cigarro e derivados', description: 'Compromete severamente a cicatrização', sortOrder: 21 },
    { type: ContentType.DIET, category: ContentCategory.PROHIBITED, title: 'Alimentos crus (sushi, carpaccio)', description: 'Risco de infecção - evitar por 15 dias', sortOrder: 22 },
    { type: ContentType.DIET, category: ContentCategory.PROHIBITED, title: 'Suplementos sem orientação', description: 'Podem interferir na recuperação', sortOrder: 23 },
  ];

  // ==================== ATIVIDADES ====================
  const atividades: TemplateData[] = [
    // PERMITIDAS (verde)
    { type: ContentType.ACTIVITIES, category: ContentCategory.ALLOWED, title: 'Caminhada leve', description: 'A partir do 3º dia, 10-15 minutos', sortOrder: 1, validFromDay: 3 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.ALLOWED, title: 'Banho morno', description: 'Evitar água muito quente na área operada', sortOrder: 2, validFromDay: 1 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.ALLOWED, title: 'Trabalho remoto/leve', description: 'Sem esforço físico - a partir do 7º dia', sortOrder: 3, validFromDay: 7 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.ALLOWED, title: 'Atividades domésticas leves', description: 'Sem carregar peso - a partir do 14º dia', sortOrder: 4, validFromDay: 14 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.ALLOWED, title: 'Retorno ao trabalho presencial', description: 'Trabalho sem esforço - a partir do 14º dia', sortOrder: 5, validFromDay: 14 },

    // RESTRITAS (amarelo)
    { type: ContentType.ACTIVITIES, category: ContentCategory.RESTRICTED, title: 'Dirigir', description: 'Somente após 7-14 dias e sem dor', sortOrder: 10, validFromDay: 7 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.RESTRICTED, title: 'Subir escadas', description: 'Com cuidado e sem pressa', sortOrder: 11, validFromDay: 3 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.RESTRICTED, title: 'Relações sexuais', description: 'Após liberação médica (geralmente 21 dias)', sortOrder: 12, validFromDay: 21 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.RESTRICTED, title: 'Viagens longas', description: 'Evitar nas primeiras 2 semanas', sortOrder: 13, validFromDay: 14 },

    // PROIBIDAS (vermelho)
    { type: ContentType.ACTIVITIES, category: ContentCategory.PROHIBITED, title: 'Academia e musculação', description: 'Proibido por 30-60 dias', sortOrder: 20, validUntilDay: 60 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.PROHIBITED, title: 'Pegar peso acima de 3kg', description: 'Proibido nos primeiros 30 dias', sortOrder: 21, validUntilDay: 30 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.PROHIBITED, title: 'Exposição ao sol na cicatriz', description: 'Evitar por 6 meses', sortOrder: 22, validUntilDay: 180 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.PROHIBITED, title: 'Natação/imersão em água', description: 'Até cicatrização completa (~30 dias)', sortOrder: 23, validUntilDay: 30 },
    { type: ContentType.ACTIVITIES, category: ContentCategory.PROHIBITED, title: 'Exercícios abdominais', description: 'Proibido por 60-90 dias', sortOrder: 24, validUntilDay: 90 },
  ];

  // ==================== CUIDADOS ====================
  const cuidados: TemplateData[] = [
    { type: ContentType.CARE, category: ContentCategory.INFO, title: 'Usar cinta compressiva', description: '24 horas por dia nos primeiros 30 dias', sortOrder: 1 },
    { type: ContentType.CARE, category: ContentCategory.INFO, title: 'Dormir de barriga para cima', description: 'Posição recomendada nos primeiros 15 dias', sortOrder: 2 },
    { type: ContentType.CARE, category: ContentCategory.INFO, title: 'Limpar a cicatriz', description: 'Com soro fisiológico e gaze estéril', sortOrder: 3 },
    { type: ContentType.CARE, category: ContentCategory.INFO, title: 'Aplicar pomada cicatrizante', description: 'Conforme orientação médica', sortOrder: 4 },
    { type: ContentType.CARE, category: ContentCategory.INFO, title: 'Fazer drenagem linfática', description: 'Iniciar após 7-10 dias (com profissional)', sortOrder: 5, validFromDay: 7 },
    { type: ContentType.CARE, category: ContentCategory.INFO, title: 'Tomar medicações no horário', description: 'Seguir prescrição médica rigorosamente', sortOrder: 6 },
    { type: ContentType.CARE, category: ContentCategory.INFO, title: 'Manter curativos limpos e secos', description: 'Trocar conforme orientação', sortOrder: 7 },
    { type: ContentType.CARE, category: ContentCategory.INFO, title: 'Comparecer aos retornos', description: 'Não faltar às consultas de acompanhamento', sortOrder: 8 },
    { type: ContentType.CARE, category: ContentCategory.INFO, title: 'Usar protetor solar na cicatriz', description: 'FPS 50+ após liberação médica', sortOrder: 9, validFromDay: 30 },
    { type: ContentType.CARE, category: ContentCategory.INFO, title: 'Massagear a cicatriz', description: 'Após 30 dias, conforme orientação', sortOrder: 10, validFromDay: 30 },
  ];

  // ==================== TREINO ====================
  const treino: TemplateData[] = [
    { type: ContentType.TRAINING, category: ContentCategory.INFO, title: 'Semana 1-2: Repouso', description: 'Apenas caminhadas leves de 5-10 min', sortOrder: 1, validFromDay: 1, validUntilDay: 14 },
    { type: ContentType.TRAINING, category: ContentCategory.INFO, title: 'Semana 3-4: Caminhadas', description: 'Aumentar para 15-20 min diários', sortOrder: 2, validFromDay: 15, validUntilDay: 30 },
    { type: ContentType.TRAINING, category: ContentCategory.INFO, title: 'Semana 5-6: Atividades leves', description: 'Alongamentos suaves, yoga leve', sortOrder: 3, validFromDay: 31, validUntilDay: 45 },
    { type: ContentType.TRAINING, category: ContentCategory.INFO, title: 'Semana 7-8: Exercícios moderados', description: 'Bicicleta ergométrica, natação (com liberação)', sortOrder: 4, validFromDay: 46, validUntilDay: 60 },
    { type: ContentType.TRAINING, category: ContentCategory.INFO, title: 'Após 60 dias: Retorno gradual', description: 'Academia com cargas leves, aumentando gradualmente', sortOrder: 5, validFromDay: 61 },
  ];

  // ==================== MEDICAÇÕES ====================
  const medicacoes: TemplateData[] = [
    { type: ContentType.MEDICATIONS, category: ContentCategory.INFO, title: 'Antibiótico', description: 'Tomar 1 comprimido de 8 em 8 horas por 7 dias', sortOrder: 1, validFromDay: 1, validUntilDay: 7 },
    { type: ContentType.MEDICATIONS, category: ContentCategory.INFO, title: 'Anti-inflamatório', description: 'Tomar 1 comprimido de 12 em 12 horas por 5 dias', sortOrder: 2, validFromDay: 1, validUntilDay: 5 },
    { type: ContentType.MEDICATIONS, category: ContentCategory.INFO, title: 'Analgésico', description: 'Tomar 1 comprimido de 6 em 6 horas se dor', sortOrder: 3, validFromDay: 1, validUntilDay: 14 },
    { type: ContentType.MEDICATIONS, category: ContentCategory.INFO, title: 'Protetor gástrico', description: 'Tomar 1 comprimido em jejum pela manhã', sortOrder: 4, validFromDay: 1, validUntilDay: 7 },
    { type: ContentType.MEDICATIONS, category: ContentCategory.INFO, title: 'Pomada cicatrizante', description: 'Aplicar na cicatriz 2x ao dia após higienização', sortOrder: 5, validFromDay: 7, validUntilDay: 60 },
    { type: ContentType.MEDICATIONS, category: ContentCategory.WARNING, title: 'Anticoagulante', description: 'Atenção: não usar sem orientação médica', sortOrder: 10 },
    { type: ContentType.MEDICATIONS, category: ContentCategory.WARNING, title: 'Anti-inflamatórios não prescritos', description: 'Não tomar sem consultar o médico', sortOrder: 11 },
    { type: ContentType.MEDICATIONS, category: ContentCategory.PROHIBITED, title: 'Aspirina', description: 'Proibido por 15 dias - aumenta risco de sangramento', sortOrder: 20, validUntilDay: 15 },
  ];

  // ==================== INSERIR TODOS ====================
  const allTemplates = [...sintomas, ...dieta, ...atividades, ...cuidados, ...treino, ...medicacoes];

  let created = 0;
  let updated = 0;

  for (const template of allTemplates) {
    // Gerar ID baseado no tipo e título
    const id = `tpl-${template.type.toLowerCase()}-${template.title
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]/g, '-')
      .substring(0, 40)}`;

    const existing = await prisma.systemContentTemplate.findUnique({ where: { id } });

    if (existing) {
      await prisma.systemContentTemplate.update({
        where: { id },
        data: { ...template, isActive: true },
      });
      updated++;
    } else {
      await prisma.systemContentTemplate.create({
        data: { id, ...template, isActive: true },
      });
      created++;
    }
  }

  console.log(`✅ Templates: ${created} criados, ${updated} atualizados`);
  console.log(`   Total: ${allTemplates.length} templates\n`);

  // Resumo por tipo
  const byType = allTemplates.reduce((acc, t) => {
    acc[t.type] = (acc[t.type] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  console.log('📋 Resumo por tipo:');
  Object.entries(byType).forEach(([type, count]) => {
    console.log(`   ${type}: ${count} templates`);
  });
}

async function createDefaultClinic() {
  console.log('\n🏥 Criando clínica padrão...\n');

  const clinicId = 'clinic-default-scheibell';

  const existingClinic = await prisma.clinic.findUnique({
    where: { id: clinicId },
  });

  if (existingClinic) {
    console.log('   Clínica já existe, pulando criação...');
    return clinicId;
  }

  await prisma.clinic.create({
    data: {
      id: clinicId,
      name: 'Clínica Scheibell',
      email: 'contato@clinicascheibell.com.br',
      phone: '(11) 99999-9999',
      address: 'Rua Exemplo, 123 - São Paulo, SP',
      primaryColor: '#4F4A34',
      secondaryColor: '#A49E86',
      isActive: true,
    },
  });

  console.log('✅ Clínica padrão criada: Clínica Scheibell');
  return clinicId;
}

async function syncTemplatesForClinic(clinicId: string) {
  console.log('\n📋 Sincronizando templates para a clínica...\n');

  // Verificar quais templates já foram sincronizados
  const existingTemplateIds = await prisma.clinicContent.findMany({
    where: { clinicId, templateId: { not: null } },
    select: { templateId: true },
  });

  const existingIds = new Set(existingTemplateIds.map((c) => c.templateId));

  // Buscar templates que ainda não foram sincronizados
  const newTemplates = await prisma.systemContentTemplate.findMany({
    where: {
      isActive: true,
      id: { notIn: Array.from(existingIds) as string[] },
    },
  });

  if (newTemplates.length === 0) {
    console.log('   Todos os templates já estão sincronizados');
    return;
  }

  // Criar conteúdos da clínica baseados nos templates
  await prisma.clinicContent.createMany({
    data: newTemplates.map((t) => ({
      clinicId,
      templateId: t.id,
      type: t.type,
      category: t.category,
      title: t.title,
      description: t.description,
      validFromDay: t.validFromDay,
      validUntilDay: t.validUntilDay,
      sortOrder: t.sortOrder,
      isCustom: false,
    })),
  });

  console.log(`✅ ${newTemplates.length} conteúdos sincronizados para a clínica`);
}

async function createSampleAppointments() {
  console.log('\n📅 Criando consultas de exemplo...\n');

  // Buscar todos os pacientes
  const patients = await prisma.patient.findMany({
    select: { id: true, surgeryDate: true },
  });

  if (patients.length === 0) {
    console.log('   Nenhum paciente encontrado, pulando criação de consultas...');
    return;
  }

  for (const patient of patients) {
    // Verificar se já tem consultas
    const existingAppointments = await prisma.appointment.count({
      where: { patientId: patient.id },
    });

    if (existingAppointments > 0) {
      console.log(`   Paciente ${patient.id} já tem consultas, pulando...`);
      continue;
    }

    const surgeryDate = patient.surgeryDate || new Date();
    const now = new Date();

    // Criar consultas de exemplo
    const appointments = [
      {
        patientId: patient.id,
        title: 'Retorno Pós-Operatório',
        description: 'Avaliação de cicatrização e retirada de pontos',
        date: new Date(surgeryDate.getTime() + 7 * 24 * 60 * 60 * 1000), // 7 dias após cirurgia
        time: '09:00',
        type: AppointmentType.RETURN_VISIT,
        status: now > new Date(surgeryDate.getTime() + 7 * 24 * 60 * 60 * 1000)
          ? AppointmentStatus.COMPLETED
          : AppointmentStatus.CONFIRMED,
        location: 'Consultório 1',
      },
      {
        patientId: patient.id,
        title: 'Avaliação 1 Mês',
        description: 'Avaliação de evolução e ajuste de medicação',
        date: new Date(surgeryDate.getTime() + 30 * 24 * 60 * 60 * 1000), // 30 dias após cirurgia
        time: '10:30',
        type: AppointmentType.EVALUATION,
        status: AppointmentStatus.PENDING,
        location: 'Consultório 2',
      },
      {
        patientId: patient.id,
        title: 'Fisioterapia',
        description: 'Sessão de drenagem linfática',
        date: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000), // 3 dias a partir de hoje
        time: '14:00',
        type: AppointmentType.PHYSIOTHERAPY,
        status: AppointmentStatus.CONFIRMED,
        location: 'Sala de Fisioterapia',
      },
      {
        patientId: patient.id,
        title: 'Avaliação 3 Meses',
        description: 'Avaliação final de resultado',
        date: new Date(surgeryDate.getTime() + 90 * 24 * 60 * 60 * 1000), // 90 dias após cirurgia
        time: '11:00',
        type: AppointmentType.EVALUATION,
        status: AppointmentStatus.PENDING,
        location: 'Consultório 1',
      },
    ];

    await prisma.appointment.createMany({
      data: appointments,
    });

    console.log(`   ✅ ${appointments.length} consultas criadas para paciente ${patient.id}`);
  }
}

async function createDefaultTrainingProtocol(clinicId: string) {
  console.log('\n🏋️ Criando protocolo de treino padrão...\n');

  const protocolId = 'protocol-default-rinoplastia';

  // Verificar se já existe
  const existing = await prisma.trainingProtocol.findUnique({
    where: { id: protocolId },
  });

  if (existing) {
    console.log('   Protocolo já existe, pulando criação...');
    return protocolId;
  }

  // Criar protocolo padrão de 8 semanas para rinoplastia
  await prisma.trainingProtocol.create({
    data: {
      id: protocolId,
      clinicId,
      name: 'Protocolo Rinoplastia Padrão',
      surgeryType: 'RINOPLASTIA',
      description: 'Protocolo de recuperação física para pacientes de rinoplastia',
      totalWeeks: 8,
      isDefault: true,
      isActive: true,
    },
  });

  console.log('✅ Protocolo de treino criado');

  // Definição das 8 semanas do protocolo
  const weeks = [
    {
      weekNumber: 1,
      title: 'Semana 1',
      dayRange: 'Dias 1-7',
      objective: 'Repouso absoluto. Foco na recuperação inicial.',
      maxHeartRate: null,
      heartRateLabel: 'Repouso',
      canDo: ['Repouso em casa', 'Caminhadas curtas dentro de casa', 'Exercícios respiratórios leves'],
      avoid: ['Qualquer esforço físico', 'Abaixar a cabeça', 'Assoar o nariz', 'Exposição ao sol'],
      sessions: [
        { sessionNumber: 1, name: 'Respiração diafragmática', description: '5 minutos de respiração profunda', duration: 5, intensity: 'Muito leve' },
        { sessionNumber: 2, name: 'Caminhada indoor', description: 'Andar pela casa por 5 minutos', duration: 5, intensity: 'Muito leve' },
        { sessionNumber: 3, name: 'Alongamento sentado', description: 'Movimentos suaves de pescoço e ombros', duration: 5, intensity: 'Muito leve' },
      ],
    },
    {
      weekNumber: 2,
      title: 'Semana 2',
      dayRange: 'Dias 8-14',
      objective: 'Início de movimentação leve. Caminhadas curtas.',
      maxHeartRate: 90,
      heartRateLabel: 'FC Basal + 25 bpm',
      canDo: ['Caminhadas leves de 10-15 min', 'Exercícios de mobilidade articular', 'Trabalho remoto leve'],
      avoid: ['Exercícios intensos', 'Pegar peso', 'Sol direto', 'Ambientes com muita poeira'],
      sessions: [
        { sessionNumber: 1, name: 'Caminhada leve', description: 'Caminhada de 10 minutos em ritmo lento', duration: 10, intensity: 'Leve' },
        { sessionNumber: 2, name: 'Mobilidade articular', description: 'Movimentos circulares de articulações', duration: 10, intensity: 'Leve' },
        { sessionNumber: 3, name: 'Caminhada + respiração', description: 'Caminhada com foco na respiração', duration: 10, intensity: 'Leve' },
      ],
    },
    {
      weekNumber: 3,
      title: 'Semana 3',
      dayRange: 'Dias 15-21',
      objective: 'Aumento gradual da atividade. Caminhadas mais longas.',
      maxHeartRate: 100,
      heartRateLabel: 'FC Basal + 35 bpm',
      canDo: ['Caminhadas de 20-30 min', 'Alongamentos suaves', 'Subir escadas devagar'],
      avoid: ['Corrida', 'Musculação', 'Esportes de contato', 'Nadar'],
      sessions: [
        { sessionNumber: 1, name: 'Caminhada moderada', description: 'Caminhada de 20 minutos', duration: 20, intensity: 'Leve' },
        { sessionNumber: 2, name: 'Alongamento completo', description: 'Série de alongamentos para todo corpo', duration: 15, intensity: 'Leve' },
        { sessionNumber: 3, name: 'Caminhada ao ar livre', description: 'Caminhada de 25 minutos em local aberto', duration: 25, intensity: 'Leve-Moderada' },
      ],
    },
    {
      weekNumber: 4,
      title: 'Semana 4',
      dayRange: 'Dias 22-28',
      objective: 'Consolidação da fase de caminhadas. Preparação para próxima fase.',
      maxHeartRate: 110,
      heartRateLabel: 'FC Basal + 45 bpm',
      canDo: ['Caminhadas de 30-40 min', 'Yoga restaurativa', 'Bicicleta ergométrica leve'],
      avoid: ['Corrida', 'Peso', 'Exercícios abdominais', 'Sol direto no nariz'],
      sessions: [
        { sessionNumber: 1, name: 'Caminhada longa', description: 'Caminhada de 30 minutos', duration: 30, intensity: 'Moderada' },
        { sessionNumber: 2, name: 'Yoga restaurativa', description: 'Posturas suaves de yoga', duration: 20, intensity: 'Leve' },
        { sessionNumber: 3, name: 'Bicicleta ergométrica', description: 'Pedalar leve por 15 minutos', duration: 15, intensity: 'Leve-Moderada' },
      ],
    },
    {
      weekNumber: 5,
      title: 'Semana 5',
      dayRange: 'Dias 29-35',
      objective: 'Início de exercícios mais estruturados. Cardio leve.',
      maxHeartRate: 120,
      heartRateLabel: 'FC Basal + 55 bpm',
      canDo: ['Caminhada rápida', 'Bicicleta', 'Elíptico', 'Exercícios de força leve (sem peso)'],
      avoid: ['Corrida intensa', 'Musculação pesada', 'Esportes de impacto'],
      sessions: [
        { sessionNumber: 1, name: 'Cardio leve', description: 'Elíptico ou bicicleta 20 min', duration: 20, intensity: 'Moderada' },
        { sessionNumber: 2, name: 'Força leve', description: 'Exercícios com peso corporal', duration: 20, intensity: 'Moderada' },
        { sessionNumber: 3, name: 'Caminhada intensa', description: 'Caminhada em ritmo acelerado', duration: 30, intensity: 'Moderada' },
      ],
    },
    {
      weekNumber: 6,
      title: 'Semana 6',
      dayRange: 'Dias 36-42',
      objective: 'Aumento da intensidade. Introdução de exercícios de força.',
      maxHeartRate: 130,
      heartRateLabel: 'FC Basal + 65 bpm',
      canDo: ['Musculação leve', 'Natação (com liberação)', 'Corrida leve/trote'],
      avoid: ['Exercícios de alta intensidade', 'Mergulho', 'Esportes de contato'],
      sessions: [
        { sessionNumber: 1, name: 'Musculação leve', description: 'Série de exercícios com peso leve', duration: 30, intensity: 'Moderada' },
        { sessionNumber: 2, name: 'Trote/Corrida leve', description: 'Alternância entre caminhada e trote', duration: 25, intensity: 'Moderada-Alta' },
        { sessionNumber: 3, name: 'Natação', description: 'Nado livre em ritmo leve', duration: 30, intensity: 'Moderada' },
      ],
    },
    {
      weekNumber: 7,
      title: 'Semana 7',
      dayRange: 'Dias 43-49',
      objective: 'Retorno gradual às atividades normais. Aumento de carga.',
      maxHeartRate: 140,
      heartRateLabel: 'FC Basal + 75 bpm',
      canDo: ['Musculação moderada', 'Corrida', 'Maioria dos esportes'],
      avoid: ['Esportes de contato no rosto', 'HIIT muito intenso'],
      sessions: [
        { sessionNumber: 1, name: 'Treino de força', description: 'Musculação com carga moderada', duration: 40, intensity: 'Moderada-Alta' },
        { sessionNumber: 2, name: 'Corrida', description: 'Corrida contínua 20-25 minutos', duration: 25, intensity: 'Alta' },
        { sessionNumber: 3, name: 'Treino funcional', description: 'Circuito funcional moderado', duration: 35, intensity: 'Moderada-Alta' },
      ],
    },
    {
      weekNumber: 8,
      title: 'Semana 8',
      dayRange: 'Dias 50-56',
      objective: 'Retorno completo. Atividades físicas liberadas (exceto contato facial).',
      maxHeartRate: null,
      heartRateLabel: 'Normal',
      canDo: ['Todos os exercícios', 'Esportes', 'Academia sem restrição'],
      avoid: ['Impactos diretos no nariz', 'Esportes com risco de trauma facial'],
      sessions: [
        { sessionNumber: 1, name: 'Treino completo A', description: 'Treino de força superior', duration: 45, intensity: 'Alta' },
        { sessionNumber: 2, name: 'Treino completo B', description: 'Treino de força inferior', duration: 45, intensity: 'Alta' },
        { sessionNumber: 3, name: 'Cardio intenso', description: 'HIIT ou corrida longa', duration: 40, intensity: 'Alta' },
      ],
    },
  ];

  // Criar semanas e sessões
  for (const week of weeks) {
    const weekId = `week-${protocolId}-${week.weekNumber}`;

    await prisma.trainingWeek.create({
      data: {
        id: weekId,
        protocolId,
        weekNumber: week.weekNumber,
        title: week.title,
        dayRange: week.dayRange,
        objective: week.objective,
        maxHeartRate: week.maxHeartRate,
        heartRateLabel: week.heartRateLabel,
        canDo: week.canDo,
        avoid: week.avoid,
        sortOrder: week.weekNumber,
      },
    });

    // Criar sessões da semana
    for (const session of week.sessions) {
      await prisma.trainingSession.create({
        data: {
          id: `session-${weekId}-${session.sessionNumber}`,
          weekId,
          sessionNumber: session.sessionNumber,
          name: session.name,
          description: session.description,
          duration: session.duration,
          intensity: session.intensity,
          sortOrder: session.sessionNumber,
        },
      });
    }
  }

  console.log(`✅ ${weeks.length} semanas com sessões criadas`);
  return protocolId;
}

async function initializePatientTrainingProgress() {
  console.log('\n📊 Inicializando progresso de treino dos pacientes...\n');

  // Buscar pacientes com data de cirurgia definida
  const patients = await prisma.patient.findMany({
    where: { surgeryDate: { not: null } },
    select: { id: true, surgeryDate: true },
  });

  if (patients.length === 0) {
    console.log('   Nenhum paciente com data de cirurgia encontrado');
    return;
  }

  // Buscar protocolo padrão
  const protocol = await prisma.trainingProtocol.findFirst({
    where: { isDefault: true },
    include: { weeks: { orderBy: { weekNumber: 'asc' } } },
  });

  if (!protocol) {
    console.log('   Protocolo padrão não encontrado');
    return;
  }

  for (const patient of patients) {
    // Verificar se já tem progresso
    const existingProgress = await prisma.patientTrainingProgress.count({
      where: { patientId: patient.id },
    });

    if (existingProgress > 0) {
      console.log(`   Paciente ${patient.id} já tem progresso, pulando...`);
      continue;
    }

    const surgeryDate = patient.surgeryDate!;
    const now = new Date();
    const daysSinceSurgery = Math.floor((now.getTime() - surgeryDate.getTime()) / (1000 * 60 * 60 * 24));
    const currentWeekNumber = Math.min(Math.floor(daysSinceSurgery / 7) + 1, protocol.totalWeeks);

    // Criar progresso para cada semana
    for (const week of protocol.weeks) {
      let status: TrainingWeekStatus;

      if (week.weekNumber < currentWeekNumber) {
        status = TrainingWeekStatus.COMPLETED;
      } else if (week.weekNumber === currentWeekNumber) {
        status = TrainingWeekStatus.CURRENT;
      } else {
        status = TrainingWeekStatus.FUTURE;
      }

      await prisma.patientTrainingProgress.create({
        data: {
          patientId: patient.id,
          weekId: week.id,
          status,
          startedAt: week.weekNumber <= currentWeekNumber ? surgeryDate : null,
          completedAt: week.weekNumber < currentWeekNumber ? new Date() : null,
        },
      });
    }

    console.log(`   ✅ Progresso criado para paciente ${patient.id} (semana ${currentWeekNumber})`);
  }
}

async function createTestUsers(clinicId: string) {
  console.log('\n👥 Criando usuários de teste...\n');

  const defaultPassword = await bcrypt.hash('123456', 10);

  // Definição dos usuários de teste
  const testUsers = [
    {
      id: 'user-paciente-d0',
      email: 'paciente@teste.com',
      name: 'Paciente Novo (D+0)',
      role: UserRole.PATIENT,
      surgeryDaysAgo: 0, // Cirurgia hoje
    },
    {
      id: 'user-paciente-d7',
      email: 'paciente.semana2@teste.com',
      name: 'Paciente Semana 2 (D+7)',
      role: UserRole.PATIENT,
      surgeryDaysAgo: 7, // Cirurgia há 7 dias
    },
    {
      id: 'user-paciente-d14',
      email: 'paciente.semana3@teste.com',
      name: 'Paciente Semana 3 (D+14)',
      role: UserRole.PATIENT,
      surgeryDaysAgo: 14, // Cirurgia há 14 dias
    },
    {
      id: 'user-admin',
      email: 'admin@teste.com',
      name: 'Administrador',
      role: UserRole.CLINIC_ADMIN,
      surgeryDaysAgo: null, // Não é paciente
    },
  ];

  for (const userData of testUsers) {
    // Verificar se usuário já existe
    const existingUser = await prisma.user.findUnique({
      where: { email: userData.email },
    });

    if (existingUser) {
      console.log(`   ⏭️  Usuário ${userData.email} já existe, pulando...`);
      continue;
    }

    // Criar usuário
    const user = await prisma.user.create({
      data: {
        id: userData.id,
        email: userData.email,
        name: userData.name,
        passwordHash: defaultPassword,
        role: userData.role,
        clinicId: clinicId,
      },
    });

    // Se for paciente, criar registro de Patient
    if (userData.role === UserRole.PATIENT && userData.surgeryDaysAgo !== null) {
      const surgeryDate = new Date();
      surgeryDate.setDate(surgeryDate.getDate() - userData.surgeryDaysAgo);

      await prisma.patient.create({
        data: {
          id: `patient-${userData.id}`,
          userId: user.id,
          clinicId: clinicId,
          surgeryDate: surgeryDate,
          surgeryType: 'RINOPLASTIA',
        },
      });
    }

    console.log(`   ✅ Usuário criado: ${userData.email} (${userData.role})`);
  }

  console.log('\n📋 Resumo dos logins de teste:');
  console.log('   ┌─────────────────────────────────┬──────────┬───────────────────┐');
  console.log('   │ Email                           │ Senha    │ Descrição         │');
  console.log('   ├─────────────────────────────────┼──────────┼───────────────────┤');
  console.log('   │ paciente@teste.com              │ 123456   │ Paciente D+0      │');
  console.log('   │ paciente.semana2@teste.com      │ 123456   │ Paciente D+7      │');
  console.log('   │ paciente.semana3@teste.com      │ 123456   │ Paciente D+14     │');
  console.log('   │ admin@teste.com                 │ 123456   │ Admin da clínica  │');
  console.log('   └─────────────────────────────────┴──────────┴───────────────────┘');
}

async function run() {
  try {
    await main();
    const clinicId = await createDefaultClinic();
    await syncTemplatesForClinic(clinicId);
    await createTestUsers(clinicId);
    await createDefaultTrainingProtocol(clinicId);
    await initializePatientTrainingProgress();
    await createSampleAppointments();
    console.log('\n🎉 Seed concluído com sucesso!\n');
  } catch (error) {
    console.error('❌ Erro no seed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

run();
