const { getSupabaseClient, isSupabaseConfigured } = require('../config/supabase');

/**
 * Supabase Database Sync & Persistence Service
 */
class SupabaseDbService {
  /**
   * Pull all tables from Supabase into a plain JS object matching database.json schema.
   */
  async pullAll() {
    if (!isSupabaseConfigured()) return null;
    const supabase = getSupabaseClient();
    if (!supabase) return null;

    try {
      console.log('[Supabase DB] Pulling latest data from Supabase tables...');

      const [
        { data: users, error: errUsers },
        { data: packages, error: errPkgs },
        { data: invoices, error: errInvs },
        { data: payments, error: errPmts },
        { data: ledger_blocks, error: errLdg },
        { data: tasks, error: errTasks },
        { data: upstream_bills, error: errBills },
        { data: feedback, error: errFb },
        { data: devices, error: errDevs },
        { data: package_requests, error: errPkgReqs }
      ] = await Promise.all([
        supabase.from('users').select('*').order('id', { ascending: true }),
        supabase.from('packages').select('*').order('id', { ascending: true }),
        supabase.from('invoices').select('*').order('id', { ascending: true }),
        supabase.from('payments').select('*').order('id', { ascending: true }),
        supabase.from('ledger_blocks').select('*').order('idx', { ascending: true }),
        supabase.from('tasks').select('*').order('id', { ascending: true }),
        supabase.from('upstream_bills').select('*').order('id', { ascending: true }),
        supabase.from('feedback').select('*').order('id', { ascending: true }),
        supabase.from('devices').select('*').order('id', { ascending: true }),
        supabase.from('package_requests').select('*').order('id', { ascending: true })
      ]);

      if (errUsers) {
        console.warn('[Supabase DB] Failed pulling users:', errUsers.message);
        return null;
      }

      console.log(`[Supabase DB] Successfully synced from Supabase: ${users?.length || 0} users, ${packages?.length || 0} packages, ${invoices?.length || 0} invoices.`);

      return {
        users: users || [],
        packages: packages || [],
        invoices: invoices || [],
        payments: payments || [],
        ledger_blocks: ledger_blocks || [],
        tasks: tasks || [],
        upstream_bills: upstream_bills || [],
        feedback: feedback || [],
        devices: devices || [],
        package_requests: package_requests || []
      };
    } catch (err) {
      console.error('[Supabase DB Sync Error]:', err.message);
      return null;
    }
  }

