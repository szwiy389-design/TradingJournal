import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { LogOut, Download, Wallet } from 'lucide-react';
import Navigation from '../components/Navigation';
import { useAuth } from '../context/AuthContext';
import { updateIncome, formatCurrency } from '../utils/api';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';

export default function Profile() {
  const { user, logout, refreshUser } = useAuth();
  const navigate = useNavigate();
  const [income, setIncome] = useState(user?.monthlyIncome ? String(user.monthlyIncome) : '');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);

  const handleSaveIncome = async () => {
    const val = parseFloat(income);
    if (isNaN(val) || val < 0) return;
    setSaving(true);
    try {
      await updateIncome(val);
      await refreshUser();
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = async () => {
    setLoggingOut(true);
    await logout();
    navigate('/login');
  };

  return (
    <div className="page-content bg-background">
      <Navigation />

      <div className="max-w-lg mx-auto px-4 pt-6 pb-4 space-y-4">
        <h1 className="text-xl font-bold animate-fade-in">פרופיל</h1>

        {/* User card */}
        <Card className="border-border/60 animate-slide-up">
          <CardContent className="p-5 flex items-center gap-4">
            <Avatar className="h-16 w-16">
              <AvatarImage src={user?.avatar || ''} />
              <AvatarFallback className="text-2xl">{user?.name?.[0]}</AvatarFallback>
            </Avatar>
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-base leading-tight">{user?.name}</p>
              <p className="text-sm text-muted-foreground mt-0.5 truncate">{user?.email}</p>
              {user?.monthlyIncome && user.monthlyIncome > 0 && (
                <Badge variant="secondary" className="mt-2 gap-1.5">
                  <Wallet className="h-3 w-3" />
                  {formatCurrency(user.monthlyIncome)} / חודש
                </Badge>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Income setting */}
        <Card className="border-border/60 animate-slide-up">
          <CardHeader className="p-4 pb-2">
            <CardTitle className="text-sm">הכנסה חודשית</CardTitle>
            <CardDescription className="text-xs">משמש לחישוב היתרה החודשית</CardDescription>
          </CardHeader>
          <CardContent className="p-4 pt-2">
            <div className="flex gap-2">
              <div className="relative flex-1">
                <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">₪</span>
                <Input
                  type="number"
                  value={income}
                  onChange={e => setIncome(e.target.value)}
                  onKeyDown={e => e.key === 'Enter' && handleSaveIncome()}
                  placeholder="למשל: 12000"
                  className="pr-7 text-right"
                  dir="rtl"
                  min="0"
                />
              </div>
              <Button onClick={handleSaveIncome} disabled={saving || !income} className="min-w-[72px]">
                {saving ? (
                  <div className="w-4 h-4 rounded-full border-2 border-primary-foreground border-t-transparent" style={{ animation: 'spin 0.6s linear infinite' }} />
                ) : saved ? '✓ נשמר' : 'שמור'}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Actions */}
        <Card className="border-border/60 animate-slide-up">
          <CardContent className="p-2">
            <button
              onClick={() => window.open(`/api/expenses/export?month=${new Date().getMonth() + 1}&year=${new Date().getFullYear()}`, '_blank')}
              className="w-full flex items-center gap-3 px-3 py-3 rounded-md hover:bg-accent transition-colors text-right"
            >
              <div className="w-8 h-8 rounded-md bg-secondary flex items-center justify-center flex-shrink-0">
                <Download className="h-4 w-4 text-muted-foreground" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium">ייצוא נתונים</p>
                <p className="text-xs text-muted-foreground">הורד הוצאות החודש כ-CSV</p>
              </div>
            </button>

            <Separator className="my-1" />

            <button
              onClick={handleLogout}
              disabled={loggingOut}
              className="w-full flex items-center gap-3 px-3 py-3 rounded-md hover:bg-destructive/10 transition-colors text-right"
            >
              <div className="w-8 h-8 rounded-md bg-destructive/10 flex items-center justify-center flex-shrink-0">
                <LogOut className="h-4 w-4 text-destructive" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium text-destructive">התנתק</p>
                <p className="text-xs text-muted-foreground">{loggingOut ? 'מתנתק...' : 'צא מהחשבון'}</p>
              </div>
            </button>
          </CardContent>
        </Card>

        {/* App info */}
        <p className="text-xs text-muted-foreground text-center pb-2">MoneyWise v1.0.0</p>
      </div>
    </div>
  );
}
