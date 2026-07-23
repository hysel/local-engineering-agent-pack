"use strict";

const CAPABILITIES = {
  "general.chat": {
    eyebrow: "03 · CHAT",
    title: "Private conversation",
    promptLabel: "Message",
    placeholder: "Ask anything…",
    busy: "Model is thinking locally…",
    welcome: "Ask a question and continue the conversation. Context stays in memory until you start a new task or close Haven 42.",
    resultLabel: "Haven 42",
  },
  "content.write": {
    eyebrow: "03 · WRITING",
    title: "Draft content",
    promptLabel: "Writing request",
    placeholder: "Describe what you want written…",
    busy: "Drafting locally…",
    welcome: "Describe the audience, purpose, tone, and key points. Haven 42 returns a Markdown draft without writing files.",
    resultLabel: "Draft",
  },
  "content.summarize": {
    eyebrow: "03 · SUMMARY",
    title: "Summarize text",
    promptLabel: "Material to summarize",
    placeholder: "Paste the material you want summarized…",
    busy: "Summarizing locally…",
    welcome: "Paste source material below. The model is instructed to summarize only what you provide and preserve uncertainty.",
    resultLabel: "Summary",
  },
};

const state = {
  token: "",
  connected: false,
  capabilityId: "general.chat",
  messages: [],
};

const byId = (id) => document.getElementById(id);

function showError(message) {
  const box = byId("connection-error");
  box.textContent = message;
  box.classList.remove("hidden");
}

function clearError() {
  byId("connection-error").classList.add("hidden");
}

function setTaskControlsDisabled(disabled) {
  document.querySelectorAll(".mode-tab, .capability-nav").forEach((button) => {
    button.disabled = disabled;
  });
  byId("new-task-button").disabled = disabled;
}

function setProviderReady(ready) {
  byId("model").disabled = !ready;
  byId("prompt").disabled = !ready;
  byId("send-button").disabled = !ready;
}

async function api(path, body) {
  const response = await fetch(path, {
    method: "POST",
    credentials: "same-origin",
    headers: {
      "Content-Type": "application/json",
      "X-Haven-Token": state.token,
    },
    body: JSON.stringify(body),
  });
  const result = await response.json().catch(() => ({ error: "invalid-server-response" }));
  if (!response.ok) {
    throw new Error(result.error || `request-failed-${response.status}`);
  }
  return result;
}

function humanError(error) {
  const messages = {
    "provider-host-must-be-ip-literal": "Enter a literal IP address; hostnames are not accepted.",
    "loopback-provider-required": "Choose Trusted local network for a server on another machine.",
    "trusted-lan-provider-required": "The selected address is not a private local-network address.",
    "ollama-connection-failed": "Haven 42 could not reach Ollama at that address.",
    "ollama-chat-failed": "Ollama did not complete the text request.",
    "empty-model-response": "The model returned an empty response.",
    "capability-not-admitted": "That capability is not available in this Haven 42 release.",
  };
  return messages[error.message] || `Request blocked: ${error.message}`;
}

function addMessage(role, content, label) {
  const article = document.createElement("article");
  article.className = `message ${role}`;
  const avatar = document.createElement("div");
  avatar.className = "avatar";
  avatar.textContent = role === "assistant" ? "42" : "You";
  const body = document.createElement("div");
  const heading = document.createElement("strong");
  heading.textContent = label || (role === "assistant" ? "Haven 42" : "You");
  const text = document.createElement("p");
  text.textContent = content;
  body.append(heading, text);
  article.append(avatar, body);
  byId("messages").append(article);
  article.scrollIntoView({ behavior: "smooth", block: "end" });
}

function resetTask() {
  state.messages = [];
  const capability = CAPABILITIES[state.capabilityId];
  const messages = byId("messages");
  messages.replaceChildren();
  addMessage("assistant", capability.welcome, "Haven 42");
  byId("prompt").value = "";
  byId("text-status").textContent = state.connected ? "Ready · nothing saved" : "Provider not connected";
}

function selectCapability(capabilityId) {
  if (!Object.hasOwn(CAPABILITIES, capabilityId)) return;
  state.capabilityId = capabilityId;
  const capability = CAPABILITIES[capabilityId];
  byId("capability-eyebrow").textContent = capability.eyebrow;
  byId("capability-title").textContent = capability.title;
  byId("prompt-label").textContent = capability.promptLabel;
  if (state.connected) byId("prompt").placeholder = capability.placeholder;
  document.querySelectorAll(".mode-tab").forEach((button) => {
    const active = button.dataset.capability === capabilityId;
    button.classList.toggle("active", active);
    button.setAttribute("aria-selected", String(active));
  });
  document.querySelectorAll(".capability-nav").forEach((button) => {
    button.classList.toggle("active", button.dataset.capability === capabilityId);
  });
  byId("home-nav").classList.remove("active");
  resetTask();
}

