const GIST_ID = process.env.GIST_ID || 'd9936181f4ec00b1e06b8a2fcb169cdc';
const APK_URL = 'https://github.com/burikethhh/AmbotAI/releases/download/v1.6.3/AmbotAI-v1.6.3.apk';
const GITHUB_API = 'https://api.github.com';

async function getCounter() {
  const res = await fetch(`${GITHUB_API}/gists/${GIST_ID}`, {
    headers: { 'Authorization': `token ${process.env.GITHUB_TOKEN}` },
  });
  if (!res.ok) throw new Error(`GitHub API ${res.status}`);
  const gist = await res.json();
  const content = gist.files['counter.json'].content;
  return JSON.parse(content);
}

async function setCounter(count) {
  const data = JSON.stringify({ count, updatedAt: new Date().toISOString() });
  const res = await fetch(`${GITHUB_API}/gists/${GIST_ID}`, {
    method: 'PATCH',
    headers: {
      'Authorization': `token ${process.env.GITHUB_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ files: { 'counter.json': { content: data } } }),
  });
  if (!res.ok) throw new Error(`GitHub API ${res.status}`);
}

export default async function handler(req, res) {
  try {
    const current = await getCounter();
    await setCounter((current.count || 0) + 1);
  } catch (err) {
    console.error('Counter error:', err.message);
  }

  res.redirect(302, APK_URL);
}
