const path = require("path");

const config = {
  apiUrl: process.env.ORCHESTRATOR_API_URL || "http://localhost:8080",
  sessionDir:
    process.env.WHATSAPP_SESSION_DIR || path.resolve(process.cwd(), "sessions"),
  ownerJid: process.env.WHATSAPP_OWNER_JID || "",
  autoApproveSafe: process.env.WHATSAPP_AUTO_APPROVE_SAFE === "true",
};

module.exports = { config };
