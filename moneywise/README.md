# 💰 MoneyWise — ניהול כספים חכם עם AI

A full-stack RTL Hebrew personal finance tracker with Google OAuth and Claude AI chat.

---

## Tech Stack
- **Frontend**: React 18 + Vite + TypeScript + Tailwind CSS
- **Backend**: Node.js + Express + TypeScript
- **Database**: SQLite via Prisma ORM
- **Auth**: Google OAuth 2.0 (Passport.js)
- **AI**: Anthropic Claude API (streaming)

---

## ⚡ Quick Start

### 1. Clone & Install

```bash
# Backend
cd backend
npm install

# Frontend
cd ../frontend
npm install
```

### 2. Set Up Google OAuth Credentials

1. Go to **[Google Cloud Console](https://console.cloud.google.com/)**
2. Create a new project (or use existing)
3. Navigate to **APIs & Services → Credentials**
4. Click **"+ CREATE CREDENTIALS" → "OAuth client ID"**
5. Choose **"Web application"**
6. Set the name to "MoneyWise"
7. Under **"Authorized redirect URIs"** add:
   - `http://localhost:3001/auth/google/callback`
8. Click **Create**
9. Copy your **Client ID** and **Client Secret**

> **Also enable the API**: Go to APIs & Services → Library → search "Google+ API" or "People API" → Enable

### 3. Get Anthropic API Key

1. Go to **[console.anthropic.com](https://console.anthropic.com/)**
2. Sign in or create an account
3. Navigate to **API Keys**
4. Click **"Create Key"**
5. Copy the key (starts with `sk-ant-...`)

### 4. Configure Backend Environment

```bash
cd backend
cp .env.example .env
```

Edit `.env`:

```env
DATABASE_URL="file:./dev.db"
GOOGLE_CLIENT_ID="your-google-client-id-here"
GOOGLE_CLIENT_SECRET="your-google-client-secret-here"
ANTHROPIC_API_KEY="sk-ant-your-key-here"
SESSION_SECRET="some-long-random-string-change-this"
FRONTEND_URL="http://localhost:5173"
BACKEND_URL="http://localhost:3001"
PORT=3001
NODE_ENV=development
```

### 5. Initialize Database

```bash
cd backend
npm run setup
```

This generates the Prisma client and creates the SQLite database.

### 6. Run the App

Open **two terminals**:

**Terminal 1 — Backend:**
```bash
cd backend
npm run dev
```
Server starts at http://localhost:3001

**Terminal 2 — Frontend:**
```bash
cd frontend
npm run dev
```
App opens at http://localhost:5173

---

## 📁 Project Structure

```
moneywise/
├── backend/
│   ├── prisma/
│   │   └── schema.prisma       # Database schema
│   ├── src/
│   │   ├── middleware/
│   │   │   └── auth.ts         # Auth guard middleware
│   │   ├── routes/
│   │   │   ├── auth.ts         # Google OAuth routes
│   │   │   ├── expenses.ts     # CRUD + CSV export
│   │   │   ├── chat.ts         # AI chat (SSE streaming)
│   │   │   ├── stats.ts        # Monthly statistics
│   │   │   └── user.ts         # User profile update
│   │   └── index.ts            # Express server entry
│   ├── .env.example
│   ├── package.json
│   └── tsconfig.json
│
└── frontend/
    ├── src/
    │   ├── components/
    │   │   ├── Navigation.tsx  # Bottom nav (mobile) + sidebar (desktop)
    │   │   ├── StatCard.tsx    # Dashboard stat cards
    │   │   ├── ExpenseModal.tsx # Add expense bottom sheet
    │   │   ├── ExpenseItem.tsx  # Expense list row
    │   │   ├── CategoryChart.tsx # Horizontal bar chart
    │   │   └── MonthlyChart.tsx  # Daily spending bar chart
    │   ├── context/
    │   │   └── AuthContext.tsx  # Global auth state
    │   ├── pages/
    │   │   ├── Login.tsx        # Google sign-in page
    │   │   ├── Dashboard.tsx    # Main dashboard
    │   │   ├── AIChat.tsx       # AI advisor chat
    │   │   └── Profile.tsx      # Profile + settings
    │   ├── utils/
    │   │   └── api.ts           # Axios + API helpers + types
    │   ├── App.tsx
    │   ├── main.tsx
    │   └── index.css            # Global styles + CSS variables
    ├── index.html
    ├── vite.config.ts           # Dev proxy to backend
    ├── tailwind.config.js
    └── package.json
```

---

## 🔌 API Reference

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/auth/google` | Initiate Google OAuth |
| GET | `/auth/google/callback` | OAuth callback |
| GET | `/auth/me` | Get current user |
| POST | `/auth/logout` | Logout |
| GET | `/api/expenses?month=&year=` | Get expenses by month |
| POST | `/api/expenses` | Add expense |
| DELETE | `/api/expenses/:id` | Delete expense |
| GET | `/api/expenses/export` | Export CSV |
| PUT | `/api/user/income` | Update monthly income |
| POST | `/api/chat` | AI chat (SSE stream) |
| GET | `/api/chat/history` | Get chat history |
| DELETE | `/api/chat/history` | Clear chat history |
| GET | `/api/stats?month=&year=` | Get monthly stats |

---

## 🚀 Production Deployment

1. Build frontend: `cd frontend && npm run build`
2. Set `NODE_ENV=production` in backend `.env`
3. Update `FRONTEND_URL` and `BACKEND_URL` to your domains
4. Add production callback URL to Google Console:
   `https://yourdomain.com/auth/google/callback`
5. Serve `frontend/dist` as static files (nginx, Cloudflare Pages, etc.)
6. Run backend with `npm start` or use PM2

---

## 🎨 Design System

| Token | Value |
|-------|-------|
| Background | `#0a0a0f → #1a1a2e` gradient |
| Accent | `linear-gradient(135deg, #00d4aa, #00b4d8)` |
| Card | `rgba(255,255,255,0.04)` glass |
| Expense | `#FF6B6B` |
| Income | `#00d4aa` |
| Font | Rubik (Hebrew support) |
