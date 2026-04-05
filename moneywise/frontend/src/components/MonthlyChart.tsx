import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';

interface Props {
  dailyTotals: { day: number; amount: number }[];
}

const CustomTooltip = ({ active, payload, label }: { active?: boolean; payload?: Array<{ value: number }>; label?: number }) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-popover border border-border rounded-md px-3 py-2 text-xs shadow-md" dir="rtl">
      <p className="text-muted-foreground mb-0.5">יום {label}</p>
      <p className="font-semibold">₪{payload[0].value.toLocaleString('he-IL')}</p>
    </div>
  );
};

export default function MonthlyChart({ dailyTotals }: Props) {
  return (
    <div style={{ height: 130 }}>
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={dailyTotals} margin={{ top: 4, right: 4, left: -28, bottom: 0 }} barSize={5}>
          <XAxis dataKey="day" tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))', fontFamily: 'inherit' }} tickLine={false} axisLine={false} interval={4} />
          <YAxis tick={{ fontSize: 10, fill: 'hsl(var(--muted-foreground))', fontFamily: 'inherit' }} tickLine={false} axisLine={false} tickFormatter={(v: number) => v === 0 ? '' : `₪${v}`} />
          <Tooltip content={<CustomTooltip />} cursor={{ fill: 'hsl(var(--accent))' }} />
          <Bar dataKey="amount" fill="hsl(var(--primary))" radius={[3, 3, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
