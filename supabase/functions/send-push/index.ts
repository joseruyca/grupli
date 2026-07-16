import { createClient } from 'npm:@supabase/supabase-js@2'
import { create, getNumericDate } from 'https://deno.land/x/djwt@v3.0.2/mod.ts'

type NotificationRecord = {
  id: string
  user_id: string
  group_id?: string | null
  actor_id?: string | null
  type?: string | null
  title: string
  body: string
  route_type?: string | null
  route_id?: string | null
}

type WebhookPayload = {
  type?: 'INSERT' | 'UPDATE' | 'DELETE'
  table?: string
  record?: NotificationRecord
  old_record?: NotificationRecord | null
  notification_id?: string
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const firebaseProjectId = Deno.env.get('FIREBASE_PROJECT_ID') ?? ''
const firebaseClientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL') ?? ''
const firebasePrivateKey = (Deno.env.get('FIREBASE_PRIVATE_KEY') ?? '').replace(/\\n/g, '\n')

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
})

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    if (!supabaseUrl || !serviceRoleKey || !firebaseProjectId || !firebaseClientEmail || !firebasePrivateKey) {
      throw new Error('Missing Supabase/Firebase Edge Function secrets')
    }

    const payload = await req.json().catch(() => ({})) as WebhookPayload
    const notificationId = payload.record?.id ?? payload.notification_id
    if (!notificationId) throw new Error('Missing notification id')

    const { data: notification, error: notificationError } = await supabase
      .from('notifications')
      .select('*')
      .eq('id', notificationId)
      .single<NotificationRecord>()

    if (notificationError || !notification) throw notificationError ?? new Error('Notification not found')
    if (!['pending', 'failed', 'partial'].includes(notification.push_status ?? 'pending')) {
      return json({ ok: true, skipped: true, reason: 'already_sent', status: notification.push_status ?? null })
    }

    const { data: settings } = await supabase
      .from('user_settings')
      .select('push_enabled')
      .eq('user_id', notification.user_id)
      .maybeSingle()

    if (settings?.push_enabled === false) {
      await markNotification(notification.id, 'skipped', 0, 'Push disabled by user')
      return json({ ok: true, skipped: true, reason: 'push_disabled' })
    }

    const { data: devices, error: devicesError } = await supabase
      .from('user_devices')
      .select('id,fcm_token,platform,enabled')
      .eq('user_id', notification.user_id)
      .eq('enabled', true)

    if (devicesError) throw devicesError
    if (!devices || devices.length === 0) {
      await markNotification(notification.id, 'skipped', 0, 'No enabled devices')
      return json({ ok: true, skipped: true, reason: 'no_devices' })
    }

    const accessToken = await getAccessToken()
    const results = []
    for (const device of devices) {
      const result = await sendToFcm(accessToken, notification, device.fcm_token)
      results.push({ device_id: device.id, ok: result.ok, status: result.status, body: result.body })
      if (!result.ok && shouldDisableToken(result.body)) {
        await supabase.from('user_devices').update({
          enabled: false,
          disabled_at: new Date().toISOString(),
          last_error: result.body,
        }).eq('id', device.id)
      }
    }

    const sent = results.filter((r) => r.ok).length
    const failed = results.length - sent
    const status = sent === results.length ? 'sent' : sent > 0 ? 'partial' : 'failed'
    await markNotification(notification.id, status, results.length, failed ? JSON.stringify(results.filter((r) => !r.ok)).slice(0, 900) : null)

    return json({ ok: sent > 0, sent, failed, results })
  } catch (error) {
    return json({ ok: false, error: String(error?.message ?? error) }, 500)
  }
})

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function markNotification(id: string, status: string, attempts: number, error: string | null) {
  await supabase.from('notifications').update({
    push_status: status,
    push_sent_at: status === 'sent' || status === 'partial' ? new Date().toISOString() : null,
    push_error: error,
    push_attempts: attempts,
  }).eq('id', id)
}

async function getAccessToken() {
  const key = await importPrivateKey(firebasePrivateKey)
  const assertion = await create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: firebaseClientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: getNumericDate(0),
      exp: getNumericDate(3600),
    },
    key,
  )

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  })

  const body = await res.json()
  if (!res.ok || !body.access_token) throw new Error(`Google auth failed: ${JSON.stringify(body)}`)
  return body.access_token as string
}

async function importPrivateKey(pem: string) {
  const clean = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  const binary = Uint8Array.from(atob(clean), (c) => c.charCodeAt(0))
  return crypto.subtle.importKey(
    'pkcs8',
    binary.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )
}

async function sendToFcm(accessToken: string, notification: NotificationRecord, token: string) {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          notification_id: notification.id,
          type: notification.type ?? 'general',
          group_id: notification.group_id ?? '',
          route_type: notification.route_type ?? '',
          route_id: notification.route_id ?? '',
        },
        android: {
          priority: 'HIGH',
          notification: {
            channel_id: 'grupli_general',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      },
    }),
  })

  const body = await res.text()
  return { ok: res.ok, status: res.status, body }
}

function shouldDisableToken(body: string) {
  return body.includes('UNREGISTERED') || body.includes('INVALID_ARGUMENT') || body.includes('not a valid FCM registration token')
}
