(() => {
  window.SideRefreshVariants = window.SideRefreshVariants || {};
  window.SideRefreshVariants.c = ({ state: key, device }) => {
    const ui = window.ConnectionPrototypeUI;
    const state = ui.resolve(key, device);
    const steps = ["처음 연결", "iPhone 선택", "연결 확인"].map((label, index) => {
      const step = index + 1;
      const style = step < state.step ? "done" : step === state.step ? "active" : "";
      return `<li class="${style}"><b>${step < state.step ? "✓" : step}</b><span>${label}</span></li>`;
    }).join("");
    return `<section class="journey-layout tone-${state.tone}" aria-labelledby="c-title">
      <aside class="journey-nav">
        <span class="badge">C · 단계형</span>
        <h2>iPhone 연결</h2>
        <ol class="step-list">${steps}</ol>
        <button class="button quiet" type="button" data-toast="선택한 iPhone을 바꾸지 않고 닫습니다.">나중에</button>
      </aside>
      <div class="journey-main">
        <header><p class="eyebrow">3단계 중 ${state.step}단계</p><h2 id="c-title">${state.title}</h2><p>${state.detail}</p></header>
        <div class="instruction-strip">
          <div class="${state.step === 1 ? "current" : ""}"><b>케이블 연결</b>iPhone 잠금을 풀고 이 Mac을 신뢰합니다.</div>
          <div class="${state.step === 2 ? "current" : ""}"><b>기기 선택</b>여러 대라면 사용할 한 대를 직접 고릅니다.</div>
          <div class="${state.step === 3 ? "current" : ""}"><b>Xcode 확인</b>같은 기기가 설치 대상으로 보이는지 확인합니다.</div>
        </div>
        <div class="card">${ui.rail(state)}</div>
        <div class="status-copy"><span class="state-mark">${state.mark}</span><h3>${state.identity ? state.deviceLine : state.title}</h3><p>${state.identity ? `${state.device.os} · ${state.detail}` : state.detail}</p></div>
        ${key === "multiple" ? ui.candidates() : ""}
        ${ui.actions(key)}
        <p class="fine-print">SideRefresh는 계정, 신뢰, Developer Mode 또는 VPN을 대신 변경하지 않습니다.</p>
      </div>
    </section>`;
  };
})();
