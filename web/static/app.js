"use strict";

const state = {
  token: "",
  connected: false,
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
    "ollama-chat-failed": "Ollama did not complete the chat request.",
    "empty-model-response": "The model returned an empty response.",
  };
  return messages[error.message] || `Request blocked: ${error.message}`;
}

function addMessage(role, content) {
  const article = document.createElement("article");
  article.className = `message ${role}`;
  const avatar = document.createElement("div");
  avatar.className = "avatar";
  avatar.textContent = role === "assistant" ? "42" : "You";
  const body = document.createElement("div");
  const label = document.createElement("strong");
  label.textContent = role === "assistant" ? "Haven 42" : "You";
  const text = document.createElement("p");
  text.textContent = content;
  body.append(label, text);
  article.append(avatar, body);
  byId("messages").append(article);
  article.scrollIntoView({ behavior: "smooth", block: "end" });
}

async function bootstrap() {
  try {
    const response = await fetch("/api/bootstrap", { credentials: "same-origin" });
    if (!response.ok) throw new Error("bootstrap-failed");
    const result = await response.json();
    state.token = result.sessionToken;
    byId("app-version").textContent = `v${result.version}`;
    byId("host-status").textContent =
      `${result.runtime.platform} · ${result.runtime.architecture}`;
  } catch (_error) {
    showError("Haven 42 could not initialize its secure local session.");
  }
}

byId("connection-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  clearError();
  const button = byId("connect-button");
  button.disabled = true;
  button.textContent = "Checking…";
  try {
    const result = await api("/api/connect", {
      endpoint: byId("endpoint").value.trim(),
      trustScope: byId("trust-scope").value,
      timeoutSeconds: Number(byId("timeout").value),
    });
    state.connected = true;
    state.messages = [];
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
      byId("prompt").placeholder = "Ask anything…";
      byId("send-button").disabled = false;
    }
    const badge = byId("connection-badge");
    badge.textContent = `Connected · Ollama ${result.version}`;
    badge.classList.add("good");
    byId("chat-status").textContent =
      `${result.models.length} installed model${result.models.length === 1 ? "" : "s"} found`;
  } catch (error) {
    showError(humanError(error));
  } finally {
    button.disabled = false;
    button.textContent = state.connected ? "Reconnect" : "Connect";
  }
});

byId("chat-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const prompt = byId("prompt");
  const content = prompt.value.trim();
  if (!content || !state.connected) return;
  const send = byId("send-button");
  send.disabled = true;
  prompt.disabled = true;
  prompt.value = "";
  state.messages.push({ role: "user", content });
  addMessage("user", content);
  byId("chat-status").textContent = "Model is thinking locally…";
  try {
    const result = await api("/api/chat", {
      model: byId("model").value,
      messages: state.messages.slice(-20),
    });
    state.messages.push({ role: "assistant", content: result.content });
    addMessage("assistant", result.content);
    byId("chat-status").textContent = result.modelUnloaded
      ? `${result.model} · response complete · model unloaded`
      : `${result.model} · response complete · cleanup needs attention`;
  } catch (error) {
    showError(humanError(error));
    byId("chat-status").textContent = "Chat request failed";
  } finally {
    send.disabled = false;
    prompt.disabled = false;
    prompt.focus();
  }
});

byId("models-nav").addEventListener("click", () => {
  byId("connection-panel").scrollIntoView({ behavior: "smooth" });
});
byId("system-nav").addEventListener("click", () => {
  byId("status-panel").scrollIntoView({ behavior: "smooth" });
});

bootstrap();
