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

  // Configurar dias úteis (Segunda a Sexta = 1 a 5)
  const diasUteis = [
    { dayOfWeek: 1, nome: 'Segunda' },
    { dayOfWeek: 2, nome: 'Terça' },
    { dayOfWeek: 3, nome: 'Quarta' },
    { dayOfWeek: 4, nome: 'Quinta' },
    { dayOfWeek: 5, nome: 'Sexta' },
  ];

  for (const dia of diasUteis) {
    // Verificar se já existe
    const existing = await prisma.clinicSchedule.findFirst({
      where: { clinicId: clinic.id, dayOfWeek: dia.dayOfWeek }
    });

    if (existing) {
      // Atualizar para ativo
      await prisma.clinicSchedule.update({
        where: { id: existing.id },
        data: { isActive: true, openTime: '08:00', closeTime: '18:00' }
      });
      console.log(`${dia.nome}: atualizado para ativo`);
    } else {
      // Criar
      await prisma.clinicSchedule.create({
        data: {
          clinicId: clinic.id,
          dayOfWeek: dia.dayOfWeek,
          openTime: '08:00',
          closeTime: '18:00',
          slotDuration: 30,
          maxSlots: 20,
          isActive: true
        }
      });
      console.log(`${dia.nome}: criado`);
    }
  }

  // Mostrar horários finais
  const finalSchedules = await prisma.clinicSchedule.findMany({
    where: { clinicId: clinic.id },
    orderBy: { dayOfWeek: 'asc' }
  });

  const dayNames = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
  console.log('\n=== Horários configurados ===');
  for (const schedule of finalSchedules) {
    console.log(`${dayNames[schedule.dayOfWeek]}: ${schedule.openTime} - ${schedule.closeTime} (ativo: ${schedule.isActive})`);
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
