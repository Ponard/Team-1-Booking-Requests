const axios = require('axios');

// Test variables
const BASE_URL = 'http://localhost:3000';
const TEST_JWT_TOKEN = process.env.TEST_JWT_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInJvbGUiOiJkaW9jZXNlX2FkbWluIiwiaWF0IjoxNjI0NTA2NDAwfQ.example'; // Replace with a valid JWT token

async function testNewEndpoints() {
  console.log('Testing new mass schedule and PDF generation endpoints...\n');

  try {
    // Test getting all mass schedules
    console.log('1. Testing GET /api/mass-schedules');
    try {
      const response = await axios.get(`${BASE_URL}/api/mass-schedules`, {
        headers: { Authorization: `Bearer ${TEST_JWT_TOKEN}` }
      });
      console.log('✓ Successfully called GET /api/mass-schedules');
      console.log(`  Status: ${response.status}`);
      console.log(`  Data length: ${response.data.massSchedules ? response.data.massSchedules.length : 0}\n`);
    } catch (error) {
      console.log(`✗ Error calling GET /api/mass-schedules: ${error.message}\n`);
    }

    // Test creating a mass schedule
    console.log('2. Testing POST /api/mass-schedules');
    try {
      const newSchedule = {
        parishId: 1,
        dayOfWeek: 'Sunday',
        startTime: '08:00',
        endTime: '09:00',
        intentionCutoffTime: '06:00',
        notes: 'Regular Sunday mass'
      };
      
      const response = await axios.post(`${BASE_URL}/api/mass-schedules`, newSchedule, {
        headers: { Authorization: `Bearer ${TEST_JWT_TOKEN}` }
      });
      console.log('✓ Successfully called POST /api/mass-schedules');
      console.log(`  Status: ${response.status}`);
      console.log(`  Created schedule ID: ${response.data.massSchedule?.id}\n`);
    } catch (error) {
      console.log(`✗ Error calling POST /api/mass-schedules: ${error.message}\n`);
    }

    // Test PDF generation endpoint (without actually downloading the PDF)
    console.log('3. Testing GET /api/mass-schedules/pdf/generate');
    try {
      const response = await axios.get(`${BASE_URL}/api/mass-schedules/pdf/generate?parishId=1`, {
        headers: { Authorization: `Bearer ${TEST_JWT_TOKEN}` },
        responseType: 'blob' // This tells axios to expect binary data
      });
      console.log('✓ Successfully called GET /api/mass-schedules/pdf/generate');
      console.log(`  Status: ${response.status}\n`);
    } catch (error) {
      console.log(`✗ Error calling GET /api/mass-schedules/pdf/generate: ${error.message}\n`);
    }

    // Test notification sending endpoint
    console.log('4. Testing POST /api/mass-schedules/notifications/send');
    try {
      const response = await axios.post(`${BASE_URL}/api/mass-schedules/notifications/send?parishId=1`, {}, {
        headers: { Authorization: `Bearer ${TEST_JWT_TOKEN}` }
      });
      console.log('✓ Successfully called POST /api/mass-schedules/notifications/send');
      console.log(`  Status: ${response.status}\n`);
    } catch (error) {
      console.log(`✗ Error calling POST /api/mass-schedules/notifications/send: ${error.message}\n`);
    }

    console.log('All tests completed!');
  } catch (error) {
    console.error('Unexpected error during testing:', error.message);
  }
}

// Run the test
testNewEndpoints();