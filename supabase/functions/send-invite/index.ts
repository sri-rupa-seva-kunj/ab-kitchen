import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SITE_URL = (Deno.env.get('SITE_URL') ?? '').replace(/\/$/, '');
const ALLOWED_ORIGIN = SITE_URL ? new URL(SITE_URL).origin : '';

const corsHeaders = {
  'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (!SITE_URL) {
    return new Response(
      JSON.stringify({ error: 'SITE_URL is not configured' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Получаем service role client для admin операций
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Получаем обычный client для проверки прав вызывающего
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    // Проверяем что вызывающий авторизован и имеет права
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Проверяем права (superuser или manage_users)
    const { data: callerVaishnava } = await supabaseAdmin
      .from('vaishnavas')
      .select('is_superuser')
      .eq('user_id', user.id)
      .single();

    const { data: superuserCheck } = await supabaseAdmin
      .from('superusers')
      .select('user_id')
      .eq('user_id', user.id)
      .maybeSingle();

    const isSuperuser = callerVaishnava?.is_superuser || !!superuserCheck;

    if (!isSuperuser) {
      // Проверяем permission manage_users
      const { data: hasPermission } = await supabaseAdmin.rpc('has_permission', {
        user_uuid: user.id,
        perm_code: 'manage_users'
      });

      if (!hasPermission) {
        return new Response(
          JSON.stringify({ error: 'Insufficient permissions' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Получаем данные запроса
    const { email, vaishnavId } = await req.json();

    if (!email) {
      return new Response(
        JSON.stringify({ error: 'Email is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Проверяем, что профиль существует и приглашение отправляется именно
    // на сохранённый в нём адрес.
    const { data: vaishnava, error: vaishError } = await supabaseAdmin
      .from('vaishnavas')
      .select('id, email, user_id, spiritual_name, first_name')
      .eq('id', vaishnavId)
      .single();

    if (vaishError || !vaishnava) {
      return new Response(
        JSON.stringify({ error: 'Vaishnava not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const profileEmail = String(vaishnava.email ?? '').trim().toLowerCase();

    if (!profileEmail || normalizedEmail !== profileEmail) {
      return new Response(
        JSON.stringify({ error: 'Email does not match the selected profile' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const redirectUrl = `${SITE_URL}/guest-portal/auth-callback/`;

    // Supabase не позволяет повторно пригласить уже созданного пользователя.
    // Для связанного/подтверждённого аккаунта отправляем новую recovery-ссылку.
    if (vaishnava.user_id) {
      const { error: recoveryError } = await supabaseAdmin.auth.resetPasswordForEmail(
        normalizedEmail,
        { redirectTo: redirectUrl }
      );

      if (recoveryError) {
        console.error('Recovery link error:', recoveryError);
        return new Response(
          JSON.stringify({ error: recoveryError.message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      return new Response(
        JSON.stringify({ success: true, mode: 'recovery', message: 'Access link sent successfully' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Истёкшее приглашение оставляет в Auth неподтверждённую запись. Удаляем
    // только такую неподтверждённую и непривязанную запись, затем создаём
    // полноценное новое приглашение.
    const { data: usersPage, error: usersError } = await supabaseAdmin.auth.admin.listUsers({
      page: 1,
      perPage: 1000
    });

    if (usersError) {
      console.error('List users error:', usersError);
      return new Response(
        JSON.stringify({ error: usersError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const existingAuthUser = usersPage.users.find(
      existing => existing.email?.trim().toLowerCase() === normalizedEmail
    );

    if (existingAuthUser?.email_confirmed_at) {
      const { error: recoveryError } = await supabaseAdmin.auth.resetPasswordForEmail(
        normalizedEmail,
        { redirectTo: redirectUrl }
      );

      if (recoveryError) {
        console.error('Recovery link error:', recoveryError);
        return new Response(
          JSON.stringify({ error: recoveryError.message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      return new Response(
        JSON.stringify({ success: true, mode: 'recovery', message: 'Access link sent successfully' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (existingAuthUser) {
      const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(existingAuthUser.id);
      if (deleteError) {
        console.error('Delete stale invite error:', deleteError);
        return new Response(
          JSON.stringify({ error: deleteError.message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Отправляем новое приглашение (создаст пользователя, если его ещё нет).
    const { error: inviteError } = await supabaseAdmin.auth.admin.inviteUserByEmail(normalizedEmail, {
      redirectTo: redirectUrl,
      data: {
        vaishnava_id: vaishnavId,
        full_name: vaishnava.spiritual_name || `${vaishnava.first_name || ''}`
      }
    });

    if (inviteError) {
      console.error('Invite error:', inviteError);
      return new Response(
        JSON.stringify({ error: inviteError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        mode: existingAuthUser ? 'reinvite' : 'invite',
        message: 'Invite sent successfully'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Function error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
