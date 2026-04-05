import { useLocation, useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { HugeiconsIcon } from '@hugeicons/react';
import {
  PlusSignIcon,
  DashboardSquare01Icon,
  Message01Icon,
  UserIcon,
  Wallet02Icon,
} from '@hugeicons/core-free-icons';

interface NavProps {
  onAddClick?: () => void;
}

const NAV_ITEMS = [
  { path: '/dashboard', icon: DashboardSquare01Icon, label: 'דשבורד' },
  { path: '/chat', icon: Message01Icon, label: 'AI' },
  { path: '/profile', icon: UserIcon, label: 'פרופיל' },
];

export default function Navigation({ onAddClick }: NavProps) {
  const location = useLocation();
  const navigate = useNavigate();

  return (
    <>
      {/* Mobile bottom nav */}
      <nav
        className="md:hidden fixed bottom-0 left-0 right-0 z-50 border-t border-border bg-background/90 backdrop-blur-md"
        style={{ height: 'var(--nav-height)' }}
      >
        <div className="grid grid-cols-5 h-full items-center px-2">
          <NavBtn icon={DashboardSquare01Icon} label="דשבורד" active={location.pathname === '/dashboard'} onClick={() => navigate('/dashboard')} />
          <NavBtn icon={Message01Icon} label="AI" active={location.pathname === '/chat'} onClick={() => navigate('/chat')} />

          <div className="flex justify-center">
            <Button
              size="icon"
              className="h-12 w-12 rounded-2xl shadow-lg"
              onClick={onAddClick || (() => navigate('/dashboard'))}
            >
              <HugeiconsIcon icon={PlusSignIcon} strokeWidth={2} />
            </Button>
          </div>

          <NavBtn icon={UserIcon} label="פרופיל" active={location.pathname === '/profile'} onClick={() => navigate('/profile')} />
          <div />
        </div>
      </nav>

      {/* Desktop sidebar */}
      <nav className="hidden md:flex fixed right-0 top-0 h-full w-16 z-50 flex-col items-center py-4 gap-2 border-l border-border bg-background/90 backdrop-blur-md">
        <div
          className="w-9 h-9 rounded-xl bg-primary flex items-center justify-center mb-3 cursor-pointer"
          onClick={() => navigate('/dashboard')}
        >
          <HugeiconsIcon icon={Wallet02Icon} strokeWidth={2} className="size-4 text-primary-foreground" />
        </div>

        {NAV_ITEMS.map(item => (
          <Button
            key={item.path}
            variant={location.pathname === item.path ? 'secondary' : 'ghost'}
            size="icon"
            className="w-10 h-10 rounded-xl"
            title={item.label}
            onClick={() => navigate(item.path)}
          >
            <HugeiconsIcon icon={item.icon} strokeWidth={2} />
          </Button>
        ))}

        <div className="flex-1" />

        <Button
          size="icon"
          className="w-10 h-10 rounded-xl"
          title="הוסף הוצאה"
          onClick={onAddClick || (() => navigate('/dashboard'))}
        >
          <HugeiconsIcon icon={PlusSignIcon} strokeWidth={2} />
        </Button>
      </nav>
    </>
  );
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function NavBtn({ icon, label, active, onClick }: { icon: any; label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={cn(
        'flex flex-col items-center justify-center gap-1 py-1 rounded-xl transition-colors w-full',
        active ? 'text-foreground' : 'text-muted-foreground'
      )}
    >
      <HugeiconsIcon icon={icon} strokeWidth={2} className="size-5" />
      <span className="text-[10px] font-medium">{label}</span>
    </button>
  );
}
