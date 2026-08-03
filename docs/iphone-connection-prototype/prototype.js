(() => {
  window.history.scrollRestoration = "manual";
  window.scrollTo(0, 0);
  const variantKeys = ["a", "b", "c", "d"];
  const variantLabels = {
    a: "A — 한 단계 연결 시트", b: "B — 기기와 연결 분리",
    c: "C — 단계형 도우미", d: "D — A+B 결합"
  };
  const validStates = Object.keys(window.ConnectionPrototypeUI.stateLabels);
  const tailscaleLabels = { installed: "설치됨", missing: "미설치" };
  const url = new URL(window.location.href);
  const pick = (value, choices, fallback) => choices.includes(value) ? value : fallback;
  let variant = pick(url.searchParams.get("variant"), variantKeys, "d");
  let state = pick(url.searchParams.get("state"), validStates, "ready");
  let device = pick(
    url.searchParams.get("device"),
    ["personal", "studio"],
    "personal"
  );
  const tailscaleChoices = Object.keys(tailscaleLabels);
  let tailscale = pick(url.searchParams.get("tailscale"), tailscaleChoices, "installed");
  const root = document.querySelector("#variant-root");
  const stateSelect = document.querySelector("#state-select");
  const tailscaleControl = document.querySelector("#tailscale-control");
  const tailscaleSelect = document.querySelector("#tailscale-select");
  const label = document.querySelector("#variant-label");
  const announcement = document.querySelector("#announcement");

  function syncUrl() {
    const nextUrl = new URL(window.location.href);
    nextUrl.searchParams.set("variant", variant);
    nextUrl.searchParams.set("state", state);
    nextUrl.searchParams.set("device", device);
    nextUrl.searchParams.set("tailscale", tailscale);
    window.history.replaceState(null, "", nextUrl.href);
  }

  function announce(message) {
    announcement.textContent = "";
    window.requestAnimationFrame(() => { announcement.textContent = message; });
  }

  function render(shouldAnnounce = true, shouldFocus = false) {
    root.innerHTML = window.SideRefreshVariants[variant]({ state, device, tailscale });
    Object.assign(root.dataset, { variant, state, tailscale });
    stateSelect.value = state;
    tailscaleSelect.value = tailscale;
    tailscaleControl.hidden = variant !== "d";
    label.textContent = variantLabels[variant];
    syncUrl();
    window.scrollTo(0, 0);
    if (shouldFocus) root.focus({ preventScroll: true });
    const tailscaleState = variant === "d"
      ? `, Tailscale ${tailscaleLabels[tailscale]}`
      : "";
    const stateLabel = window.ConnectionPrototypeUI.stateLabels[state];
    if (shouldAnnounce) {
      announce(`${variantLabels[variant]}, ${stateLabel}${tailscaleState}`);
    }
  }

  function moveVariant(offset) {
    const index = variantKeys.indexOf(variant);
    variant = variantKeys[(index + offset + variantKeys.length) % variantKeys.length];
    render();
  }

  document.querySelector("#previous-variant").addEventListener("click", () => moveVariant(-1));
  document.querySelector("#next-variant").addEventListener("click", () => moveVariant(1));
  stateSelect.addEventListener("change", () => { state = stateSelect.value; render(); });
  tailscaleSelect.addEventListener("change", () => {
    tailscale = tailscaleSelect.value; render();
  });
  document.addEventListener("click", (event) => {
    const control = event.target.closest("[data-next], [data-toast]");
    if (!control) return;
    if (control.dataset.device) device = control.dataset.device;
    if (control.dataset.next) {
      state = control.dataset.next;
      render(true, true);
      return;
    }
    announce(`${control.dataset.toast} 프로토타입에서는 실행하지 않습니다.`);
  });
  document.addEventListener("keydown", (event) => {
    const hasModifier = event.metaKey || event.ctrlKey || event.altKey;
    if (event.defaultPrevented || event.isComposing || hasModifier) return;
    const target = event.target;
    const selector = "input, textarea, select, button, [contenteditable]";
    if (!(target instanceof Element) || target.closest(selector)) return;
    if (event.key === "ArrowLeft") { event.preventDefault(); moveVariant(-1); }
    if (event.key === "ArrowRight") { event.preventDefault(); moveVariant(1); }
  });
  render(false);
  window.addEventListener("load", () => {
    window.requestAnimationFrame(() => window.scrollTo(0, 0));
  }, { once: true });
})();
