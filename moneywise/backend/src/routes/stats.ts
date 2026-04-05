import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { requireAuth } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

// GET /api/stats?month=X&year=Y
router.get('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const now = new Date();
    const month = parseInt((req.query.month as string) || String(now.getMonth() + 1), 10);
    const year = parseInt((req.query.year as string) || String(now.getFullYear()), 10);

    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const [expenses, user] = await Promise.all([
      prisma.expense.findMany({
        where: { userId, date: { gte: startDate, lte: endDate } },
        orderBy: { date: 'asc' },
      }),
      prisma.user.findUnique({ where: { id: userId } }),
    ]);

    // Total expenses
    const totalExpenses = expenses.reduce((sum, e) => sum + e.amount, 0);
    const monthlyIncome = user?.monthlyIncome || 0;
    const remaining = monthlyIncome - totalExpenses;

    // By category
    const byCategory = expenses.reduce((acc, e) => {
      acc[e.category] = (acc[e.category] || 0) + e.amount;
      return acc;
    }, {} as Record<string, number>);

    // Daily totals (for chart)
    const daysInMonth = new Date(year, month, 0).getDate();
    const dailyTotals: { day: number; amount: number }[] = [];

    for (let day = 1; day <= daysInMonth; day++) {
      const dayExpenses = expenses.filter((e) => {
        const d = new Date(e.date);
        return d.getDate() === day;
      });
      const amount = dayExpenses.reduce((sum, e) => sum + e.amount, 0);
      dailyTotals.push({ day, amount });
    }

    // Transaction count per category
    const countByCategory = expenses.reduce((acc, e) => {
      acc[e.category] = (acc[e.category] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    res.json({
      month,
      year,
      totalExpenses,
      monthlyIncome,
      remaining,
      byCategory,
      countByCategory,
      dailyTotals,
      transactionCount: expenses.length,
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

export default router;
