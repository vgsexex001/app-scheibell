const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function checkAndFix() {
  const users = await prisma.user.findMany({
    select: { id: true, email: true, name: true, role: true, passwordHash: true }
  });

  console.log('Usuarios encontrados:', users.length);

  for (const user of users) {
    console.log('- Email:', user.email, '| Role:', user.role);
    const isValid = await bcrypt.compare('123456', user.passwordHash);
    console.log('  Senha 123456 valida?', isValid);

    if (!isValid) {
      const newHash = await bcrypt.hash('123456', 10);
      await prisma.user.update({
        where: { id: user.id },
        data: { passwordHash: newHash }
      });
      console.log('  -> Senha corrigida!');
    }
  }

  await prisma.$disconnect();
}

checkAndFix();
