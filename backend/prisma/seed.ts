import { PrismaClient, ContentType, ContentCategory } from '@prisma/client';

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

  // ==================== INSERIR TODOS ====================
  const allTemplates = [...sintomas, ...dieta, ...atividades, ...cuidados, ...treino];

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

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
