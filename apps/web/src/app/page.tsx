import { apiBaseUrl } from '@/lib/apiBaseUrl.ts';

export default function HomePage() {
  const api = apiBaseUrl(process.env.NEXT_PUBLIC_API_URL);

  return (
    <main className="mx-auto flex max-w-2xl flex-col gap-6 px-6 py-16">
      <h1 className="text-3xl font-semibold tracking-tight">FlowWave</h1>
      <p className="text-lg text-slate-700 dark:text-slate-300">
        The web panel for your personal energy and focus rhythm is under construction.
      </p>
      <p className="text-sm text-slate-600 dark:text-slate-400">
        FlowWave estimates are personal rhythm estimates based on the data you choose to share. They are not
        medical assessments or diagnoses.
      </p>
      <p className="text-xs text-slate-500">
        API: <code>{api.ok ? api.url : 'not configured'}</code>
      </p>
    </main>
  );
}
