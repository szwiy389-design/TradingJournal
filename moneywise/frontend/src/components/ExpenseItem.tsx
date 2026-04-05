import { Expense, getCategoryInfo, formatCurrency, formatDate } from '../utils/api';

interface Props {
  expense: Expense;
  onDelete: (id: string) => void;
  deleting: boolean;
}

export default function ExpenseItem({ expense, onDelete, deleting }: Props) {
  const cat = getCategoryInfo(expense.category);

  return (
    <div
      className="expense-item animate-slide-in"
      style={{ opacity: deleting ? 0.5 : 1, transition: 'opacity 0.2s ease' }}
    >
      {/* Category icon */}
      <div
        className="w-10 h-10 rounded-xl flex items-center justify-center text-lg flex-shrink-0"
        style={{ background: `${cat.color}18` }}
      >
        {cat.icon}
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <p className="font-medium text-sm leading-tight truncate">
          {expense.description}
        </p>
        <p className="text-xs mt-0.5" style={{ color: 'rgba(255,255,255,0.35)' }}>
          {cat.label} · {formatDate(expense.date)}
        </p>
      </div>

      {/* Amount */}
      <span className="font-bold text-sm flex-shrink-0" style={{ color: '#FF6B6B' }}>
        -{formatCurrency(expense.amount)}
      </span>

      {/* Delete */}
      <button
        onClick={() => !deleting && onDelete(expense.id)}
        disabled={deleting}
        className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 transition-all"
        style={{
          background: 'rgba(255,107,107,0.08)',
          color: 'rgba(255,107,107,0.5)',
          border: 'none',
          cursor: deleting ? 'not-allowed' : 'pointer',
        }}
        onMouseEnter={(e) => {
          if (!deleting) {
            e.currentTarget.style.background = 'rgba(255,107,107,0.18)';
            e.currentTarget.style.color = '#FF6B6B';
          }
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.background = 'rgba(255,107,107,0.08)';
          e.currentTarget.style.color = 'rgba(255,107,107,0.5)';
        }}
      >
        {deleting ? (
          <div
            className="w-3 h-3 rounded-full border border-current border-t-transparent"
            style={{ animation: 'spin 0.6s linear infinite' }}
          />
        ) : (
          <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
            <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" />
          </svg>
        )}
      </button>
    </div>
  );
}
