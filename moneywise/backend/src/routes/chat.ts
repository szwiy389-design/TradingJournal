import { Router, Request, Response } from 'express';
import Anthropic from '@anthropic-ai/sdk';
import { PrismaClient } from '@prisma/client';
import { requireAuth } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();
const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const SYSTEM_PROMPT = `אתה יועץ פיננסי חכם וידידותי בשם MoneyWise AI. תפקידך לעזור למשתמש לחסוך כסף ולנהל את הכספים שלו בצורה חכמה.

כשהמשתמש מזכיר הוצאה או מוצר, הצע חלופות זולות יותר עם מחירים משוערים בישראל.
כשהוא שואל שאלות על כספים, ענה בקצרה ובצורה פרקטית.
השתמש בנתוני ההוצאות שסיפקתי לך כדי לתת עצות מותאמות אישית.
דבר בעברית בלבד.
היה ישיר ותכליתי.
השתמש באמוג'ים מדי פעם להוסיף חיות לשיחה.
אל תהיה מרצה - היה חבר שמבין כספים.`;

// POST /api/chat - Send message (streaming)
router.post('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const { message } = req.body;

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      res.status(400).json({ error: 'Message is required' });
      return;
    }

    const cleanMessage = message.trim().substring(0, 2000);

    // Get recent expenses for context
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const recentExpenses = await prisma.expense.findMany({
      where: { userId, date: { gte: startOfMonth } },
      orderBy: { date: 'desc' },
      take: 30,
    });

    const user = await prisma.user.findUnique({ where: { id: userId } });

    // Get chat history (last 10 messages)
    const history = await prisma.message.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
      take: 20,
    });

    // Build context about user's finances
    const categoryLabels: Record<string, string> = {
      food: 'אוכל', transport: 'תחבורה', shopping: 'קניות',
      bills: 'חשבונות', entertainment: 'בילויים', health: 'בריאות',
      education: 'לימודים', other: 'אחר',
    };

    const totalSpent = recentExpenses.reduce((sum, e) => sum + e.amount, 0);
    const expensesByCategory = recentExpenses.reduce((acc, e) => {
      acc[e.category] = (acc[e.category] || 0) + e.amount;
      return acc;
    }, {} as Record<string, number>);

    const categoryBreakdown = Object.entries(expensesByCategory)
      .map(([cat, amount]) => `${categoryLabels[cat] || cat}: ₪${amount.toFixed(0)}`)
      .join(', ');

    const financialContext = user
      ? `\n\n[מידע על המשתמש החודש הנוכחי]
הכנסה חודשית: ₪${user.monthlyIncome.toFixed(0)}
סך הוצאות החודש: ₪${totalSpent.toFixed(0)}
יתרה: ₪${(user.monthlyIncome - totalSpent).toFixed(0)}
פירוט לפי קטגוריה: ${categoryBreakdown || 'אין הוצאות עדיין'}
הוצאות אחרונות: ${recentExpenses
          .slice(0, 5)
          .map((e) => `${e.description} (₪${e.amount})`)
          .join(', ') || 'אין'}`
      : '';

    // Save user message
    await prisma.message.create({
      data: { userId, role: 'user', content: cleanMessage },
    });

    // Build messages for Anthropic
    const messages: Array<{ role: 'user' | 'assistant'; content: string }> = [
      ...history.map((m) => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      })),
      { role: 'user', content: cleanMessage },
    ];

    // Set up SSE streaming
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('X-Accel-Buffering', 'no');
    res.flushHeaders();

    let fullContent = '';

    const stream = anthropic.messages.stream({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      system: SYSTEM_PROMPT + financialContext,
      messages,
    });

    stream.on('text', (text: string) => {
      fullContent += text;
      res.write(`data: ${JSON.stringify({ text })}\n\n`);
    });

    stream.on('error', (error: Error) => {
      console.error('Stream error:', error);
      res.write(`data: ${JSON.stringify({ error: 'שגיאה בחיבור ל-AI' })}\n\n`);
      res.end();
    });

    await stream.finalMessage();

    // Save AI response to DB
    await prisma.message.create({
      data: { userId, role: 'assistant', content: fullContent },
    });

    res.write('data: [DONE]\n\n');
    res.end();
  } catch (error) {
    console.error('Chat error:', error);
    if (!res.headersSent) {
      res.status(500).json({ error: 'Failed to process message' });
    } else {
      res.write(`data: ${JSON.stringify({ error: 'שגיאה פנימית' })}\n\n`);
      res.end();
    }
  }
});

// GET /api/chat/history
router.get('/history', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const messages = await prisma.message.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
      take: 50,
    });
    res.json(messages);
  } catch (error) {
    console.error('Error fetching chat history:', error);
    res.status(500).json({ error: 'Failed to fetch chat history' });
  }
});

// DELETE /api/chat/history - Clear chat history
router.delete('/history', requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    await prisma.message.deleteMany({ where: { userId } });
    res.json({ success: true });
  } catch (error) {
    console.error('Error clearing chat history:', error);
    res.status(500).json({ error: 'Failed to clear chat history' });
  }
});

export default router;
