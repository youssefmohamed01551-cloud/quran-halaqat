import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type InsightRequest = {
  studentId: string;
  fromDate?: string;
  toDate?: string;
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const modelGatewayUrl = Deno.env.get("MODEL_GATEWAY_URL");
const modelGatewayKey = Deno.env.get("MODEL_GATEWAY_KEY");

const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false },
});

serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const { studentId, fromDate, toDate } = (await req.json()) as InsightRequest;
  if (!studentId) return json({ error: "studentId is required" }, 400);

  const periodStart = fromDate ?? dateDaysAgo(60);
  const periodEnd = toDate ?? new Date().toISOString().slice(0, 10);

  const student = await single("students", "id, organization_id, full_name, level", "id", studentId);
  const memorization = await list("daily_memorization_records", studentId, "record_date", periodStart, periodEnd);
  const attendance = await list("attendance_records", studentId, "attendance_date", periodStart, periodEnd);
  const weekly = await list("weekly_evaluations", studentId, "week_start", periodStart, periodEnd);

  const deterministicInsight = analyze(student, memorization, attendance, weekly);
  const aiInsight = modelGatewayUrl
    ? await enrichWithModelGateway(deterministicInsight, { student, memorization, attendance, weekly })
    : deterministicInsight;

  const { data, error } = await admin
    .from("ai_insights")
    .insert({
      organization_id: student.organization_id,
      student_id: studentId,
      insight_type: "performance_review",
      summary: aiInsight.summary,
      recommendations: aiInsight.recommendations,
      confidence: aiInsight.confidence,
    })
    .select("*")
    .single();

  if (error) return json({ error: error.message }, 500);
  return json({ ok: true, insight: data });
});

async function single(table: string, select: string, column: string, value: string) {
  const { data, error } = await admin.from(table).select(select).eq(column, value).single();
  if (error) throw error;
  return data;
}

async function list(table: string, studentId: string, dateColumn: string, fromDate: string, toDate: string) {
  const { data, error } = await admin
    .from(table)
    .select("*")
    .eq("student_id", studentId)
    .gte(dateColumn, fromDate)
    .lte(dateColumn, toDate);

  if (error) throw error;
  return data ?? [];
}

function analyze(student: any, memorization: any[], attendance: any[], weekly: any[]) {
  const avgMastery = average(memorization.map((row) => Number(row.mastery_percent ?? 0)));
  const avgWeekly = average(weekly.map((row) => Number(row.percentage ?? 0)));
  const attendancePercent = attendance.length === 0
    ? 0
    : (attendance.filter((row) => row.status === "present" || row.status === "late").length / attendance.length) * 100;
  const errors = memorization.reduce((sum, row) => sum + Number(row.total_mistakes ?? 0), 0);

  const recommendations = [];
  if (avgMastery < 70) {
    recommendations.push({
      type: "review_plan",
      priority: "high",
      text: "زيادة المراجعة اليومية وتقليل مقدار الحفظ الجديد حتى ترتفع نسبة الإتقان.",
    });
  }
  if (attendancePercent < 85) {
    recommendations.push({
      type: "attendance",
      priority: "medium",
      text: "تفعيل تنبيه ولي الأمر عند الغياب ومتابعة أسباب الانقطاع.",
    });
  }
  if (errors > memorization.length * 3) {
    recommendations.push({
      type: "tajweed",
      priority: "medium",
      text: "إضافة اختبار قصير في مواضع الأخطاء المتكررة قبل الانتقال لمقطع جديد.",
    });
  }
  if (recommendations.length === 0) {
    recommendations.push({
      type: "encouragement",
      priority: "low",
      text: "المستوى مستقر، يوصى بالمحافظة على الخطة الحالية مع تحد أسبوعي خفيف.",
    });
  }

  return {
    summary: `تحليل ${student.full_name}: متوسط الإتقان ${round(avgMastery)}%، الحضور ${round(attendancePercent)}%، ومتوسط التقييم الأسبوعي ${round(avgWeekly)}%.`,
    recommendations,
    confidence: 0.82,
  };
}

async function enrichWithModelGateway(baseInsight: any, evidence: Record<string, unknown>) {
  const response = await fetch(modelGatewayUrl!, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: modelGatewayKey ? `Bearer ${modelGatewayKey}` : "",
    },
    body: JSON.stringify({
      task: "quran_student_performance_analysis",
      language: "ar",
      baseInsight,
      evidence,
      outputSchema: {
        summary: "string",
        recommendations: "array",
        confidence: "number 0..1",
      },
    }),
  });

  if (!response.ok) return baseInsight;
  return await response.json();
}

function average(values: number[]) {
  if (values.length === 0) return 0;
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function round(value: number) {
  return Math.round(value * 100) / 100;
}

function dateDaysAgo(days: number) {
  const date = new Date();
  date.setDate(date.getDate() - days);
  return date.toISOString().slice(0, 10);
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
