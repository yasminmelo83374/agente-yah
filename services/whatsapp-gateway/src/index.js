const pino = require("pino");

const { config } = require("./config");
const { sendCommand, approveJob, getJob, setKillSwitch } = require("./orchestratorClient");

const pendingChunks = new Map(); // remoteJid -> array of chunks

function chunkText(text, maxLength = 800) {
  const chunks = [];
  let remaining = text.trim();
  while (remaining.length > maxLength) {
    let slice = remaining.slice(0, maxLength);
    const lastBreak = Math.max(slice.lastIndexOf("\n"), slice.lastIndexOf(". "));
    if (lastBreak > 200) {
      slice = slice.slice(0, lastBreak + 1);
    }
    chunks.push(slice.trim());
    remaining = remaining.slice(slice.length).trim();
  }
  if (remaining) chunks.push(remaining);
  return chunks;
}

async function createSocket() {
  let baileys;
  try {
    baileys = require("@whiskeysockets/baileys");
  } catch (error) {
    console.error("Baileys nao instalado. Rode npm install em services/whatsapp-gateway.");
    throw error;
  }

  const {
    default: makeWASocket,
    useMultiFileAuthState,
    DisconnectReason,
    fetchLatestBaileysVersion,
    downloadMediaMessage,
  } = baileys;

  const { state, saveCreds } = await useMultiFileAuthState(config.sessionDir);
  const { version } = await fetchLatestBaileysVersion();
  const socket = makeWASocket({
    auth: state,
    logger: pino({ level: "info" }),
    version,
    printQRInTerminal: true,
    markOnlineOnConnect: true,
    emitOwnEvents: true,
  });

  socket.ev.on("creds.update", saveCreds);

  socket.ev.on("connection.update", (update) => {
    if (update.qr) {
      console.log("=== QR CODE (BASE64) ===");
      console.log(update.qr);
      console.log("Use um leitor de QR no WhatsApp para parear.");
    }
    if (update.connection === "close") {
      const reason = update.lastDisconnect?.error?.output?.statusCode;
      if (reason === DisconnectReason.loggedOut) {
        console.log("Sessao encerrada. Remova a pasta sessions e conecte novamente.");
      } else {
        console.log("Conexao fechada. Tentando reconectar...");
        createSocket().catch(console.error);
      }
    }
  });

  socket.ev.on("messages.upsert", async ({ messages }) => {
    const msg = messages?.[0];
    if (!msg) {
      return;
    }

    const audioMsg = msg.message?.audioMessage;
    const text = msg.message?.conversation || msg.message?.extendedTextMessage?.text || "";
    let normalized = text.trim();
    let lower = normalized.toLowerCase();
    if (!normalized && !audioMsg) {
      return;
    }

    const remoteJid = msg.key?.remoteJid || "";
    try {
      if (lower === "mais") {
        const chunks = pendingChunks.get(remoteJid);
        if (!chunks || chunks.length === 0) {
          await socket.sendMessage(remoteJid, { text: "Nao ha mais conteudo pendente." });
          return;
        }
        const next = chunks.shift();
        await socket.sendMessage(remoteJid, { text: next });
        if (chunks.length === 0) {
          pendingChunks.delete(remoteJid);
        } else {
          pendingChunks.set(remoteJid, chunks);
        }
        return;
      }

      const isFromMe = Boolean(msg.key?.fromMe);
      const wakeWords = ["bot:", "agente:", "assistente:"];
      if (isFromMe) {
        const hasWakeWord = wakeWords.some((word) => lower.startsWith(word));
        const isExplicitCommand = lower.startsWith("/") || lower.startsWith("cmd:");
        if (!hasWakeWord && !isExplicitCommand && !audioMsg) {
          return;
        }
        if (hasWakeWord) {
          const matched = wakeWords.find((word) => lower.startsWith(word));
          normalized = normalized.slice(matched.length).trim();
          lower = normalized.toLowerCase();
        }
      }

      if (audioMsg) {
        const buffer = await downloadMediaMessage(msg, "buffer", {}, { logger: pino() });
        const mime = audioMsg.mimetype || "audio/ogg";
        const ext = mime.split("/")[1] || "ogg";
        const form = new FormData();
        form.append(
          "file",
          new Blob([buffer], { type: mime }),
          `audio.${ext}`
        );
        const resp = await fetch(`${config.apiUrl}/transcribe`, {
          method: "POST",
          body: form,
        });
        if (!resp.ok) {
          throw new Error(`Transcricao falhou: ${resp.status} ${await resp.text()}`);
        }
        const data = await resp.json();
        normalized = data.text || "";
        lower = normalized.toLowerCase();
        if (!normalized.trim()) {
          await socket.sendMessage(remoteJid, { text: "Nao consegui entender o audio." });
          return;
        }
        await socket.sendMessage(remoteJid, {
          text: `Transcricao: ${normalized}`,
        });
      }

      if (lower.includes("/whoami") || lower.startsWith("/who")) {
        await socket.sendMessage(remoteJid, {
          text: `Seu JID: ${remoteJid}`,
        });
        return;
      }

      if (config.ownerJid && remoteJid !== config.ownerJid) {
        return;
      }

      if (lower.startsWith("/status")) {
        const jobId = Number(normalized.split(" ")[1]);
        const job = await getJob(config.apiUrl, jobId);
        await socket.sendMessage(remoteJid, {
          text: `Job ${job.id} status=${job.status} risco=${job.risk_level}`,
        });
        return;
      }

      if (lower.startsWith("/approve")) {
        const jobId = Number(normalized.split(" ")[1]);
        const job = await approveJob(config.apiUrl, jobId);
        await socket.sendMessage(remoteJid, {
          text: `Aprovado. Status=${job.status} confirmacoes=${job.confirmations_done}/${job.required_confirmations}`,
        });
        return;
      }

      if (lower === "/killon") {
        const status = await setKillSwitch(config.apiUrl, true);
        await socket.sendMessage(remoteJid, {
          text: `Kill switch ativado: ${status.kill_switch_enabled}`,
        });
        return;
      }

      if (lower === "/killoff") {
        const status = await setKillSwitch(config.apiUrl, false);
        await socket.sendMessage(remoteJid, {
          text: `Kill switch desativado: ${!status.kill_switch_enabled}`,
        });
        return;
      }

      const result = await sendCommand(config.apiUrl, normalized, "owner");
      const reply =
        result.assistant_message ||
        `Entendi. Vou cuidar disso agora. Se precisar de aprovacao, eu aviso. (job ${result.job_id})`;

      if (reply.length > 800) {
        const chunks = chunkText(reply, 800);
        const summary = chunks.shift();
        pendingChunks.set(remoteJid, chunks);
        await socket.sendMessage(remoteJid, {
          text: `${summary}\n\nSe quiser a resposta completa, responda \"mais\".`,
        });
      } else {
        await socket.sendMessage(remoteJid, { text: reply });
      }
    } catch (error) {
      if (remoteJid) {
        await socket.sendMessage(remoteJid, {
          text: `Erro ao processar: ${error.message}`,
        });
      }
    }
  });

  return socket;
}

createSocket().catch((error) => {
  console.error("Falha ao iniciar WhatsApp gateway", error);
});
