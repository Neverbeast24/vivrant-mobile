# VIVRΛNT Mobile REST API Specification

> Feed this document into the **viva-server** (`vivrant-server`) repo to implement the mobile REST surface consumed by the Flutter app in **vivrant-mobile**.

**Audience:** backend / Next.js engineers  
**Client:** Flutter iOS + Android (`vivrant_mobile`)  
**Base URL:** same host as VIVRΛNT Web (e.g. `https://your-app.vercel.app`)  
**Auth:** `Authorization: Bearer <supabase_access_token>` on all `/api/mobile/*` routes  
**Content-Type:** `application/json`

---

## 1. Why this exists

VIVRΛNT Web currently runs most member domain logic as **Next.js Server Actions** (cookie sessions). Native mobile cannot call Server Actions reliably. The Flutter app therefore expects a **JSON REST catalog** under `/api/mobile/*` that mirrors those actions and returns Supabase JWT sessions for auth.

Existing HTTP routes to **keep / extend**:

| Method | Path | Notes |
|--------|------|--------|
| `POST` | `/api/auth/login` | **Extend** to return `access_token` + `refresh_token` for mobile |
| `POST` | `/api/auth/signup` | Keep; return session tokens when email confirmation is off |
| `POST` | `/api/auth/forgot-password` | Keep |
| `POST` | `/api/auth/reset-password` | Keep |
| `GET` | `/api/search?q=` | Keep; accept Bearer |
| `POST`/`DELETE` | `/api/device-tokens` | Keep (already supports Bearer) |

New routes: everything under **`/api/mobile/**`** below.

---

## 2. Conventions

### 2.1 Auth

1. Mobile signs in via `POST /api/auth/login` (or signup).
2. Response **must** include Supabase session tokens (web can keep setting cookies too).
3. Subsequent requests send:

```http
Authorization: Bearer eyJhbGciOi...
```

4. Server creates a Supabase client scoped to that JWT (same pattern as `device-tokens/route.ts`).
5. Reject `profiles.status === 'suspended'` with `403` and `{ "error": "..." }`.
6. On `401`, client clears tokens and returns to login.

### 2.2 Success / error shapes

```json
{ "ok": true, "...": "payload" }
```

```json
{ "error": "Human-readable message" }
```

Use HTTP status: `400` validation, `401` auth, `403` suspended/forbidden, `404` missing, `500` unexpected.

### 2.3 IDs & dates

- Numeric row `id` values as JSON numbers.
- Timestamps ISO-8601 UTC (`logged_at`, `created_at`, …).
- Dates as `YYYY-MM-DD` (`checkin_date`, `entry_date`, `target_date`).
- Money in PHP pesos as numbers (`estimated_price`, `amount`, `monthly_health_budget`).

### 2.4 Source of truth

Reimplement by calling the **same Supabase tables + Gemini helpers** used by:

- `src/app/dashboard/**/actions.ts`
- `src/app/dashboard/**/ai-actions.ts`
- `src/lib/ai/gemini.ts`

Do **not** invent parallel schemas. Prefer extracting shared service functions from Server Actions, then wrapping them in Route Handlers.

---

## 3. Auth endpoints (extend existing)

### `POST /api/auth/login`

**Body**

```json
{ "email": "user@example.com", "password": "••••••••" }
```

**Required mobile response**

```json
{
  "ok": true,
  "user": { "id": "uuid", "email": "user@example.com" },
  "access_token": "…",
  "refresh_token": "…",
  "expires_in": 3600,
  "profile": { /* profiles row */ }
}
```

Still set cookies for the web browser if desired. Mobile ignores cookies.

### `POST /api/auth/signup`

**Body**

```json
{ "email": "…", "password": "…", "displayName": "Optional" }
```

**Response** — if session available immediately, same token fields as login; otherwise:

```json
{ "ok": true, "needs_email_confirmation": true }
```

### `POST /api/auth/forgot-password`

```json
{ "email": "…" }
```

### `POST /api/auth/reset-password`

```json
{ "password": "…" }
```

(Requires recovery session.)

### `POST /api/mobile/auth/logout`

Invalidate/refresh cleanup optional; always `{ "ok": true }`. Client deletes local tokens.

### `POST /api/mobile/auth/refresh` (recommended)

```json
{ "refresh_token": "…" }
```

Returns new `access_token` / `refresh_token`.

---

## 4. Profile, settings, today

### `GET /api/mobile/profile`

Returns `{ "profile": Profile }`.

### `PATCH /api/mobile/profile`

