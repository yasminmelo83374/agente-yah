const DEFAULT_TIMEOUT_MS = 30_000;

async function sendCommand(apiUrl, text, actorId = "owner") {
  const response = await fetch(`${apiUrl}/commands`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ source: "whatsapp", text, actor_id: actorId }),
    signal: AbortSignal.timeout(DEFAULT_TIMEOUT_MS),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`API error: ${response.status} ${body}`);
  }

  return response.json();
}

async function approveJob(apiUrl, jobId, actorId = "owner") {
  const response = await fetch(`${apiUrl}/approvals/${jobId}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ actor_id: actorId }),
    signal: AbortSignal.timeout(DEFAULT_TIMEOUT_MS),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`API error: ${response.status} ${body}`);
  }

  return response.json();
}

async function getJob(apiUrl, jobId) {
  const response = await fetch(`${apiUrl}/jobs/${jobId}`, {
    method: "GET",
    signal: AbortSignal.timeout(DEFAULT_TIMEOUT_MS),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`API error: ${response.status} ${body}`);
  }

  return response.json();
}

async function setKillSwitch(apiUrl, enabled, actorId = "owner") {
  const response = await fetch(`${apiUrl}/control/kill-switch`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ enabled, actor_id: actorId }),
    signal: AbortSignal.timeout(DEFAULT_TIMEOUT_MS),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`API error: ${response.status} ${body}`);
  }

  return response.json();
}

module.exports = { sendCommand, approveJob, getJob, setKillSwitch };