async function bootstrap() {
  try {
    const response = await fetch("/api/bootstrap", { credentials: "same-origin" });
    if (!response.ok) throw new Error("bootstrap-failed");
    const result = await response.json();
    state.token = result.sessionToken;
    byId("app-version").textContent = `v${result.version}`;
    byId("host-status").textContent = `${result.runtime.platform} · ${result.runtime.architecture}`;
  } catch (_error) {
    showError("Haven 42 could not initialize its secure local session.");
  }
}

byId("connection-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  clearError();
  const button = byId("connect-button");
  const wasConnected = state.connected;
  button.disabled = true;
  setProviderReady(false);
  button.textContent = "Checking…";
  try {
    const result = await api("/api/connect", {
      endpoint: byId("endpoint").value.trim(),
      trustScope: byId("trust-scope").value,
      timeoutSeconds: Number(byId("timeout").value),
    });
    state.connected = true;
    const select = byId("model");
    select.replaceChildren();
    if (result.models.length === 0) {
      const option = document.createElement("option");
      option.textContent = "No installed models found";
      select.append(option);
      select.disabled = true;
      byId("prompt").disabled = true;
      byId("prompt").placeholder = "Install an Ollama model to begin…";
      byId("send-button").disabled = true;
    } else {
      for (const model of result.models) {
        const option = document.createElement("option");
        option.value = model;
        option.textContent = model;
        select.append(option);
      }
      select.disabled = false;
      byId("prompt").disabled = false;
      byId("prompt").placeholder = CAPABILITIES[state.capabilityId].placeholder;
      byId("send-button").disabled = false;
    }
    const badge = byId("connection-badge");
    badge.textContent = `Connected · Ollama ${result.version}`;
    badge.classList.add("good");
    resetTask();
    byId("text-status").textContent = `${result.models.length} installed model${result.models.length === 1 ? "" : "s"} found`;
  } catch (error) {
    if (error.message === "ollama-connection-failed") {
      state.connected = false;
      byId("connection-badge").textContent = "Not connected";
      byId("connection-badge").classList.remove("good");
      byId("prompt").placeholder = "Reconnect Ollama to begin…";
      byId("text-status").textContent = "Provider not connected";
    } else {
      state.connected = wasConnected;
      setProviderReady(wasConnected);
    }
    showError(humanError(error));
  } finally {
    button.disabled = false;
    button.textContent = state.connected ? "Reconnect" : "Connect";
  }
});

byId("text-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  clearError();
  const prompt = byId("prompt");
  const content = prompt.value.trim();
  if (!content || !state.connected) return;
  const capability = CAPABILITIES[state.capabilityId];
  const capabilityId = state.capabilityId;
  const send = byId("send-button");
  send.disabled = true;
  prompt.disabled = true;
  setTaskControlsDisabled(true);
  prompt.value = "";
  const requestMessages = capabilityId === "general.chat"
    ? [...state.messages, { role: "user", content }].slice(-20)
    : [{ role: "user", content }];
  if (capabilityId === "general.chat") state.messages = requestMessages;
  addMessage("user", content, capabilityId === "content.summarize" ? "Source" : "You");
  byId("text-status").textContent = capability.busy;
  try {
    const result = await api("/api/text", {
      capabilityId,
      model: byId("model").value,
      messages: requestMessages,
    });
    if (capabilityId === "general.chat") {
      state.messages.push({ role: "assistant", content: result.content });
    }
    addMessage("assistant", result.content, capability.resultLabel);
    byId("text-status").textContent = result.modelUnloaded
      ? `${result.model} · response complete · model unloaded`
      : `${result.model} · response complete · cleanup needs attention`;
  } catch (error) {
    showError(humanError(error));
    byId("text-status").textContent = "Text request failed";
  } finally {
    send.disabled = false;
    prompt.disabled = false;
    setTaskControlsDisabled(false);
    prompt.focus();
  }
});

document.querySelectorAll("[data-capability]").forEach((button) => {
  button.addEventListener("click", () => {
    selectCapability(button.dataset.capability);
    byId("text-panel").scrollIntoView({ behavior: "smooth" });
  });
});
byId("new-task-button").addEventListener("click", resetTask);
byId("home-nav").addEventListener("click", () => {
  document.querySelectorAll(".nav-item").forEach((button) => button.classList.remove("active"));
  byId("home-nav").classList.add("active");
  window.scrollTo({ top: 0, behavior: "smooth" });
});
byId("models-nav").addEventListener("click", () => {
  byId("connection-panel").scrollIntoView({ behavior: "smooth" });
});
byId("system-nav").addEventListener("click", () => {
  byId("status-panel").scrollIntoView({ behavior: "smooth" });
});

bootstrap();
