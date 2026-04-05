import { CATEGORIES, formatCurrency } from '../utils/api';

interface Props {
  byCategory: Record<string, number>;
}

export default function CategoryChart({ byCategory }: Props) {
  const entries = CATEGORIES
    .filter(cat => byCategory[cat.id] > 0)
    .map(cat => ({ ...cat, amount: byCategory[cat.id] }))
    .sort((a, b) => b.amount - a.amount);

  if (entries.length === 0) return null;

  const max = Math.max(...entries.map(e => e.amount));

  return (
    <div className="space-y-3">
      {entries.map((cat, i) => (
        <div key={cat.id} style={{ animationDelay: `${i * 0.05}s` }} className="animate-fade-in">
          <div className="flex items-center justify-between mb-1.5">
            <div className="flex items-center gap-2">
              <span className="text-base">{cat.icon}</span>
              <span className="text-sm text-muted-foreground">{cat.label}</span>
            </div>
            <span className="text-sm font-semibold">{formatCurrency(cat.amount)}</span>
          </div>
          <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-700"
              style={{
                width: `${(cat.amount / max) * 100}%`,
                background: cat.color,
              }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}
