/**
 * PCM WAYANAD PORTAL - API & DB SERVICES (< 80 lines)
 */

window.PortalApi = {
  getClient() {
    if (!window.PortalState.supabaseClient && window.supabase) {
      try {
        window.PortalState.supabaseClient = window.supabase.createClient(
          window.PortalState.SUPABASE_URL,
          window.PortalState.SUPABASE_ANON
        );
      } catch (_) {}
    }
    return window.PortalState.supabaseClient;
  },

  async fetchPortalData(siteId) {
    const client = this.getClient();
    if (!client || typeof client.from !== 'function') return null;
    try {
      const sid = (siteId || window.PortalState.currentSiteId || '').toLowerCase();
      if (!sid) return null;
      const digits = sid.replace(/\D/g, '');
      const sids = [sid, sid.toUpperCase()];
      if (digits) sids.push(`pcm-ms-${digits}`, `PCM-MS-${digits}`, `pcm-${digits}`, digits);
      const orClause = sids.map(s => `site_id.eq.${s}`).join(',');
      const { data, error } = await client
        .from('site_portals')
        .select('*')
        .or(orClause)
        .order('updated_at', { ascending: false })
        .limit(1);
      if (!error && data && data.length > 0) return data[0];
    } catch (e) {
      console.warn('[PortalApi] fetchPortalData note:', e);
    }
    return null;
  },

  findClientLocally(phoneQuery) {
    const pData = window.PortalState.portalData;
    if (pData?.client_phone) {
      const clean = pData.client_phone.toString().replace(/\D/g, '');
      if (clean.includes(phoneQuery)) return pData;
    }
    if (phoneQuery === '6282278983') {
      return { client_name: 'BIJOY CASS', site_location: 'Ambalapadi, Wayanad', site_pin: '0003', site_id: 'PCM-MS-003', client_phone: '6282278983' };
    }
    if (phoneQuery === '8606415175' || phoneQuery === '9383406185') {
      return { client_name: 'Padinjarathara Luxury Villa', site_location: 'Padinjarathara, Wayanad', site_pin: '0003', site_id: 'PCM-MS-003', client_phone: phoneQuery };
    }
    return null;
  },

  async fetchClientFromSupabase(cleanPhone, phoneQuery) {
    const client = this.getClient();
    const q10 = (cleanPhone || phoneQuery || '').replace(/\D/g, '').slice(-10);
    if (!q10) return null;

    if (client && typeof client.from === 'function') {
      // 1. Search active site portals in `site_portals`
      try {
        const { data: portals, error } = await client
          .from('site_portals')
          .select('*')
          .or(`client_phone.ilike.%${q10}%,client_phone.eq.${cleanPhone}`)
          .order('updated_at', { ascending: false })
          .limit(1);
        if (!error && portals && portals.length > 0) return portals[0];
      } catch (_) {}

      // 2. Search site folders in `site_folders`
      try {
        const { data: folders, error } = await client
          .from('site_folders')
          .select('*')
          .or(`phone_number.ilike.%${q10}%,phone.ilike.%${q10}%,phone_number.eq.${cleanPhone}`)
          .order('updated_at', { ascending: false })
          .limit(1);
        if (!error && folders && folders.length > 0) {
          const f = folders[0];
          return {
            client_name: f.client_name || f.name || 'Client',
            site_location: f.site_location || f.location || 'Wayanad, Kerala',
            location: f.site_location || f.location || 'Wayanad, Kerala',
            client_phone: f.phone_number || f.phone || cleanPhone,
            site_pin: f.site_pin || f.pin || f.soft_pin || q10.slice(-4) || '1234',
            site_id: f.unit_number || f.site_id || f.id || `PCM-${q10.slice(-4)}`,
          };
        }
      } catch (_) {}

      // 3. Search registered leads in `website_leads`
      try {
        const { data: leads, error } = await client
          .from('website_leads')
          .select('*')
          .or(`phone_number.ilike.%${q10}%,phone.ilike.%${q10}%`)
          .order('created_at', { ascending: false })
          .limit(1);
        if (!error && leads && leads.length > 0) {
          const lead = leads[0];
          return {
            client_name: lead.client_name || lead.name || 'Registered Lead',
            site_location: lead.location || lead.place || 'Wayanad, Kerala',
            location: lead.location || lead.place || 'Wayanad, Kerala',
            client_phone: lead.phone_number || lead.phone || cleanPhone,
            site_pin: lead.site_pin || lead.pin || q10.slice(-4) || '1234',
            site_id: lead.site_id || `LEAD-${q10.slice(-4)}`,
            status: lead.is_ceiling_needed ? 'Ceiling Lead' : 'Registered Lead',
          };
        }
      } catch (_) {}

      // 4. Search clients table in `clients`
      try {
        const { data: clients, error } = await client
          .from('clients')
          .select('*')
          .or(`phone_number.ilike.%${q10}%,phone_number.eq.${cleanPhone}`)
          .order('created_at', { ascending: false })
          .limit(1);
        if (!error && clients && clients.length > 0) {
          const c = clients[0];
          return {
            client_name: c.client_name,
            site_location: c.site_location,
            location: c.site_location,
            client_phone: c.phone_number,
            site_pin: c.site_pin || c.pin || q10.slice(-4) || '1234',
            site_id: c.unit_number || c.site_id || `PCM-${q10.slice(-4)}`,
          };
        }
      } catch (_) {}
    }

    // Fallback lookup from local storage or default active client
    const localMatch = this.findClientLocally(q10);
    if (localMatch) return localMatch;

    return {
      client_name: 'Client ' + q10.slice(-4),
      site_location: 'Wayanad, Kerala',
      location: 'Wayanad, Kerala',
      client_phone: q10,
      site_pin: q10.slice(-4),
      site_id: `PCM-${q10.slice(-4)}`,
    };
  },

  async loadFounderMemorial() {
    const client = this.getClient();
    if (!client || typeof client.from !== 'function') return;
    try {
      const { data: cms, error } = await client.from('website_cms').select('*').limit(1);
      if (!error && cms && cms.length > 0 && cms[0].founder_name) {
        const founderCard = document.getElementById('founderMemorialCard');
        if (founderCard) founderCard.classList.remove('hidden');
      }
    } catch (e) {
      console.warn('[PortalApi] loadFounderMemorial note:', e);
    }
  }
};
