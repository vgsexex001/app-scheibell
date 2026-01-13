import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Buscar a clínica
  const clinic = await prisma.clinic.findFirst();

  if (!clinic) {
    console.log('Nenhuma clínica encontrada');
    return;
  }

  console.log('Clínica encontrada:', clinic.id, clinic.name);

  // Ver horários atuais
  const currentSchedules = await prisma.clinicSchedule.findMany({
    where: { clinicId: clinic.id },
    orderBy: { dayOfWeek: 'asc' }
  });

  console.log('\nHorários atuais:');
  const dayNames = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
  for (const schedule of currentSchedules) {
    console.log(`  ${dayNames[schedule.dayOfWeek]}: ${schedule.openTime} - ${schedule.closeTime} (ativo: ${schedule.isActive})`);
  }

  // Verificar se quinta-feira (4) já existe
  const thursdayExists = currentSchedules.find(s => s.dayOfWeek === 4);

  if (thursdayExists) {
    // Atualizar para ativo
    await prisma.clinicSchedule.update({
      where: { id: thursdayExists.id },
      data: { isActive: true }
    });
    console.log('\nQuinta-feira já existia - atualizado para ativo!');
  } else {
    // Criar novo registro para quinta-feira
    await prisma.clinicSchedule.create({
      data: {
        clinicId: clinic.id,
        dayOfWeek: 4, // Quinta-feira
        openTime: '08:00',
        closeTime: '18:00',
        slotDuration: 30,
        maxSlots: 20,
        isActive: true
      }
    });
    console.log('\nQuinta-feira adicionada com sucesso!');
  }

  // Mostrar horários finais
  const finalSchedules = await prisma.clinicSchedule.findMany({
    where: { clinicId: clinic.id },
    orderBy: { dayOfWeek: 'asc' }
  });

  console.log('\nHorários finais:');
  for (const schedule of finalSchedules) {
    console.log(`  ${dayNames[schedule.dayOfWeek]}: ${schedule.openTime} - ${schedule.closeTime} (ativo: ${schedule.isActive})`);
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
