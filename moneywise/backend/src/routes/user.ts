import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { requireAuth } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

// PUT /api/user/income
router.put('/income', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const { monthlyIncome } = req.body;

    if (typeof monthlyIncome !== 'number' || monthlyIncome < 0) {
      res.status(400).json({ error: 'Invalid income value' });
      return;
    }

    const user = await prisma.user.update({
      where: { id: userId },
      data: { monthlyIncome },
    });

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      avatar: user.avatar,
      monthlyIncome: user.monthlyIncome,
    });
  } catch (error) {
    console.error('Error updating income:', error);
    res.status(500).json({ error: 'Failed to update income' });
  }
});

export default router;
