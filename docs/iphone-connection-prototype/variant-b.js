(() => {
  window.SideRefreshVariants = window.SideRefreshVariants || {};
  window.SideRefreshVariants.b = ({ state: key, device }) => {
    const ui = window.ConnectionPrototypeUI;
    const state = ui.resolve(key, device);
    const identityName = state.identity ? state.deviceLine : "iPhone 미선택";
    const identityDetail = state.identity ? `${state.device.os} · 식별자 …${state.device.suffix}` : "Xcode에서 설치할 iPhone을 선택하세요.";
    return `<section class="explicit-layout tone-${state.tone}" aria-labelledby="b-title">
      <header class="page-heading">
        <div><span class="badge">B · 개념 분리</span><h2 id="b-title">iPhone과 연결</h2><p>설치 대상과 도달 방법을 따로 확인합니다.</p></div>
        <button class="button" type="button" data-next="scanning">연결 다시 확인</button>
      </header>
      <div class="dual-grid">
        <article class="card identity-card">
          <p class="card-title">1 · 설치할 iPhone</p>
          <div class="identity-lockup"><span class="candidate-icon">▯</span><div><strong>${identityName}</strong><span>${identityDetail}</span></div></div>
          <p class="fine-print">실제 설치 대상은 Xcode가 제공하는 기기 식별자로 고정됩니다.</p>
          <div class="actions"><button class="button" type="button" data-next="multiple">iPhone 변경</button></div>
        </article>
        <article class="card route-card">
          <p class="card-title">2 · 지원 연결</p>
          ${ui.rail(state)}
          <div class="status-copy"><span class="state-mark">${state.mark}</span><h3>${state.title}</h3><p>${state.detail}</p></div>
          ${ui.actions(key)}
        </article>
      </div>
      ${key === "multiple" ? `<div class="explicit-candidates">${ui.candidates()}</div>` : ""}
      <aside class="truth-note">
        <span class="badge experimental">실험적</span>
        <p>Tailscale 온라인 상태는 Xcode 연결 성공을 뜻하지 않습니다. Tailnet과 직접 주소는 지원 상태와 분리합니다.</p>
        <button class="button" type="button" data-toast="고급 설정의 실험적 연결을 엽니다.">고급 설정</button>
      </aside>
    </section>`;
  };
})();
