const GIST_ID = process.env.GIST_ID || 'd9936181f4ec00b1e06b8a2fcb169cdc';
const GITHUB_API = 'https://api.github.com';

export default async function handler(req, res) {
  const host = req.headers.host || 'ambot-ai.vercel.app';
  const path = req.url || '/api/stats';
  const url = new URL(path, `https://${host}`);
  const token = url.searchParams.get('token');
  const expected = process.env.STATS_TOKEN;

  if (!expected) {
    return res.status(500).json({ error: 'STATS_TOKEN not configured' });
  }

  if (!token || token !== expected) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  try {
    const apiRes = await fetch(`${GITHUB_API}/gists/${GIST_ID}`, {
      headers: { 'Authorization': `token ${process.env.GITHUB_TOKEN}` },
    });
    if (!apiRes.ok) throw new Error(`GitHub API ${apiRes.status}`);
    const gist = await apiRes.json();
    const data = JSON.parse(gist.files['counter.json'].content);
    return res.status(200).json({ count: data.count || 0, updatedAt: data.updatedAt || null });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to read counter' });
  }
}
