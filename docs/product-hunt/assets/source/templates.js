(() => {
  const icon = "../../../../Assets/Brand/SideRefresh-AppIcon-1024.png";
  const list = values => values.map(value => `<span class="tag">${value}</span>`).join("");
  const screenshot = data => `<div class="screenshot-shell glass-card"><img src="${data.screenshot}" alt="SideRefresh Simple workspace"></div>`;

  function visual(data) {
    switch (data.variant) {
      case "hero": case "social":
        return `<img class="product-icon" src="${icon}" alt="SideRefresh icon">`;
      case "workspace":
        return screenshot(data);
      case "cycle":
        return `<div class="cycle-card glass-card"><div class="cycle-row">${data.items.map((item, index) => `<div class="cycle-step"><span class="micro">0${index + 1}</span><strong>${item}</strong></div>`).join("")}</div><div class="cycle-note"><span class="check">✓</span><strong>Repeat before signing expires</strong></div></div>`;
      case "flow":
        return `<div class="flow-card glass-card">${data.items.map((item, index) => `<div class="flow-node"><div class="node-mark">${index + 1}</div><div><strong>${item}</strong><span>${["Select source you own", "Plan and verify the refresh", "Build, sign, validate, install", "Use the verified personal app"][index]}</span></div></div>`).join("")}</div>`;
      case "privacy":
        return `<div class="privacy-grid">${[["⌂", "Local source", "Builds the selected project on this Mac."], ["✓", "No password collection", "Apple Account sign-in stays in Xcode."], ["→", "Explicit access", "You choose the project and paired device."]].map(item => `<div class="privacy-card glass-card"><span class="check">${item[0]}</span><div><strong>${item[1]}</strong><p>${item[2]}</p></div></div>`).join("")}</div>`;
      case "trust":
        return `<div class="trust-card glass-card"><img class="product-icon" src="${icon}" alt="SideRefresh icon"><div class="trust-list">${[["✓", "Apache-2.0 Swift source", ""], ["→", "Public repository at launch", "pending"], ["✓", "English and Korean UI", ""], ["→", "Developer ID + notarization before launch", "pending"]].map(item => `<div class="trust-item"><span class="check ${item[2]}">${item[0]}</span>${item[1]}</div>`).join("")}</div></div>`;
      case "video":
        return `${screenshot(data)}<div class="play">▶</div>`;
      default:
        return "";
    }
  }

  window.AssetTemplates = { icon, list, visual };
})();