Body: subset of profile health fields (`display_name`, `birth_date`, `sex`, `height_cm`, `weight_kg`, `goal_weight_kg`, `activity_level`, `health_focus`, `daily_step_goal`, `daily_water_goal_ml`, `bio`, …).  
Mirrors `saveHealthProfile`.

### `PUT /api/mobile/settings/preferences`

```json
{
  "theme": "light|dark|system",
  "notifications_enabled": true,
  "weekly_report_enabled": true,
  "timezone": "Asia/Manila"
}
```

Mirrors `saveSettings` → `user_settings`.

### `POST /api/mobile/profile/avatar`

`multipart/form-data` with `file` → Firebase/Supabase `avatars` bucket. Returns `{ "avatar_url": "…" }`.

### `DELETE /api/mobile/profile/avatar`

### `GET /api/mobile/today`

Aggregate for the Today screen:

```json
{
  "checkin": { "energy": 4, "mood": 3, "steps": 4200, "water_ml": 750, "note": null },
  "calories": 1450,
  "protein_g": 90,
  "steps": 4200,
  "water_ml": 750,
  "workouts_minutes": 35,
  "active_goals": 3,
  "unread_notifications": 2
}
```

### `POST /api/mobile/today/checkin`

```json
{
  "energy": 1-5,
  "mood": 1-5,
  "steps": 0,
  "water_ml": 0,
  "sleep_minutes": 420,
  "sleep_quality": 1-5,
  "bedtime": "22:30",
  "wake_time": "06:30",
  "note": "optional"
}
```

Upsert `daily_checkins` on `(user_id, checkin_date)` — same as `saveCheckin`.

---

## 5. Nutrition

| Method | Path | Mirrors |
|--------|------|---------|
| `GET` | `/api/mobile/nutrition/meals?date=YYYY-MM-DD` | list `nutrition_logs` |
| `POST` | `/api/mobile/nutrition/meals` | `logMeal` |
| `DELETE` | `/api/mobile/nutrition/meals/:id` | `deleteMeal` |
| `POST` | `/api/mobile/nutrition/water` | `addWaterIntake` |
| `POST` | `/api/mobile/nutrition/estimate` | `estimateMealWithAi` |

**POST meal body**

```json
{
  "meal_name": "Chicken rice",
  "meal_type": "breakfast|lunch|dinner|snack",
  "calories": 520,
  "protein_g": 42,
  "carbs_g": 48,
  "fat_g": 12
}
```

**POST water**

```json
{ "ml": 250 }
```

(or `amount_ml` — accept either; web uses `amount_ml`)

**POST estimate**

```json
{ "description": "adobo with rice and egg" }
```

```json
{
  "ok": true,
  "summary": "…",
  "calories": 650,
  "protein_g": 35,
  "carbs_g": 70,
  "fat_g": 20
}
```

---

## 6. Movement

| Method | Path | Mirrors |
|--------|------|---------|
| `GET` | `/api/mobile/movement/workouts?date=` | list |
| `POST` | `/api/mobile/movement/workouts` | `logWorkout` |
| `DELETE` | `/api/mobile/movement/workouts/:id` | `deleteWorkout` |
| `POST` | `/api/mobile/movement/suggest` | `suggestWorkoutWithAi` |

**POST workout**

```json
{
  "title": "Evening run",
  "activity_type": "walk|run|strength|cycle|yoga|other",
  "duration_minutes": 30,
  "calories_burned": 280
}
```

---

## 7. Gym

| Method | Path | Mirrors |
|--------|------|---------|
| `GET` | `/api/mobile/gym` | overview stats |
| `GET` | `/api/mobile/gym/exercises?equipment=` | `gym_exercises` catalog |
| `GET` | `/api/mobile/gym/sessions` | list |
| `POST` | `/api/mobile/gym/sessions` | `logGymSession` |
| `DELETE` | `/api/mobile/gym/sessions/:id` | `deleteGymSession` |
| `GET` | `/api/mobile/gym/plans` | list |
| `POST` | `/api/mobile/gym/plans/ai` | `createAiGymPlan` |
| `DELETE` | `/api/mobile/gym/plans/:id` | `deleteGymPlan` |
| `POST` | `/api/mobile/gym/machines/recommend` | `recommendMachinesWithAi` |

**POST session**

```json
{
  "title": "Upper body",
  "focus": "full_body|strength|fat_loss|mobility|endurance|upper|lower|core",
  "duration_minutes": 55,
  "calories_burned": 320,
  "exercises": [{ "name": "Bench press", "sets": "3x8" }],
  "notes": "optional"
}
```

---

## 8. Sleep, hydration, mindfulness, journal, habits

### Sleep

- `POST /api/mobile/sleep` → `logSleep`  
  `{ "sleep_minutes", "sleep_quality", "bedtime", "wake_time", "note?" }`
