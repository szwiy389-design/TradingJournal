import { useState, useEffect, useCallback } from 'react';
import Navigation from '../components/Navigation';
import ExpenseModal from '../components/ExpenseModal';
import CategoryChart from '../components/CategoryChart';
import MonthlyChart from '../components/MonthlyChart';
import { fetchExpenses, fetchStats, deleteExpense, Expense, Stats, formatCurrency, MONTH_NAMES, getCategoryInfo } from '../utils/api';
import { useAuth } from '../context/AuthContext';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { HugeiconsIcon } from '@hugeicons/react';
import {
  PlusSignIcon,
  ArrowLeft02Icon,
  ArrowRight02Icon,
  Delete02Icon,
  ChartBarLineIcon,
  WalletAdd02Icon,
  ChartBarDecreasingIcon,
} from '@hugeicons/core-free-icons';

export default function Dashboard() {
  const { user } = useAuth();
  const now = new Date();
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [year, setYear] = useState(now.getFullYear());
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [expRes, statRes] = await Promise.all([
        fetchExpenses(month, year),
        fetchStats(month, year),
      ]);
      setExpenses(expRes.data);
      setStats(statRes.data);
    } finally {
      setLoading(false);
    }
  }, [month, year]);

  useEffect(() => { loadData(); }, [loadData]);

  const handleDelete = async (id: string) => {
    setDeletingId(id);
    try {
      await deleteExpense(id);
      setExpenses(prev => prev.filter(e => e.id !== id));
      const statRes = await fetchStats(month, year);
      setStats(statRes.data);
    } finally {
      setDeletingId(null);
    }
  };

  const prevMonth = () => { if (month === 1) { setMonth(12); setYear(y => y - 1); } else setMonth(m => m - 1); };
  const nextMonth = () => { if (month === 12) { setMonth(1); setYear(y => y + 1); } else setMonth(m => m + 1); };

  const income = stats?.monthlyIncome || 0;
  const totalExpenses = stats?.totalExpenses || 0;
  const remaining = stats?.remaining || 0;
  const spendPct = income > 0 ? Math.min(100, (totalExpenses / income) * 100) : 0;

  const formatDate = (d: string) => {
    const date = new Date(d);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    if (date.toDateString() === today.toDateString()) return 'היום';
    if (date.toDateString() === yesterday.toDateString()) return 'אתמול';
    return date.toLocaleDateString('he-IL', { day: 'numeric', month: 'short' });
  };

  return (
    <div className="page-content bg-background min-h-screen">
      <Navigation onAddClick={() => setShowModal(true)} />

      <div className="max-w-screen-xl mx-auto px-4 pt-6 pb-4 space-y-4">

        {/* ── Month header ── */}
        <div className="flex items-center justify-between animate-fade-in">
          <div>
            <h1 className="text-base font-semibold">שלום, {user?.name?.split(' ')[0]} 👋</h1>
            <p className="text-xs text-muted-foreground mt-0.5">{MONTH_NAMES[month - 1]} {year}</p>
          </div>
          <div className="flex items-center gap-1">
            <Button variant="outline" size="icon" onClick={nextMonth}>
              <HugeiconsIcon icon={ArrowLeft02Icon} strokeWidth={2} />
            </Button>
            <Button variant="outline" size="icon" onClick={prevMonth}>
              <HugeiconsIcon icon={ArrowRight02Icon} strokeWidth={2} />
            </Button>
          </div>
        </div>

        {/* ── Bento Grid ── */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 animate-slide-up">

          {/* Card 1: Monthly Chart */}
          <Card className="lg:col-span-1 flex flex-col">
            <CardHeader className="border-b border-border/50">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>היסטוריית הוצאות</CardTitle>
                  <CardDescription>6 חודשים אחרונים</CardDescription>
                </div>
                <Badge variant="secondary" className="text-xs text-emerald-400 border-emerald-400/30 bg-emerald-400/10">
                  {income > 0 ? `${spendPct.toFixed(0)}% מהתקציב` : 'החודש'}
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="flex-1 pt-4">
              {loading ? (
                <div className="h-[130px] bg-muted/30 rounded animate-pulse" />
              ) : (
                <MonthlyChart dailyTotals={stats?.dailyTotals || []} />
              )}
            </CardContent>
            <div className="grid grid-cols-2 border-t border-border/50">
              <div className="px-4 py-3 border-l border-border/50">
                <p className="text-[10px] uppercase tracking-wider text-muted-foreground mb-1">הוצאות</p>
                <p className="font-semibold text-sm">{loading ? '—' : formatCurrency(totalExpenses)}</p>
              </div>
              <div className="px-4 py-3">
                <p className="text-[10px] uppercase tracking-wider text-muted-foreground mb-1">הכנסה</p>
                <p className="font-semibold text-sm text-primary">{loading ? '—' : income > 0 ? formatCurrency(income) : 'לא הוגדר'}</p>
              </div>
            </div>
            <div className="px-4 py-3 border-t border-border/50">
              <Button className="w-full" onClick={() => setShowModal(true)}>
                <HugeiconsIcon icon={PlusSignIcon} strokeWidth={2} />
                הוסף הוצאה
              </Button>
            </div>
          </Card>

          {/* Card 2: Budget Status */}
          <Card className="lg:col-span-1 flex flex-col">
            <CardHeader className="border-b border-border/50">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>מצב תקציב</CardTitle>
                  <CardDescription>יתרה חודשית</CardDescription>
                </div>
                <div className="p-2 rounded-md bg-muted">
                  <HugeiconsIcon icon={WalletAdd02Icon} strokeWidth={2} className="size-4 text-muted-foreground" />
                </div>
              </div>
            </CardHeader>
            <CardContent className="flex-1 flex flex-col justify-center gap-4 pt-4">
              <div>
                <p className="text-xs text-muted-foreground mb-1">יתרה זמינה</p>
                <p className={`text-4xl font-bold tracking-tight ${remaining >= 0 ? 'text-foreground' : 'text-destructive'}`}>
                  {loading ? '—' : formatCurrency(remaining)}
                </p>
                {income > 0 && (
                  <Badge
                    variant="secondary"
                    className={`mt-2 text-xs ${remaining >= 0 ? 'text-emerald-400 bg-emerald-400/10 border-emerald-400/20' : 'text-destructive bg-destructive/10 border-destructive/20'}`}
                  >
                    {remaining >= 0 ? '● מצב תקין' : '● חריגה מהתקציב'}
                  </Badge>
                )}
              </div>
              {income > 0 && (
                <div>
                  <div className="flex justify-between text-xs text-muted-foreground mb-2">
                    <span>הוצאו</span>
                    <span>{spendPct.toFixed(0)}%</span>
                  </div>
                  <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-700"
                      style={{
                        width: `${spendPct}%`,
                        background: spendPct > 90 ? 'oklch(0.704 0.191 22.216)' : spendPct > 70 ? 'oklch(0.75 0.17 50)' : 'var(--chart-1)',
                      }}
                    />
                  </div>
                  <div className="flex justify-between text-xs text-muted-foreground mt-1.5">
                    <span>{formatCurrency(totalExpenses)}</span>
                    <span>{formatCurrency(income)}</span>
                  </div>
                </div>
              )}
            </CardContent>
            <div className="border-t border-border/50 px-4 py-3">
              <p className="text-xs text-muted-foreground">
                {expenses.length} עסקאות ב{MONTH_NAMES[month - 1]}
              </p>
            </div>
          </Card>

          {/* Card 3: Category Breakdown */}
          <Card className="lg:col-span-1 flex flex-col">
            <CardHeader className="border-b border-border/50">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>פירוט קטגוריות</CardTitle>
                  <CardDescription>הוצאות לפי סוג</CardDescription>
                </div>
                <div className="p-2 rounded-md bg-muted">
                  <HugeiconsIcon icon={ChartBarLineIcon} strokeWidth={2} className="size-4 text-muted-foreground" />
                </div>
              </div>
            </CardHeader>
            <CardContent className="flex-1 pt-4">
              {loading ? (
                <div className="space-y-3">
                  {[1,2,3].map(i => <div key={i} className="h-8 bg-muted/30 rounded animate-pulse" />)}
                </div>
              ) : stats && Object.keys(stats.byCategory).length > 0 ? (
                <CategoryChart byCategory={stats.byCategory} />
              ) : (
                <div className="flex flex-col items-center justify-center h-full py-8 text-center">
                  <p className="text-2xl mb-2">📊</p>
                  <p className="text-xs text-muted-foreground">אין נתונים עדיין</p>
                </div>
              )}
            </CardContent>
            {!loading && stats && (
              <div className="border-t border-border/50 px-4 py-3 text-xs text-muted-foreground">
                לא עמדת ביעדים החודש? הוסף הוצאות לתחילת המעקב.
              </div>
            )}
          </Card>

          {/* Card 4: Quick Stats */}
          <Card className="lg:col-span-1 flex flex-col">
            <CardHeader className="border-b border-border/50">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>סטטיסטיקות</CardTitle>
                  <CardDescription>מבט מהיר</CardDescription>
                </div>
                <div className="p-2 rounded-md bg-muted">
                  <HugeiconsIcon icon={ChartBarDecreasingIcon} strokeWidth={2} className="size-4 text-muted-foreground" />
                </div>
              </div>
            </CardHeader>
            <CardContent className="flex-1 pt-4 space-y-4">
              <div className="space-y-3">
                <div className="flex items-center justify-between py-2 border-b border-border/40">
                  <span className="text-xs text-muted-foreground">סה״כ הוצאות</span>
                  <span className="text-sm font-semibold">{loading ? '—' : formatCurrency(totalExpenses)}</span>
                </div>
                <div className="flex items-center justify-between py-2 border-b border-border/40">
                  <span className="text-xs text-muted-foreground">ממוצע יומי</span>
                  <span className="text-sm font-semibold">
                    {loading || !stats ? '—' : formatCurrency(Math.round(totalExpenses / now.getDate()))}
                  </span>
                </div>
                <div className="flex items-center justify-between py-2 border-b border-border/40">
                  <span className="text-xs text-muted-foreground">מספר עסקאות</span>
                  <span className="text-sm font-semibold">{loading ? '—' : expenses.length}</span>
                </div>
                <div className="flex items-center justify-between py-2">
                  <span className="text-xs text-muted-foreground">ממוצע לעסקה</span>
                  <span className="text-sm font-semibold">
                    {loading || expenses.length === 0 ? '—' : formatCurrency(Math.round(totalExpenses / expenses.length))}
                  </span>
                </div>
              </div>
            </CardContent>
            <div className="border-t border-border/50 px-4 py-3">
              <p className="text-xs text-muted-foreground">{MONTH_NAMES[month - 1]} {year}</p>
            </div>
          </Card>

        </div>

        {/* ── Bottom Row ── */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 animate-slide-up">

          {/* Add Expense card */}
          <Card className="flex flex-col">
            <CardContent className="flex-1 flex flex-col items-center justify-center gap-3 py-8">
              <button
                onClick={() => setShowModal(true)}
                className="w-12 h-12 rounded-full border-2 border-dashed border-border flex items-center justify-center hover:border-primary hover:bg-primary/5 transition-colors"
              >
                <HugeiconsIcon icon={PlusSignIcon} strokeWidth={2} className="size-5 text-muted-foreground" />
              </button>
              <div className="text-center">
                <p className="font-medium text-sm">הוספת הוצאה</p>
                <p className="text-xs text-muted-foreground mt-0.5">
                  תעד הוצאה חדשה לחשבון שלך
                </p>
              </div>
              <Button size="sm" onClick={() => setShowModal(true)}>
                הוסף עכשיו
              </Button>
            </CardContent>
          </Card>

          {/* Remaining Balance */}
          <Card className="flex flex-col">
            <CardHeader className="border-b border-border/50">
              <CardTitle>יתרה חודשית</CardTitle>
              <CardDescription>נכון להיום</CardDescription>
            </CardHeader>
            <CardContent className="flex-1 flex flex-col justify-center pt-4">
              <p className={`text-5xl font-bold tracking-tight mb-2 ${remaining >= 0 ? '' : 'text-destructive'}`}>
                {loading ? '—' : formatCurrency(Math.abs(remaining))}
              </p>
              <Badge
                variant="secondary"
                className={`w-fit text-xs ${remaining >= 0 ? 'text-emerald-400 bg-emerald-400/10 border-emerald-400/20' : 'text-destructive bg-destructive/10 border-destructive/20'}`}
              >
                {remaining >= 0 ? '● נשאר לך' : '● חרגת ב'}
              </Badge>
            </CardContent>
            <div className="border-t border-border/50 px-4 py-2 text-xs text-muted-foreground">
              <div className="flex justify-between">
                <span>הכנסה</span>
                <span>{loading ? '—' : income > 0 ? formatCurrency(income) : 'לא הוגדר'}</span>
              </div>
              <div className="flex justify-between mt-1">
                <span>הוצאות</span>
                <span>-{loading ? '—' : formatCurrency(totalExpenses)}</span>
              </div>
            </div>
          </Card>

          {/* Recent Transactions */}
          <Card className="flex flex-col">
            <CardHeader className="border-b border-border/50">
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>עסקאות אחרונות</CardTitle>
                  <CardDescription>פעילות חשבון עדכנית</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="flex-1 p-0">
              {loading ? (
                <div className="p-4 space-y-3">
                  {[1,2,3].map(i => <div key={i} className="h-10 bg-muted/30 rounded animate-pulse" />)}
                </div>
              ) : expenses.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-8 text-center px-4">
                  <p className="text-2xl mb-2">🎉</p>
                  <p className="text-sm font-medium">אין הוצאות עדיין</p>
                  <p className="text-xs text-muted-foreground mt-1">לחץ על "הוסף הוצאה" כדי להתחיל</p>
                </div>
              ) : (
                <div className="divide-y divide-border/40">
                  {expenses.slice(0, 5).map(expense => {
                    const cat = getCategoryInfo(expense.category);
                    return (
                      <div key={expense.id} className="group flex items-center gap-3 px-4 py-3 hover:bg-muted/30 transition-colors">
                        <div className="w-8 h-8 rounded-md bg-muted flex items-center justify-center text-sm flex-shrink-0">
                          {cat.icon}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-xs font-medium truncate">{expense.description}</p>
                          <p className="text-xs text-muted-foreground">{cat.label}</p>
                        </div>
                        <div className="flex items-center gap-2 flex-shrink-0">
                          <div className="text-right">
                            <p className="text-xs font-semibold">{formatCurrency(expense.amount)}</p>
                            <p className="text-[10px] text-muted-foreground">{formatDate(expense.date)}</p>
                          </div>
                          <button
                            onClick={() => handleDelete(expense.id)}
                            disabled={deletingId === expense.id}
                            className="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-destructive/10 hover:text-destructive transition-all text-muted-foreground"
                          >
                            {deletingId === expense.id
                              ? <div className="w-3 h-3 rounded-full border border-current border-t-transparent" style={{ animation: 'spin 0.6s linear infinite' }} />
                              : <HugeiconsIcon icon={Delete02Icon} strokeWidth={2} className="size-3" />
                            }
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </CardContent>
            {expenses.length > 5 && (
              <div className="border-t border-border/50 px-4 py-2">
                <p className="text-xs text-muted-foreground text-center">+{expenses.length - 5} עסקאות נוספות</p>
              </div>
            )}
          </Card>

        </div>

      </div>

      {showModal && (
        <ExpenseModal
          onClose={() => setShowModal(false)}
          onAdded={async () => { setShowModal(false); await loadData(); }}
        />
      )}
    </div>
  );
}
