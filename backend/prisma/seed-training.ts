import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding training protocol...');

  // Check if default protocol already exists
  const existingProtocol = await prisma.trainingProtocol.findFirst({
    where: { isDefault: true },
  });

  if (existingProtocol) {
    console.log('Default protocol already exists:', existingProtocol.name);
    return;
  }

  // Create default training protocol
  const protocol = await prisma.trainingProtocol.create({
    data: {
      name: 'Protocolo Padrão de Reabilitação',
      description: 'Protocolo de reabilitação pós-cirúrgica de 8 semanas',
      isDefault: true,
      isActive: true,
      totalWeeks: 8,
      weeks: {
        create: [
          // Week 1
          {
            weekNumber: 1,
            title: 'Semana 1 - Fase Inicial',
            dayRange: 'Dias 1-7',
            objective: 'Foco em repouso e movimentos leves',
            maxHeartRate: 90,
            heartRateLabel: 'FC Basal + 15 bpm',
            canDo: ['Caminhada leve em casa', 'Exercícios respiratórios', 'Movimentos de braços sentado'],
            avoid: ['Esforço físico intenso', 'Levantar peso acima de 2kg', 'Subir escadas rapidamente'],
            sessions: {
              create: [
                {
                  sessionNumber: 1,
                  name: 'Exercícios Respiratórios',
                  description: 'Exercícios de respiração profunda para recuperação pulmonar',
                  duration: 10,
                  intensity: 'Leve',
                },
                {
                  sessionNumber: 2,
                  name: 'Mobilidade Leve',
                  description: 'Movimentos suaves para manter a mobilidade',
                  duration: 15,
                  intensity: 'Leve',
                },
              ],
            },
          },
          // Week 2
          {
            weekNumber: 2,
            title: 'Semana 2 - Progressão Inicial',
            dayRange: 'Dias 8-14',
            objective: 'Aumento gradual da atividade',
            maxHeartRate: 100,
            heartRateLabel: 'FC Basal + 20 bpm',
            canDo: ['Caminhada curta ao ar livre', 'Alongamentos suaves', 'Exercícios de equilíbrio'],
            avoid: ['Corrida', 'Levantamento de peso', 'Exercícios abdominais'],
            sessions: {
              create: [
                {
                  sessionNumber: 1,
                  name: 'Caminhada Guiada',
                  description: 'Caminhada leve de 10-15 minutos',
                  duration: 15,
                  intensity: 'Leve',
                },
                {
                  sessionNumber: 2,
                  name: 'Alongamentos',
                  description: 'Série de alongamentos para flexibilidade',
                  duration: 20,
                  intensity: 'Leve',
                },
              ],
            },
          },
          // Week 3
          {
            weekNumber: 3,
            title: 'Semana 3 - Fortalecimento Leve',
            dayRange: 'Dias 15-21',
            objective: 'Início de exercícios de fortalecimento',
            maxHeartRate: 110,
            heartRateLabel: 'FC Basal + 25 bpm',
            canDo: ['Exercícios com elástico leve', 'Caminhada de 20 minutos', 'Subir escadas devagar'],
            avoid: ['Exercícios de alto impacto', 'Peso livre acima de 3kg'],
            sessions: {
              create: [
                {
                  sessionNumber: 1,
                  name: 'Fortalecimento com Elástico',
                  description: 'Exercícios de resistência leve',
                  duration: 20,
                  intensity: 'Leve-Moderada',
                },
              ],
            },
          },
          // Week 4
          {
            weekNumber: 4,
            title: 'Semana 4 - Consolidação',
            dayRange: 'Dias 22-28',
            objective: 'Consolidação dos progressos anteriores',
            maxHeartRate: 115,
            heartRateLabel: 'FC Basal + 30 bpm',
            canDo: ['Caminhada de 30 minutos', 'Exercícios aeróbicos leves', 'Yoga suave'],
            avoid: ['Corrida', 'Natação intensa', 'Esportes de contato'],
            sessions: {
              create: [
                {
                  sessionNumber: 1,
                  name: 'Aeróbico Leve',
                  description: 'Exercícios cardiovasculares de baixa intensidade',
                  duration: 25,
                  intensity: 'Moderada',
                },
              ],
            },
          },
          // Week 5
          {
            weekNumber: 5,
            title: 'Semana 5 - Intensidade Moderada',
            dayRange: 'Dias 29-35',
            objective: 'Aumento da intensidade dos exercícios',
            maxHeartRate: 120,
            heartRateLabel: 'FC Basal + 35 bpm',
            canDo: ['Caminhada rápida', 'Bicicleta ergométrica', 'Exercícios de força leve'],
            avoid: ['Corrida intensa', 'Levantamento de peso pesado'],
            sessions: {
              create: [
                {
                  sessionNumber: 1,
                  name: 'Circuito Moderado',
                  description: 'Circuito de exercícios de intensidade moderada',
                  duration: 30,
                  intensity: 'Moderada',
                },
              ],
            },
          },
          // Week 6
          {
            weekNumber: 6,
            title: 'Semana 6 - Resistência',
            dayRange: 'Dias 36-42',
            objective: 'Foco em resistência cardiovascular',
            maxHeartRate: 125,
            heartRateLabel: 'FC Basal + 40 bpm',
            canDo: ['Caminhada de 45 minutos', 'Natação leve', 'Exercícios de resistência'],
            avoid: ['Esportes de alto impacto', 'Competições'],
            sessions: {
              create: [
                {
                  sessionNumber: 1,
                  name: 'Resistência Cardio',
                  description: 'Exercícios para melhorar resistência',
                  duration: 35,
                  intensity: 'Moderada-Alta',
                },
              ],
            },
          },
          // Week 7
          {
            weekNumber: 7,
            title: 'Semana 7 - Força Funcional',
            dayRange: 'Dias 43-49',
            objective: 'Exercícios de força funcional',
            maxHeartRate: 130,
            heartRateLabel: 'FC Basal + 45 bpm',
            canDo: ['Exercícios funcionais', 'Corrida leve', 'Peso livre moderado'],
            avoid: ['Exercícios explosivos', 'Competições intensas'],
            sessions: {
              create: [
                {
                  sessionNumber: 1,
                  name: 'Treino Funcional',
                  description: 'Exercícios funcionais para o dia a dia',
                  duration: 40,
                  intensity: 'Alta',
                },
              ],
            },
          },
          // Week 8
          {
            weekNumber: 8,
            title: 'Semana 8 - Retorno às Atividades',
            dayRange: 'Dias 50-56',
            objective: 'Preparação para retorno às atividades normais',
            maxHeartRate: 140,
            heartRateLabel: 'FC Basal + 50 bpm',
            canDo: ['Atividades físicas normais', 'Esportes recreativos', 'Academia com supervisão'],
            avoid: ['Esportes de contato sem liberação', 'Exercícios muito intensos sem acompanhamento'],
            sessions: {
              create: [
                {
                  sessionNumber: 1,
                  name: 'Treino Completo',
                  description: 'Treino completo de manutenção',
                  duration: 45,
                  intensity: 'Alta',
                },
              ],
            },
          },
        ],
      },
    },
    include: {
      weeks: {
        include: {
          sessions: true,
        },
      },
    },
  });

  console.log('Created default training protocol:', protocol.name);
  console.log(`   - ${protocol.weeks.length} weeks`);
  protocol.weeks.forEach((week: any) => {
    console.log(`   - Week ${week.weekNumber}: ${week.sessions.length} sessions`);
  });
}

main()
  .catch((e) => {
    console.error('Error seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
