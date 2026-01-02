import { PrismaClient, ContentType, ContentCategory, AppointmentType, AppointmentStatus } from '@prisma/client';

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

async function run() {
  try {
    await main();
    const clinicId = await createDefaultClinic();
    await syncTemplatesForClinic(clinicId);
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
