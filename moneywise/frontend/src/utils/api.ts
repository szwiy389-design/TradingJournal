import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '',
  withCredentials: true,
  headers: { 'Content-Type': 'application/json' },
});

export default api;

// ──────────────── Types ────────────────

export interface Expense {
  id: string;
  userId: string;
  description: string;
  amount: number;
  category: string;
  date: string;
  createdAt: string;
}

export interface Stats {
  month: number;
  year: number;
  totalExpenses: number;
  monthlyIncome: number;
  remaining: number;
  byCategory: Record<string, number>;
  countByCategory: Record<string, number>;
  dailyTotals: { day: number; amount: number }[];
  transactionCount: number;
}

export interface ChatMessage {
  id: string;
  userId: string;
  role: 'user' | 'assistant';
  content: string;
  createdAt: string;
}

// ──────────────── Category helpers ────────────────

export const CATEGORIES: {
  id: string;
  label: string;
  icon: string;
  color: string;
}[] = [
  { id: 'food', label: 'אוכל', icon: '🍕', color: '#FF6B6B' },
  { id: 'transport', label: 'תחבורה', icon: '🚗', color: '#FFB347' },
  { id: 'shopping', label: 'קניות', icon: '🛍️', color: '#9B59B6' },
  { id: 'bills', label: 'חשבונות', icon: '📄', color: '#3498DB' },
  { id: 'entertainment', label: 'בילויים', icon: '🎬', color: '#E74C3C' },
  { id: 'health', label: 'בריאות', icon: '💊', color: '#2ECC71' },
  { id: 'education', label: 'לימודים', icon: '📚', color: '#1ABC9C' },
  { id: 'other', label: 'אחר', icon: '📌', color: '#95A5A6' },
];

export const getCategoryInfo = (id: string) =>
  CATEGORIES.find((c) => c.id === id) || CATEGORIES[7];

// ──────────────── Formatting ────────────────

export const formatCurrency = (amount: number): string =>
  `₪${amount.toLocaleString('he-IL', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  })}`;

export const formatDate = (dateStr: string): string => {
  const d = new Date(dateStr);
  return d.toLocaleDateString('he-IL', {
    day: 'numeric',
    month: 'short',
  });
};

export const MONTH_NAMES = [
  'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
  'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
];

// ──────────────── API calls ────────────────

export const fetchExpenses = (month: number, year: number) =>
  api.get<Expense[]>(`/api/expenses?month=${month}&year=${year}`);

export const addExpense = (data: {
  description: string;
  amount: number;
  category: string;
  date: string;
}) => api.post<Expense>('/api/expenses', data);

export const deleteExpense = (id: string) =>
  api.delete(`/api/expenses/${id}`);

export const fetchStats = (month: number, year: number) =>
  api.get<Stats>(`/api/stats?month=${month}&year=${year}`);

export const updateIncome = (monthlyIncome: number) =>
  api.put('/api/user/income', { monthlyIncome });

export const fetchChatHistory = () =>
  api.get<ChatMessage[]>('/api/chat/history');

export const clearChatHistory = () =>
  api.delete('/api/chat/history');
