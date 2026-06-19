import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

console.log("Diocese of Kalookan API Engine Active!");

export default {
  fetch: withSupabase({ auth: ["publishable", "secret"] }, async (req, ctx) => {
    
    // 1. Handle CORS Preflight requests for Web/Flutter clients
    if (req.method === 'OPTIONS') {
      return new Response('ok', {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        }
      });
    }

    const url = new URL(req.url);
    const path = url.pathname;
    const dbClient = ctx.supabaseAdmin; // Bypasses RLS for secure backend execution

    try {
      // ==========================================
      // ROUTE GROUP: AUTHENTICATION & USERS
      // ==========================================
      if (path.includes('/api/auth/')) {
        if (path.endsWith('/login') && req.method === 'POST') {
          const body = await req.json();
          
          // Verify against your required diocese credentials
          if (body.email === 'admin@diocese-kalookan.com' && body.password === 'SuperAdmin2026!Secure') {
            return Response.json({
              accessToken: "mock-test-token-xyz123",
              refreshToken: "mock-refresh-token-xyz123",
              user: {
                id: "admin-user-id",
                email: "admin@diocese-kalookan.com",
                role: "admin"
              }
            }, {
              headers: { 'Access-Control-Allow-Origin': '*' }
            });
          } else {
            // Return an explicit 401 error if the credentials don't match
            return Response.json({ error: "Invalid Credentials" }, {
              status: 401,
              headers: { 'Access-Control-Allow-Origin': '*' }
            });
          }
        }

        return Response.json({ message: "Auth endpoint active" }, {
          headers: { 'Access-Control-Allow-Origin': '*' }
        });
      }

      // ==========================================
      // ROUTE GROUP: PARISHES & UTILITIES
      // ==========================================
      if (path.endsWith('/api/parishes') && req.method === 'GET') {
        const { data, error } = await dbClient.from('parishes').select('*');
        if (error) throw error;
        return Response.json(data, { headers: { 'Access-Control-Allow-Origin': '*' } });
      }

      if (path.endsWith('/api/files')) {
        return Response.json({ message: "File manager endpoint active" }, { headers: { 'Access-Control-Allow-Origin': '*' } });
      }

      // ==========================================
      // ROUTE GROUP: CORE BOOKINGS & INTENTIONS
      // ==========================================
      if (path.endsWith('/api/bookings')) {
        if (req.method === 'GET') {
          const { data, error } = await dbClient.from('bookings').select('*');
          if (error) throw error;
          return Response.json(data, { headers: { 'Access-Control-Allow-Origin': '*' } });
        }
        if (req.method === 'POST') {
          const body = await req.json();
          const { data, error } = await dbClient.from('bookings').insert([body]);
          if (error) throw error;
          return Response.json({ success: true, data }, { headers: { 'Access-Control-Allow-Origin': '*' } });
        }
      }

      if (path.endsWith('/api/intentions') || path.endsWith('/api/mass-intentions')) {
        if (req.method === 'GET') {
          const { data, error } = await dbClient.from('intentions').select('*');
          if (error) throw error;
          return Response.json(data, { headers: { 'Access-Control-Allow-Origin': '*' } });
        }
        if (req.method === 'POST') {
          const body = await req.json();
          const { data, error } = await dbClient.from('intentions').insert([body]);
          if (error) throw error;
          return Response.json({ success: true, data }, { headers: { 'Access-Control-Allow-Origin': '*' } });
        }
      }

      // ==========================================
      // ROUTE GROUP: SACRAMENTS SPECIFIC CALLS
      // ==========================================
      // These extract requests from your specific sacrament screens and record them into your main bookings table with their specific type.
      const sacramentRoutes = [
        { path: '/api/baptisms', type: 'Baptism' },
        { path: '/api/sacraments/weddings', type: 'Wedding' },
        { path: '/api/sacraments/confirmations', type: 'Confirmation' },
        { path: '/api/sacraments/eucharist', type: 'Eucharist' },
        { path: '/api/sacraments/reconciliations', type: 'Reconciliation' },
        { path: '/api/sacraments/anointing-sick', type: 'Anointing of the Sick' },
        { path: '/api/sacraments/funeral-mass', type: 'Funeral Mass' }
      ];

      for (const route of sacramentRoutes) {
        if (path.endsWith(route.path) && req.method === 'POST') {
          const body = await req.json();
          const { data, error } = await dbClient.from('bookings').insert([{
            ...body,
            service_type: route.type // Automatically injects the correct type designation
          }]);
          if (error) throw error;
          return Response.json({ success: true, data }, { headers: { 'Access-Control-Allow-Origin': '*' } });
        }
      }

      // Fallback route handling if an unconfigured url string comes in
      return new Response(`Route [${path}] not managed on this Edge Function`, { 
        status: 404,
        headers: { 'Access-Control-Allow-Origin': '*' }
      });

    } catch (err) {
      return Response.json({ error: err.message }, { 
        status: 500,
        headers: { 'Access-Control-Allow-Origin': '*' }
      });
    }
  }),
};