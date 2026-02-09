const API_URL = window.AGENT_API_URL || "http://localhost:8080";

const elements = {
  killStatus: document.querySelector("[data-kill-status]"),
  jobsBody: document.querySelector("[data-jobs-body]"),
  auditBody: document.querySelector("[data-audit-body]"),
  refreshBtn: document.querySelector("[data-refresh]") ,
  killOnBtn: document.querySelector("[data-kill-on]"),
  killOffBtn: document.querySelector("[data-kill-off]") ,
  apiUrl: document.querySelector("[data-api-url]") ,
};

async function apiGet(path) {
  const res = await fetch(`${API_URL}${path}`);
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

async function apiPost(path, payload) {
  const res = await fetch(`${API_URL}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

function badgeForRisk(risk) {
  if (risk === "destructive") return "danger";
  if (risk === "critical") return "warn";
  return "ok";
}

function renderKillSwitch(enabled) {
  elements.killStatus.textContent = enabled ? "ATIVO" : "DESATIVADO";
  elements.killStatus.className = `badge ${enabled ? "danger" : "ok"}`;
}

function renderJobs(jobs) {
  elements.jobsBody.innerHTML = "";

  if (!jobs.length) {
    elements.jobsBody.innerHTML = `<tr><td colspan="7">Sem jobs por enquanto.</td></tr>`;
    return;
  }

  jobs.forEach((job) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>#${job.id}</td>
      <td><span class="badge ${badgeForRisk(job.risk_level)}">${job.risk_level}</span></td>
      <td>${job.worker_type}</td>
      <td>${job.status}</td>
      <td>${job.confirmations_done}/${job.required_confirmations}</td>
      <td><small>${job.text}</small></td>
      <td>
        <div class="actions">
          <button class="ghost" data-approve="${job.id}">Aprovar</button>
          <button class="secondary" data-status="${job.id}">Status</button>
        </div>
      </td>
    `;
    elements.jobsBody.appendChild(row);
  });
}

function renderAudit(events) {
  elements.auditBody.innerHTML = "";

  if (!events.length) {
    elements.auditBody.innerHTML = `<tr><td colspan="4">Sem eventos ainda.</td></tr>`;
    return;
  }

  events.forEach((eventItem) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>#${eventItem.id}</td>
      <td>${eventItem.event_type}</td>
      <td>${eventItem.actor_id}</td>
      <td><small>${eventItem.payload}</small></td>
    `;
    elements.auditBody.appendChild(row);
  });
}

async function refresh() {
  const [control, jobs, audit] = await Promise.all([
    apiGet("/control"),
    apiGet("/jobs"),
    apiGet("/audit"),
  ]);
  renderKillSwitch(control.kill_switch_enabled);
  renderJobs(jobs);
  renderAudit(audit);
}

async function approve(jobId) {
  await apiPost(`/approvals/${jobId}`, { actor_id: "owner" });
  await refresh();
}

async function showJob(jobId) {
  const job = await apiGet(`/jobs/${jobId}`);
  const steps = await apiGet(`/jobs/${jobId}/steps`);
  const stepsText = steps.map((step) => `- ${step.title} (${step.status})`).join("\n");
  alert(
    `Job ${job.id}\nStatus: ${job.status}\nRisco: ${job.risk_level}\nWorker: ${job.worker_type}\n\nEtapas:\n${stepsText}\n\nExplicacao: ${job.explanation || "-"}`
  );
}

async function setKillSwitch(enabled) {
  await apiPost("/control/kill-switch", { enabled, actor_id: "owner" });
  await refresh();
}

function setup() {
  elements.apiUrl.textContent = API_URL;
  elements.refreshBtn.addEventListener("click", refresh);
  elements.killOnBtn.addEventListener("click", () => setKillSwitch(true));
  elements.killOffBtn.addEventListener("click", () => setKillSwitch(false));

  elements.jobsBody.addEventListener("click", (event) => {
    const approveBtn = event.target.closest("[data-approve]");
    if (approveBtn) {
      approve(approveBtn.dataset.approve);
      return;
    }

    const statusBtn = event.target.closest("[data-status]");
    if (statusBtn) {
      showJob(statusBtn.dataset.status);
    }
  });

  refresh().catch((error) => {
    elements.jobsBody.innerHTML = `<tr><td colspan="7">Erro ao carregar: ${error.message}</td></tr>`;
  });
}

setup();
