import { Router, Request, Response } from 'express';
import passport from 'passport';

const router = Router();

// Initiate Google OAuth
router.get(
  '/google',
  passport.authenticate('google', {
    scope: ['profile', 'email'],
    prompt: 'select_account',
  })
);

// Google OAuth callback
router.get(
  '/google/callback',
  passport.authenticate('google', {
    failureRedirect: `${process.env.FRONTEND_URL || 'http://localhost:5173'}/login?error=auth_failed`,
  }),
  (_req: Request, res: Response) => {
    res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:5173'}/dashboard`);
  }
);

// Get current user
router.get('/me', (req: Request, res: Response) => {
  if (req.isAuthenticated() && req.user) {
    const user = req.user as {
      id: string;
      email: string;
      name: string;
      avatar: string | null;
      monthlyIncome: number;
    };
    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      avatar: user.avatar,
      monthlyIncome: user.monthlyIncome,
    });
  } else {
    res.status(401).json({ error: 'Not authenticated' });
  }
});

// Logout
router.post('/logout', (req: Request, res: Response) => {
  req.logout((err) => {
    if (err) {
      res.status(500).json({ error: 'Logout failed' });
      return;
    }
    req.session.destroy(() => {
      res.clearCookie('connect.sid');
      res.json({ success: true });
    });
  });
});

export default router;
