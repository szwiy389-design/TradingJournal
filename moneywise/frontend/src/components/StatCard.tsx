interface StatCardProps {
  label: string;
  value: string;
  icon: string;
  color: string;
  subtitle?: string;
  negative?: boolean;
}

export default function StatCard({
  label,
  value,
  icon,
  color,
  subtitle,
  negative,
}: StatCardProps) {
  return (
    <div className="stat-card">
      <div
        className="w-8 h-8 rounded-xl flex items-center justify-center text-base mb-3"
        style={{ background: `${color}18` }}
      >
        {icon}
      </div>
      <p className="text-xs mb-1.5 leading-none" style={{ color: 'rgba(255,255,255,0.45)' }}>
        {label}
      </p>
      <p
        className="font-bold leading-tight text-base"
        style={{ color: negative ? '#FF6B6B' : color }}
      >
        {value}
      </p>
      {subtitle && (
        <p className="text-xs mt-1" style={{ color: 'rgba(255,255,255,0.3)' }}>
          {subtitle}
        </p>
      )}
    </div>
  );
}
