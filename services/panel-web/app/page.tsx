export default function Home() {
  return (
    <main className="page">
      <section className="hero">
        <div>
          <p className="badge">MVP v1</p>
          <h1>Painel de Controle do Agente</h1>
          <p className="subtitle">
            Visibilidade total sobre execucoes, aprovacoes e autonomia supervisionada no
            seu Mac e na VPS.
          </p>
          <div className="cta">
            <button className="primary">Abrir fila de aprovacao</button>
            <button className="ghost">Ver auditoria</button>
          </div>
        </div>
        <div className="hero-card">
          <h2>Estado Geral</h2>
          <ul>
            <li>
              <span className="dot online" /> Orquestrador: Online
            </li>
            <li>
              <span className="dot warn" /> Mac Runner: ON_SUPERVISED
            </li>
            <li>
              <span className="dot idle" /> WhatsApp: Aguardando QR
            </li>
          </ul>
          <p className="hint">
            Kill switch ativo. Use o painel para interromper qualquer agente em tempo
            real.
          </p>
        </div>
      </section>

      <section className="grid">
        <article className="card">
          <h3>Timeline</h3>
          <p>Historico de jobs, tempos e evidencias visuais.</p>
          <div className="meta">Ultima acao: 2 min atras</div>
        </article>
        <article className="card">
          <h3>Aprovacoes</h3>
          <p>Acao critica? Dupla confirmacao em destrutivas.</p>
          <div className="meta">3 pendencias</div>
        </article>
        <article className="card">
          <h3>Agentes</h3>
          <p>Subagentes por dominio com roteamento automatico.</p>
          <div className="meta">4 ativos</div>
        </article>
        <article className="card">
          <h3>Auditoria</h3>
          <p>Logs, screenshots e trilha completa de decisoes.</p>
          <div className="meta">Retencao: 90 dias</div>
        </article>
      </section>

      <section className="split">
        <div>
          <h2>Modo supervisionado por padrao</h2>
          <p>
            O agente executa tarefas automaticamente, mas para qualquer acao critica
            ele solicita sua aprovacao. Isso reduz risco sem travar a velocidade.
          </p>
        </div>
        <div className="panel">
          <h3>Politica ativa</h3>
          <div className="chips">
            <span>Safe: auto</span>
            <span>Critical: aprovar</span>
            <span>Destructive: 2x aprovar</span>
          </div>
          <p className="mini">Tempo medio de resposta: 5s</p>
        </div>
      </section>
    </main>
  );
}
