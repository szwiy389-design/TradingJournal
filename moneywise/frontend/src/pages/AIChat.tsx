import { useState, useEffect, useRef, useCallback } from 'react';
import ReactMarkdown from 'react-markdown';
import { Send, Bot, Trash2, Sparkles } from 'lucide-react';
import Navigation from '../components/Navigation';
import { fetchChatHistory, clearChatHistory, ChatMessage } from '../utils/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';

interface LocalMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  createdAt: string;
  streaming?: boolean;
}

const QUICK_PROMPTS = [
  'איך אפשר לחסוך יותר?',
  'תנתח את ההוצאות שלי',
  'תן לי טיפים לתקציב',
  'מה ההוצאה הגדולה שלי?',
];

export default function AIChat() {
  const [messages, setMessages] = useState<LocalMessage[]>([]);
  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const [loadingHistory, setLoadingHistory] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, []);

  useEffect(() => { scrollToBottom(); }, [messages, scrollToBottom]);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetchChatHistory();
        setMessages(res.data.map((m: ChatMessage) => ({ id: m.id, role: m.role, content: m.content, createdAt: m.createdAt })));
      } finally {
        setLoadingHistory(false);
      }
    };
    load();
  }, []);

  const sendMessage = async (text?: string) => {
    const msg = (text || input).trim();
    if (!msg || sending) return;
    setInput('');
    setSending(true);

    const userMsg: LocalMessage = { id: `u-${Date.now()}`, role: 'user', content: msg, createdAt: new Date().toISOString() };
    const aiId = `a-${Date.now()}`;
    const aiMsg: LocalMessage = { id: aiId, role: 'assistant', content: '', createdAt: new Date().toISOString(), streaming: true };
    setMessages(prev => [...prev, userMsg, aiMsg]);

    try {
      const res = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ message: msg }),
      });
      const reader = res.body?.getReader();
      if (!reader) throw new Error('No reader');
      const dec = new TextDecoder();
      let full = '';
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        for (const line of dec.decode(value, { stream: true }).split('\n')) {
          if (!line.startsWith('data: ')) continue;
          const data = line.slice(6).trim();
          if (data === '[DONE]') break;
          try {
            const p = JSON.parse(data);
            if (p.text) { full += p.text; setMessages(prev => prev.map(m => m.id === aiId ? { ...m, content: full } : m)); }
          } catch { /* skip */ }
        }
      }
      setMessages(prev => prev.map(m => m.id === aiId ? { ...m, streaming: false } : m));
    } catch {
      setMessages(prev => prev.map(m => m.id === aiId ? { ...m, content: 'שגיאה. נסה שנית.', streaming: false } : m));
    } finally {
      setSending(false);
      inputRef.current?.focus();
    }
  };

  const handleClear = async () => {
    if (!confirm('למחוק את השיחה?')) return;
    await clearChatHistory();
    setMessages([]);
  };

  return (
    <div className="page-content flex flex-col bg-background" style={{ height: '100vh' }}>
      <Navigation />

      {/* Header */}
      <div className="sticky top-0 z-10 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Avatar className="h-8 w-8">
              <AvatarFallback className="bg-primary text-primary-foreground text-xs">
                <Bot className="h-4 w-4" />
              </AvatarFallback>
            </Avatar>
            <div>
              <p className="font-semibold text-sm leading-none">MoneyWise AI</p>
              <div className="flex items-center gap-1 mt-0.5">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 inline-block" />
                <span className="text-xs text-muted-foreground">{sending ? 'מקליד...' : 'מחובר'}</span>
              </div>
            </div>
          </div>
          {messages.length > 0 && (
            <Button variant="ghost" size="sm" className="gap-1.5 text-xs h-7" onClick={handleClear}>
              <Trash2 className="h-3 w-3" />
              נקה
            </Button>
          )}
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-4">
        <div className="max-w-2xl mx-auto space-y-4">
          {loadingHistory ? (
            <div className="flex justify-center py-8">
              <div className="w-5 h-5 rounded-full border-2 border-primary border-t-transparent" style={{ animation: 'spin 0.7s linear infinite' }} />
            </div>
          ) : messages.length === 0 ? (
            <div className="text-center py-10 animate-fade-in">
              <div className="w-14 h-14 rounded-2xl bg-primary/10 flex items-center justify-center mx-auto mb-4">
                <Sparkles className="h-7 w-7 text-primary" />
              </div>
              <h2 className="font-semibold mb-1">MoneyWise AI</h2>
              <p className="text-sm text-muted-foreground mb-6 max-w-xs mx-auto">
                אני יכול לנתח את ההוצאות שלך ולתת עצות חיסכון
              </p>
              <div className="grid grid-cols-2 gap-2 max-w-xs mx-auto">
                {QUICK_PROMPTS.map(p => (
                  <Button key={p} variant="outline" size="sm" className="text-xs h-auto py-2 text-right whitespace-normal" onClick={() => sendMessage(p)}>
                    {p}
                  </Button>
                ))}
              </div>
            </div>
          ) : (
            messages.map(msg => (
              <div key={msg.id} className={`flex gap-2 animate-fade-in ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                {msg.role === 'assistant' && (
                  <Avatar className="h-7 w-7 flex-shrink-0 mt-1">
                    <AvatarFallback className="bg-primary/10 text-primary text-xs">
                      <Bot className="h-3.5 w-3.5" />
                    </AvatarFallback>
                  </Avatar>
                )}
                <div className={msg.role === 'user' ? 'chat-bubble-user' : 'chat-bubble-ai'}>
                  {msg.streaming && msg.content === '' ? (
                    <div className="flex gap-1 items-center py-1">
                      <div className="typing-dot" />
                      <div className="typing-dot" />
                      <div className="typing-dot" />
                    </div>
                  ) : (
                    <div className="markdown-body">
                      <ReactMarkdown>{msg.content}</ReactMarkdown>
                      {msg.streaming && (
                        <span className="inline-block w-0.5 h-4 bg-primary align-middle animate-pulse" />
                      )}
                    </div>
                  )}
                </div>
              </div>
            ))
          )}
          <div ref={messagesEndRef} />
        </div>
      </div>

      {/* Input */}
      <div className="sticky bottom-0 border-t border-border bg-background/80 backdrop-blur-md"
        style={{ paddingBottom: 'calc(var(--nav-height) + 12px)', paddingTop: 12 }}>
        <div className="max-w-2xl mx-auto px-4 flex gap-2">
          <Input
            ref={inputRef}
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); } }}
            placeholder="שאל את MoneyWise AI..."
            disabled={sending}
            className="flex-1 text-right"
            dir="rtl"
          />
          <Button
            size="icon"
            onClick={() => sendMessage()}
            disabled={!input.trim() || sending}
          >
            {sending
              ? <div className="w-4 h-4 rounded-full border-2 border-primary-foreground border-t-transparent" style={{ animation: 'spin 0.6s linear infinite' }} />
              : <Send className="h-4 w-4" style={{ transform: 'scaleX(-1)' }} />
            }
          </Button>
        </div>
      </div>
    </div>
  );
}
