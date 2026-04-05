import { useState, useEffect, useRef } from 'react';
import { addExpense, CATEGORIES } from '../utils/api';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { HugeiconsIcon } from '@hugeicons/react';
import { Loading03Icon } from '@hugeicons/core-free-icons';

interface Props {
  onClose: () => void;
  onAdded: () => void;
}

export default function ExpenseModal({ onClose, onAdded }: Props) {
  const [description, setDescription] = useState('');
  const [amount, setAmount] = useState('');
  const [category, setCategory] = useState('food');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const descRef = useRef<HTMLInputElement>(null);

  useEffect(() => { setTimeout(() => descRef.current?.focus(), 150); }, []);

  const handleSubmit = async () => {
    if (!description.trim()) { setError('נא להזין תיאור'); return; }
    const amountNum = parseFloat(amount);
    if (!amount || isNaN(amountNum) || amountNum <= 0) { setError('נא להזין סכום תקין'); return; }
    setSaving(true); setError('');
    try {
      await addExpense({ description: description.trim(), amount: amountNum, category, date });
      onAdded();
    } catch {
      setError('שגיאה בשמירה. נסה שנית.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open onOpenChange={open => !open && onClose()}>
      <DialogContent className="sm:max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle>הוספת הוצאה</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 pt-2">
          {/* Description */}
          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">תיאור ההוצאה</label>
            <Input
              ref={descRef}
              value={description}
              onChange={e => setDescription(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleSubmit()}
              placeholder="לדוגמה: קפה בוקר, מכולת..."
              dir="rtl"
              className="text-right"
            />
          </div>

          {/* Amount */}
          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">סכום ב-₪</label>
            <div className="relative">
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-muted-foreground">₪</span>
              <Input
                type="number"
                value={amount}
                onChange={e => setAmount(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleSubmit()}
                placeholder="0"
                className="pr-7 text-right"
                dir="rtl"
                min="0"
              />
            </div>
          </div>

          {/* Date */}
          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">תאריך</label>
            <Input
              type="date"
              value={date}
              onChange={e => setDate(e.target.value)}
              className="text-right"
              style={{ colorScheme: 'dark' }}
            />
          </div>

          {/* Category */}
          <div className="space-y-2">
            <label className="text-sm text-muted-foreground">קטגוריה</label>
            <div className="flex flex-wrap gap-2">
              {CATEGORIES.map(cat => (
                <button
                  key={cat.id}
                  onClick={() => setCategory(cat.id)}
                  className={`category-pill ${category === cat.id ? 'selected' : ''}`}
                >
                  <span>{cat.icon}</span>
                  <span>{cat.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Error */}
          {error && (
            <p className="text-sm text-center text-destructive bg-destructive/10 rounded-md py-2 px-3">
              {error}
            </p>
          )}

          {/* Actions */}
          <div className="flex gap-2 pt-1">
            <Button variant="outline" className="flex-1" onClick={onClose}>ביטול</Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving}>
              {saving
                ? <HugeiconsIcon icon={Loading03Icon} strokeWidth={2} className="size-4 animate-spin" />
                : 'הוסף'
              }
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
