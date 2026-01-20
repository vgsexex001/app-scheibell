/**
 * Script para limpar dados de teste mantendo usuários, clínicas e pacientes
 * Execução: npx ts-node prisma/clear-test-data.ts
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function clearTestData() {
  console.log('🧹 Iniciando limpeza de dados de teste...\n');

  try {
    // Ordem de deleção respeitando foreign keys (do mais dependente para o menos)

    // 1. Dados de progresso e completions
    console.log('Limpando progresso de treinamento...');
    await prisma.patientSessionCompletion.deleteMany({});
    await prisma.patientTrainingProgress.deleteMany({});

    // 2. Tasks e logs
    console.log('Limpando tasks e logs...');
    await prisma.taskCompletionLog.deleteMany({});
    await prisma.patientTask.deleteMany({});
    await prisma.medicationLog.deleteMany({});
    await prisma.videoProgress.deleteMany({});

    // 3. Chat
    console.log('Limpando chat...');
    await prisma.chatAttachment.deleteMany({});
    await prisma.chatMessage.deleteMany({});
    await prisma.chatConversation.deleteMany({});

    // 4. Alertas e notificações
    console.log('Limpando alertas e notificações...');
    await prisma.alert.deleteMany({});
    await prisma.notification.deleteMany({});

    // 5. Exames
    console.log('Limpando exames...');
    await prisma.exam.deleteMany({});

    // 6. Agendamentos e eventos externos
    console.log('Limpando agendamentos...');
    await prisma.externalEvent.deleteMany({});
    await prisma.appointment.deleteMany({});

    // 7. Schedules e bloqueios
    console.log('Limpando configurações de horários...');
    await prisma.clinicBlockedDateByType.deleteMany({});
    await prisma.clinicBlockedDate.deleteMany({});
    await prisma.clinicSchedule.deleteMany({});

    // 8. Conteúdo personalizado do paciente
    console.log('Limpando conteúdo personalizado...');
    await prisma.patientContentState.deleteMany({});
    await prisma.patientContentOverride.deleteMany({});
    await prisma.patientContentAdjustment.deleteMany({});

    // 9. Conteúdo da clínica (vídeos, etc)
    console.log('Limpando conteúdo da clínica...');
    await prisma.clinicContent.deleteMany({});

    // 10. Treinamento (sessões, semanas, protocolos)
    console.log('Limpando protocolos de treinamento...');
    await prisma.trainingSession.deleteMany({});
    await prisma.trainingWeek.deleteMany({});
    await prisma.trainingProtocol.deleteMany({});

    // 11. Templates de conteúdo
    console.log('Limpando templates...');
    await prisma.contentTemplate.deleteMany({});

    // 12. Notas médicas e alergias
    console.log('Limpando notas médicas e alergias...');
    await prisma.medicalNote.deleteMany({});
    await prisma.patientAllergy.deleteMany({});

    // 13. Jobs
    console.log('Limpando jobs...');
    await prisma.job.deleteMany({});

    console.log('\n✅ Dados de teste limpos com sucesso!');
    console.log('\n📋 O que foi MANTIDO:');
    console.log('   - Usuários (emails e senhas)');
    console.log('   - Clínicas');
    console.log('   - Pacientes');
    console.log('   - Conexões paciente-clínica');
    console.log('   - Templates do sistema');
    console.log('   - Tokens de autenticação');

    console.log('\n📋 O que foi LIMPO:');
    console.log('   - Agendamentos');
    console.log('   - Configurações de horários');
    console.log('   - Datas bloqueadas');
    console.log('   - Exames');
    console.log('   - Chat/mensagens');
    console.log('   - Alertas e notificações');
    console.log('   - Progresso de treinamento');
    console.log('   - Conteúdo personalizado');
    console.log('   - Vídeos da clínica');
    console.log('   - Notas médicas');

  } catch (error) {
    console.error('❌ Erro ao limpar dados:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

clearTestData()
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