- `POST /api/mobile/sleep/coach` → `coachSleep` → `{ "coaching": "…" }`

### Hydration

- `POST /api/mobile/hydration` → `{ "ml": 250 }` (adds to today’s check-in)
- `POST /api/mobile/hydration/reminders` → `scheduleHydrationReminders`

### Mindfulness

- `POST /api/mobile/mindfulness/mood` → `{ "mood": 1-5, "note?" }`
- `POST /api/mobile/mindfulness/coach` → `{ "tip": "…" }`

### Journal

- `GET /api/mobile/journal`
- `POST /api/mobile/journal` → `{ "title?", "body", "mood?", "entry_date?", "tags?" }`
- `PATCH /api/mobile/journal/:id`
- `DELETE /api/mobile/journal/:id`
- `POST /api/mobile/journal/reflect` → `reflectOnJournal`

### Habits & challenges

- `GET /api/mobile/habits` — include `done_today: boolean`
- `POST /api/mobile/habits` → `{ "title": "…" }`
- `POST /api/mobile/habits/:id/toggle` → `{ "done": true }`
- `DELETE /api/mobile/habits/:id`
- `POST /api/mobile/habits/suggest` → AI suggestions
- `GET /api/mobile/habits/challenges`
- `POST /api/mobile/habits/challenges` → `{ "title", "target_value", "unit", … }`
- `DELETE /api/mobile/habits/challenges/:id`
- `POST /api/mobile/habits/challenges/refresh`

---

## 9. Groceries & pantry

### Groceries

- `GET /api/mobile/groceries`
- `POST /api/mobile/groceries`  
  `{ "name", "quantity?", "category?", "estimated_price?" }`  
  Categories: `produce|protein|dairy|grains|pantry|snacks|drinks|household|other`
- `PATCH /api/mobile/groceries/:id` → `{ "is_checked": true }`
- `DELETE /api/mobile/groceries/:id`
- `POST /api/mobile/groceries/clear-completed`
- `POST /api/mobile/groceries/restock-pantry`
- `POST /api/mobile/groceries/plan` → `generateSmartGroceryPlan`
- `POST /api/mobile/groceries/estimate-cost` → `{ "name", "quantity?" }`
- `POST /api/mobile/groceries/plan/add` → add AI plan items to list

### Pantry

- `GET /api/mobile/pantry` (optional `?low_stock=1`, `?category=`)
- `POST /api/mobile/pantry` → `{ "name", "category", "stock_level": 0-100 }`
- `PATCH /api/mobile/pantry/:id` → `{ "stock_level": 40 }`
- `DELETE /api/mobile/pantry/:id`
- `POST /api/mobile/pantry/low-stock-to-grocery`

Low-stock threshold: **≤ 25** (same as web).

---

## 10. Spending

- `GET /api/mobile/spending` — month totals + budget remaining
- `GET /api/mobile/spending/expenses`
- `POST /api/mobile/spending/expenses`  
  `{ "title", "category": "food|fitness|supplements|wellness|other", "amount", "spent_at?" }`
- `PATCH /api/mobile/spending/expenses/:id`
- `DELETE /api/mobile/spending/expenses/:id`
- `PUT /api/mobile/spending/budget` → `{ "amount": 5000 }` → `profiles.monthly_health_budget`
- `POST /api/mobile/spending/coach`

---

## 11. Reports, AI, goals, health history

### Reports

- `GET /api/mobile/reports` — weekly aggregates (calories, workouts, spend, check-ins)
- `POST /api/mobile/reports/weekly-story` → `generateWeeklyStory`

### Ask VIVRΛNT

- `GET /api/mobile/ai/chat` → `{ "messages": [{ "id", "role": "user|viva", "content", "follow_up?" }] }`
- `POST /api/mobile/ai/chat` → `{ "question": "…" }` → returns assistant message
- `POST /api/mobile/ai/insights` → `generateInsight`
- `GET /api/mobile/ai/reminders`
- `POST /api/mobile/ai/reminders`
- `PATCH /api/mobile/ai/reminders/:id` → `{ "enabled": false }`
- `DELETE /api/mobile/ai/reminders/:id`
- `POST /api/mobile/ai/reminders/draft`
- `POST /api/mobile/ai/reminders/sync-gym-plan`

### Goals

- `GET /api/mobile/goals`
- `POST /api/mobile/goals`  
  `{ "title", "category": "nutrition|movement|sleep|mindfulness|spending|other", "target_value?", "unit?", "target_date?" }`