  /**
   * Push an entire local database dataset to Supabase.
   * Useful for initial migration / seeding.
   */
  async pushAll(dbData) {
    if (!isSupabaseConfigured()) {
      throw new Error('Supabase is not configured in .env (SUPABASE_URL / SUPABASE_KEY missing)');
    }
    const supabase = getSupabaseClient();
    if (!supabase) {
      throw new Error('Failed to initialize Supabase client');
    }

    console.log('[Supabase DB] Starting migration of local data to Supabase...');

    // 1. Packages
    if (dbData.packages && dbData.packages.length > 0) {
      const { error } = await supabase.from('packages').upsert(dbData.packages, { onConflict: 'id' });
      if (error) console.error('Error migrating packages:', error.message);
      else console.log(`✓ Migrated ${dbData.packages.length} packages`);
    }

    // 2. Users
    if (dbData.users && dbData.users.length > 0) {
      const safeUsers = dbData.users.map(u => ({
        id: u.id,
        nama: u.nama,
        email: u.email,
        no_hp: u.no_hp || '',
        password_hash: u.password_hash,
        role: u.role || 'pelanggan',
        negara: u.negara || 'Indonesia',
        mata_uang: u.mata_uang || 'IDR',
        zona_waktu: u.zona_waktu || 'WIB',
        alamat: u.alamat || '',
        lat: u.lat || -7.7956,
        lng: u.lng || 110.3695,
        foto: u.foto || '',
        status: u.status || 'active',
        paket_id: u.paket_id || null
      }));
      const { error } = await supabase.from('users').upsert(safeUsers, { onConflict: 'id' });
      if (error) console.error('Error migrating users:', error.message);
      else console.log(`✓ Migrated ${safeUsers.length} users`);
    }

    // 3. Invoices
    if (dbData.invoices && dbData.invoices.length > 0) {
      const { error } = await supabase.from('invoices').upsert(dbData.invoices, { onConflict: 'id' });
      if (error) console.error('Error migrating invoices:', error.message);
      else console.log(`✓ Migrated ${dbData.invoices.length} invoices`);
    }

    // 4. Payments
    if (dbData.payments && dbData.payments.length > 0) {
      const { error } = await supabase.from('payments').upsert(dbData.payments, { onConflict: 'id' });
      if (error) console.error('Error migrating payments:', error.message);
      else console.log(`✓ Migrated ${dbData.payments.length} payments`);
    }

    // 5. Ledger Blocks
    if (dbData.ledger_blocks && dbData.ledger_blocks.length > 0) {
      const { error } = await supabase.from('ledger_blocks').upsert(dbData.ledger_blocks, { onConflict: 'idx' });
      if (error) console.error('Error migrating ledger_blocks:', error.message);
      else console.log(`✓ Migrated ${dbData.ledger_blocks.length} ledger blocks`);
    }

    // 6. Tasks
    if (dbData.tasks && dbData.tasks.length > 0) {
      const { error } = await supabase.from('tasks').upsert(dbData.tasks, { onConflict: 'id' });
      if (error) console.error('Error migrating tasks:', error.message);
      else console.log(`✓ Migrated ${dbData.tasks.length} tasks`);
    }

    // 7. Upstream Bills
    if (dbData.upstream_bills && dbData.upstream_bills.length > 0) {
      const { error } = await supabase.from('upstream_bills').upsert(dbData.upstream_bills, { onConflict: 'id' });
      if (error) console.error('Error migrating upstream_bills:', error.message);
      else console.log(`✓ Migrated ${dbData.upstream_bills.length} upstream bills`);
    }

    // 8. Feedback
    if (dbData.feedback && dbData.feedback.length > 0) {
      const { error } = await supabase.from('feedback').upsert(dbData.feedback, { onConflict: 'id' });
      if (error) console.error('Error migrating feedback:', error.message);
      else console.log(`✓ Migrated ${dbData.feedback.length} feedback items`);
    }

    // 9. Devices
    if (dbData.devices && dbData.devices.length > 0) {
      const { error } = await supabase.from('devices').upsert(dbData.devices, { onConflict: 'id' });
      if (error) console.error('Error migrating devices:', error.message);
      else console.log(`✓ Migrated ${dbData.devices.length} devices`);
    }

    // 10. Package Requests
    if (dbData.package_requests && dbData.package_requests.length > 0) {
      const { error } = await supabase.from('package_requests').upsert(dbData.package_requests, { onConflict: 'id' });
      if (error) console.warn('[Supabase Sync Notice] package_requests table in Supabase:', error.message);
      else console.log(`✓ Migrated ${dbData.package_requests.length} package requests`);
    }

    console.log('[Supabase DB] Migration finished successfully!');
    return true;
  }

  // Asynchronous entity upserts to keep Supabase in sync
  async syncEntity(table, record, conflictColumn = 'id') {
    if (!isSupabaseConfigured()) return;
    const supabase = getSupabaseClient();
    if (!supabase) return;

    try {
      const { error } = await supabase.from(table).upsert(record, { onConflict: conflictColumn });
      if (error) {
        console.warn(`[Supabase Sync Warning] Failed to sync ${table}:`, error.message);
      }
    } catch (err) {
      console.warn(`[Supabase Sync Error] ${table}:`, err.message);
    }
  }

  async deleteEntity(table, id, idColumn = 'id') {
    if (!isSupabaseConfigured()) return;
    const supabase = getSupabaseClient();
    if (!supabase) return;

    try {
      const { error } = await supabase.from(table).delete().eq(idColumn, id);
      if (error) {
        console.warn(`[Supabase Delete Warning] Failed to delete from ${table}:`, error.message);
      }
    } catch (err) {
      console.warn(`[Supabase Delete Error] ${table}:`, err.message);
    }
  }
}

module.exports = new SupabaseDbService();
