import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Admin Endpoints (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let adminToken: string;
  let testClinicId: string;
  let testPatientId: string;
  let testAppointmentId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
    await app.init();

    prisma = app.get(PrismaService);

    // Create test data
    await setupTestData();
  });

  afterAll(async () => {
    // Clean up test data
    await cleanupTestData();
    await app.close();
  });

  async function setupTestData() {
    // Create test clinic
    const clinic = await prisma.clinic.create({
      data: {
        name: 'Test Clinic E2E',
        email: 'test-e2e@clinic.com',
        phone: '(11) 99999-9999',
      },
    });
    testClinicId = clinic.id;

    // Create admin user
    const bcrypt = require('bcrypt');
    const passwordHash = await bcrypt.hash('admin123', 10);

    const adminUser = await prisma.user.create({
      data: {
        email: 'admin-e2e@test.com',
        passwordHash,
        name: 'Admin E2E Test',
        role: 'CLINIC_ADMIN',
        clinicId: testClinicId,
      },
    });

    // Create test patient
    const patientUser = await prisma.user.create({
      data: {
        email: 'patient-e2e@test.com',
        passwordHash,
        name: 'Patient E2E Test',
        role: 'PATIENT',
        clinicId: testClinicId,
      },
    });

    const patient = await prisma.patient.create({
      data: {
        userId: patientUser.id,
        name: 'Patient E2E Test',
        email: 'patient-e2e@test.com',
        clinicId: testClinicId,
        surgeryDate: new Date(),
        surgeryType: 'Test Surgery',
      },
    });
    testPatientId = patient.id;

    // Create test appointment
    const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const appointment = await prisma.appointment.create({
      data: {
        patientId: testPatientId,
        title: 'Test Appointment E2E',
        date: tomorrow,
        time: '10:00',
        type: 'RETURN_VISIT',
        status: 'PENDING',
        notes: 'Test appointment',
      },
    });
    testAppointmentId = appointment.id;

    // Login as admin to get token
    const loginResponse = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({
        email: 'admin-e2e@test.com',
        password: 'admin123',
      });

    adminToken = loginResponse.body.accessToken;
  }

  async function cleanupTestData() {
    // Delete in order due to foreign keys
    await prisma.appointment.deleteMany({ where: { patientId: testPatientId } });
    await prisma.patientConnection.deleteMany({ where: { clinicId: testClinicId } });
    await prisma.alert.deleteMany({ where: { patientId: testPatientId } });
    await prisma.exam.deleteMany({ where: { patientId: testPatientId } });
    await prisma.patient.deleteMany({ where: { clinicId: testClinicId } });
    await prisma.user.deleteMany({ where: { clinicId: testClinicId } });
    await prisma.clinic.delete({ where: { id: testClinicId } });
  }

  // ========== AUTH TESTS ==========

  describe('Auth', () => {
    it('should login as admin and return tokens', async () => {
      const response = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({
          email: 'admin-e2e@test.com',
          password: 'admin123',
        })
        .expect(200);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
      expect(response.body.user.role).toBe('CLINIC_ADMIN');
    });

    it('should reject invalid credentials', async () => {
      await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({
          email: 'admin-e2e@test.com',
          password: 'wrongpassword',
        })
        .expect(401);
    });

    it('should validate token and return user profile', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('email', 'admin-e2e@test.com');
      expect(response.body).toHaveProperty('role', 'CLINIC_ADMIN');
    });
  });

  // ========== DASHBOARD TESTS ==========

  describe('Dashboard', () => {
    it('should return dashboard summary for admin', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/admin/dashboard/summary')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('consultationsToday');
      expect(response.body).toHaveProperty('pendingApprovals');
      expect(response.body).toHaveProperty('activeAlerts');
      expect(response.body).toHaveProperty('adherenceRate');
    });

    it('should reject unauthenticated access to dashboard', async () => {
      await request(app.getHttpServer())
        .get('/api/admin/dashboard/summary')
        .expect(401);
    });
  });

  // ========== APPOINTMENTS TESTS ==========

  describe('Appointments', () => {
    it('should list pending appointments', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/admin/appointments/pending')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(response.body).toHaveProperty('total');
      expect(Array.isArray(response.body.items)).toBe(true);
    });

    it('should approve an appointment', async () => {
      const response = await request(app.getHttpServer())
        .post(`/api/admin/appointments/${testAppointmentId}/approve`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(201);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.appointment).toHaveProperty('id', testAppointmentId);
      expect(response.body.appointment.status).toBe('CONFIRMED');
    });

    it('should reject a non-existent appointment with 404', async () => {
      await request(app.getHttpServer())
        .post('/api/admin/appointments/non-existent-id/approve')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(404);
    });
  });

  // ========== PATIENTS TESTS ==========

  describe('Patients', () => {
    it('should list patients for clinic', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/patients')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(response.body).toHaveProperty('total');
      expect(Array.isArray(response.body.items)).toBe(true);
    });

    it('should get patient details by ID', async () => {
      const response = await request(app.getHttpServer())
        .get(`/api/patients/${testPatientId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('id', testPatientId);
      expect(response.body).toHaveProperty('name');
      expect(response.body).toHaveProperty('email');
    });

    it('should return 404 for non-existent patient', async () => {
      await request(app.getHttpServer())
        .get('/api/patients/non-existent-id')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(404);
    });
  });

  // ========== EXAMS TESTS ==========

  describe('Exams', () => {
    let testExamId: string;

    it('should create an exam for patient', async () => {
      const response = await request(app.getHttpServer())
        .post('/api/exams')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          patientId: testPatientId,
          title: 'Blood Test E2E',
          type: 'BLOOD_TEST',
          date: new Date().toISOString(),
          notes: 'E2E test exam',
        })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('title', 'Blood Test E2E');
      testExamId = response.body.id;
    });

    it('should list clinic exams', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/exams/admin')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(response.body).toHaveProperty('total');
    });

    it('should get clinic exam stats', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/exams/admin/stats')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('totalExams');
      expect(response.body).toHaveProperty('pendingExams');
    });

    it('should delete exam', async () => {
      if (testExamId) {
        await request(app.getHttpServer())
          .delete(`/api/exams/${testExamId}`)
          .set('Authorization', `Bearer ${adminToken}`)
          .expect(200);
      }
    });
  });

  // ========== CONNECTIONS TESTS ==========

  describe('Connections', () => {
    let testConnectionCode: string;

    it('should generate connection code for patient', async () => {
      const response = await request(app.getHttpServer())
        .post(`/api/admin/patients/${testPatientId}/connection-code`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(201);

      expect(response.body).toHaveProperty('connectionCode');
      expect(response.body.connectionCode).toHaveLength(6);
      testConnectionCode = response.body.connectionCode;
    });

    it('should list patient connections', async () => {
      const response = await request(app.getHttpServer())
        .get(`/api/admin/patients/${testPatientId}/connections`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
    });

    it('should list all clinic connections', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/admin/connections')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(response.body).toHaveProperty('total');
    });

    it('should get connection stats', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/admin/connections/stats')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('totalConnections');
      expect(response.body).toHaveProperty('pendingConnections');
    });
  });

  // ========== CHAT ADMIN TESTS ==========

  describe('Chat Admin', () => {
    it('should list admin conversations (may be empty)', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/chat/admin/conversations')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(response.body).toHaveProperty('total');
    });
  });

  // ========== ALERTS TESTS ==========

  describe('Alerts', () => {
    let testAlertId: string;

    it('should list alerts for clinic', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/admin/alerts')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(response.body).toHaveProperty('total');
    });

    it('should create an alert', async () => {
      const response = await request(app.getHttpServer())
        .post('/api/admin/alerts')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          patientId: testPatientId,
          type: 'OTHER',
          title: 'Test Alert E2E',
          description: 'This is a test alert',
        })
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('title', 'Test Alert E2E');
      testAlertId = response.body.id;
    });

    it('should resolve an alert', async () => {
      if (testAlertId) {
        const response = await request(app.getHttpServer())
          .patch(`/api/admin/alerts/${testAlertId}/resolve`)
          .set('Authorization', `Bearer ${adminToken}`)
          .expect(200);

        expect(response.body).toHaveProperty('success', true);
        expect(response.body.alert.status).toBe('RESOLVED');
      }
    });
  });

  // ========== RBAC TESTS ==========

  describe('RBAC - Role-Based Access Control', () => {
    let patientToken: string;

    beforeAll(async () => {
      // Login as patient
      const loginResponse = await request(app.getHttpServer())
        .post('/api/auth/login')
        .send({
          email: 'patient-e2e@test.com',
          password: 'admin123',
        });

      patientToken = loginResponse.body.accessToken;
    });

    it('should deny patient access to admin dashboard', async () => {
      await request(app.getHttpServer())
        .get('/api/admin/dashboard/summary')
        .set('Authorization', `Bearer ${patientToken}`)
        .expect(403);
    });

    it('should deny patient access to pending appointments', async () => {
      await request(app.getHttpServer())
        .get('/api/admin/appointments/pending')
        .set('Authorization', `Bearer ${patientToken}`)
        .expect(403);
    });

    it('should deny patient access to clinic exams', async () => {
      await request(app.getHttpServer())
        .get('/api/exams/admin')
        .set('Authorization', `Bearer ${patientToken}`)
        .expect(403);
    });
  });
});