- `PATCH /api/mobile/goals/:id` → `{ "status"?: "active|completed|paused", "current_value"? }`
- `DELETE /api/mobile/goals/:id`
- `POST /api/mobile/goals/refresh-progress`
- `POST /api/mobile/goals/suggest`
- `POST /api/mobile/goals/accept` → accept AI suggestion payload

### Health history

- `GET /api/mobile/health-history`
- `POST /api/mobile/health-history`  
  `{ "recorded_at?", "weight_kg?", "height_cm?", "body_fat_pct?", "waist_cm?", "note?" }`
- `DELETE /api/mobile/health-history/:id`
- `POST /api/mobile/health-history/analyze`

---

## 12. Notifications, devices, support, search

### Notifications

- `GET /api/mobile/notifications`
- `POST /api/mobile/notifications/:id/read`
- `POST /api/mobile/notifications/read-all`

### Device tokens (existing)

```http
POST /api/device-tokens
Authorization: Bearer <access_token>
{ "token": "<fcm_token>", "platform": "android|ios" }
```

```http
DELETE /api/device-tokens
{ "token": "<fcm_token>" }
```

### Support

- `POST /api/mobile/support/tickets`  
  `{ "subject", "body", "category?" }` → `submitSupportTicket`
- `GET /api/mobile/support/tickets` (member’s own tickets)

### Search (existing)

```http
GET /api/search?q=chicken
Authorization: Bearer …
```

Ensure Bearer works the same as cookies.

---

## 13. Profile type (shared)

```ts
type Profile = {
  user_id: string;
  display_name: string;
  email: string;
  avatar_url: string | null;
  role: "user" | "admin" | "super_admin";
  status: "active" | "suspended";
  timezone: string;
  birth_date: string | null;
  sex: string | null;
  height_cm: number | null;
  weight_kg: number | null;
  goal_weight_kg: number | null;
  activity_level: string | null;
  health_focus: string | null;
  daily_step_goal: number;
  daily_water_goal_ml: number;
  monthly_health_budget: number | null;
  bio: string | null;
  created_at?: string;
  updated_at?: string;
};
```

---

## 14. Implementation checklist (for viva-server)

1. [ ] Create `src/lib/mobile/auth.ts` helper: Bearer → Supabase user (copy from device-tokens).
2. [ ] Extend `POST /api/auth/login` (+ signup) to return `access_token` / `refresh_token`.
3. [ ] Add `src/app/api/mobile/**/route.ts` modules grouped by domain (nutrition, movement, gym, …).
4. [ ] Extract shared domain functions from Server Actions so web + mobile share logic.
5. [ ] Wire Gemini calls through existing `src/lib/ai/gemini.ts` (never expose `GEMINI_API_KEY` to Flutter).
6. [ ] Ensure RLS still applies; never use the service role for member CRUD unless required.
7. [ ] CORS: allow mobile origins only if you add a public web wrapper; native apps don’t need browser CORS, but Expo/web builds might.
8. [ ] Document deployed base URL for Flutter `--dart-define=API_BASE_URL=…`.
9. [ ] Smoke-test each endpoint with a Bearer token from Supabase Auth.
10. [ ] Keep `/api/device-tokens` as the FCM registration path for Android/iOS.

---

## 15. Flutter client mapping

| Flutter service method | Endpoint |
|------------------------|----------|
| `VivrantApi.login` | `POST /api/auth/login` |
| `VivrantApi.getToday` | `GET /api/mobile/today` |
| `VivrantApi.logMeal` | `POST /api/mobile/nutrition/meals` |
| `VivrantApi.logWorkout` | `POST /api/mobile/movement/workouts` |
| `VivrantApi.askAi` | `POST /api/mobile/ai/chat` |
| `VivrantApi.registerDeviceToken` | `POST /api/device-tokens` |
| … | See `lib/data/vivrant_api.dart` for the full list |

Config defines:

```bash
flutter run --dart-define=API_BASE_URL=https://your-vivrant-host.vercel.app
```

Android emulator localhost → host machine: `http://10.0.2.2:3000` (default in `lib/config/env.dart`).

---

## 16. Out of scope for mobile API

- Admin console (`/admin/*`) — staff stays on web
- Marketing contact inquiries
- Firebase messaging service worker JS
- Cron secret routes (`/api/cron/reminders`) — server-only

---

## 17. Priority order (suggested)

1. Auth tokens + profile + today check-in  
2. Nutrition, movement, hydration  
3. Spending, groceries, pantry  
4. Gym sessions/plans  
5. AI chat / insights / weekly story  
6. Sleep, mindfulness, journal, habits  
7. Goals, health history, notifications, support  

Ship vertical slices so Flutter screens light up as each group lands.
