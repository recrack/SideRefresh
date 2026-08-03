(() => {
  const params = new URLSearchParams(window.location.search);
  const key = params.get("asset") || "gallery-01";
  const isDraft = params.get("status") !== "final";
  const data = window.SideRefreshAssets[key];
  if (!data) throw new Error(`Unknown asset: ${key}`);

  const canvas = document.getElementById("canvas");
  canvas.className = data.variant;
  const art = data.background
    ? `<img class="art-background" src="../backgrounds/renewal-loop-source.png" alt=""><div class="shade"></div>`
    : "";
  const tags = data.tags?.length
    ? `<div class="tags">${window.AssetTemplates.list(data.tags)}</div>`
    : "";
  const number = data.number || "PRODUCT HUNT LAUNCH KIT";
  const status = isDraft
    ? `<div class="status">DRAFT · PRE-RELEASE</div>`
    : "";

  canvas.innerHTML = `${art}
    <header class="topbar">
      <div class="brand"><img src="${window.AssetTemplates.icon}" alt="">SideRefresh</div>
      ${status}
    </header>
    <main class="stage">
      <section class="copy">
        <div class="kicker">${data.kicker}</div>
        <h1>${data.headline}</h1>
        <p class="body-copy">${data.body}</p>
        ${tags}
      </section>
      <section class="visual">${window.AssetTemplates.visual(data)}</section>
    </main>
    <footer class="footer">
      <span>${number}</span>
      <span>Independent project · Not affiliated with Apple Inc.</span>
    </footer>`;
  canvas.setAttribute("aria-label", `${data.headline}. ${data.body}`);
})();
