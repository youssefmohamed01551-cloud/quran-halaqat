import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type NotifyRequest = {
  notificationId?: string;
  recipientProfileId?: string;
  organizationId?: string;
  title?: string;
  body?: string;
  data?: Record<string, unknown>;
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");

const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false },
});

serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const payload = (await req.json()) as NotifyRequest;
  const notification = await loadOrCreateNotification(payload);

  if (!notification) {
    return json({ error: "Missing notification data" }, 400);
  }

  const { data: devices, error: deviceError } = await admin
    .from("device_tokens")
    .select("token, platform")
    .eq("profile_id", notification.recipient_profile_id)
    .eq("is_active", true);

  if (deviceError) {
    await markFailed(notification.id, deviceError.message);
    return json({ error: deviceError.message }, 500);
  }

  if (!fcmServerKey || !devices?.length) {
    await markSent(notification.id, { skipped: true, reason: "No FCM key or devices" });
    return json({ ok: true, skipped: true });
  }

  const results = await Promise.allSettled(
    devices.map((device) =>
      fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `key=${fcmServerKey}`,
        },
        body: JSON.stringify({
          to: device.token,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: notification.data ?? {},
        }),
      })
    )
  );

  const failed = results.filter((result) => result.status === "rejected");
  if (failed.length > 0) {
    await markFailed(notification.id, `${failed.length} delivery attempts failed`);
    return json({ ok: false, failed: failed.length }, 502);
  }

  await markSent(notification.id, { delivered: devices.length });
  return json({ ok: true, delivered: devices.length });
});

async function loadOrCreateNotification(payload: NotifyRequest) {
  if (payload.notificationId) {
    const { data, error } = await admin
      .from("notifications")
      .select("*")
      .eq("id", payload.notificationId)
      .single();

    if (error) throw error;
    return data;
  }

  if (!payload.organizationId || !payload.recipientProfileId || !payload.title || !payload.body) {
    return null;
  }

  const { data, error } = await admin
    .from("notifications")
    .insert({
      organization_id: payload.organizationId,
      recipient_profile_id: payload.recipientProfileId,
      title: payload.title,
      body: payload.body,
      data: payload.data ?? {},
      channel: "push",
      status: "queued",
    })
    .select("*")
    .single();

  if (error) throw error;
  return data;
}

async function markSent(id: string, meta: Record<string, unknown>) {
  await admin
    .from("notifications")
    .update({
      status: "sent",
      sent_at: new Date().toISOString(),
      data: meta,
    })
    .eq("id", id);
}

async function markFailed(id: string, reason: string) {
  await admin
    .from("notifications")
    .update({
      status: "failed",
      data: { error: reason },
    })
    .eq("id", id);
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
