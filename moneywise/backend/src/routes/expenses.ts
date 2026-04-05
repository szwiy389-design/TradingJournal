import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { requireAuth } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

// GET /api/expenses?month=X&year=Y
router.get('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const now = new Date();
    const month = parseInt((req.query.month as string) || String(now.getMonth() + 1), 10);
    const year = parseInt((req.query.year as string) || String(now.getFullYear()), 10);

    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const expenses = await prisma.expense.findMany({
      where: {
        userId,
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: { date: 'desc' },
    });

    res.json(expenses);
  } catch (error) {
    console.error('Error fetching expenses:', error);
    res.status(500).json({ error: 'Failed to fetch expenses' });
  }
});

// POST /api/expenses
router.post('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const { description, amount, category, date } = req.body;

    if (!description || !amount || !category) {
      res.status(400).json({ error: 'Missing required fields' });
      return;
    }

    if (typeof amount !== 'number' || amount <= 0) {
      res.status(400).json({ error: 'Amount must be a positive number' });
      return;
    }

    const validCategories = [
      'food', 'transport', 'shopping', 'bills',
      'entertainment', 'health', 'education', 'other',
    ];
    if (!validCategories.includes(category)) {
      res.status(400).json({ error: 'Invalid category' });
      return;
    }

    const expense = await prisma.expense.create({
      data: {
        userId,
        description: String(description).trim().substring(0, 200),
        amount: Number(amount),
        category,
        date: date ? new Date(date) : new Date(),
      },
    });

    res.status(201).json(expense);
  } catch (error) {
    console.error('Error creating expense:', error);
    res.status(500).json({ error: 'Failed to create expense' });
  }
});

// DELETE /api/expenses/:id
router.delete('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const id = String(req.params.id);

    const expense = await prisma.expense.findUnique({ where: { id } });

    if (!expense) {
      res.status(404).json({ error: 'Expense not found' });
      return;
    }

    if (expense.userId !== userId) {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }

    await prisma.expense.delete({ where: { id } });
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting expense:', error);
    res.status(500).json({ error: 'Failed to delete expense' });
  }
});

// GET /api/expenses/export?month=X&year=Y - Export as CSV
router.get('/export', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const now = new Date();
    const month = parseInt((req.query.month as string) || String(now.getMonth() + 1), 10);
    const year = parseInt((req.query.year as string) || String(now.getFullYear()), 10);

    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const expenses = await prisma.expense.findMany({
      where: { userId, date: { gte: startDate, lte: endDate } },
      orderBy: { date: 'desc' },
    });

    const categoryLabels: Record<string, string> = {
      food: 'אוכל', transport: 'תחבורה', shopping: 'קניות',
      bills: 'חשבונות', entertainment: 'בילויים', health: 'בריאות',
      education: 'לימודים', other: 'אחר',
    };

    const csvHeader = 'תיאור,סכום,קטגוריה,תאריך\n';
    const csvRows = expenses
      .map((e) => {
        const dateStr = new Date(e.date).toLocaleDateString('he-IL');
        return `"${e.description}",${e.amount},"${categoryLabels[e.category] || e.category}","${dateStr}"`;
      })
      .join('\n');

    const csv = '\uFEFF' + csvHeader + csvRows; // BOM for Hebrew in Excel

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="moneywise-${year}-${month}.csv"`
    );
    res.send(csv);
  } catch (error) {
    console.error('Error exporting expenses:', error);
    res.status(500).json({ error: 'Failed to export expenses' });
  }
});

export default router;
