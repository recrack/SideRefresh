(() => {
  window.SideRefreshVariants = window.SideRefreshVariants || {};
  window.SideRefreshVariants.a = ({ state: key, device }) => {
    const ui = window.ConnectionPrototypeUI;
    const state = ui.resolve(key, device);
    const dots = [1, 2, 3].map((step) => {
      const style = step < state.step ? "done" : step === state.step ? "active" : "";
      return `<i class="${style}"></i>`;
    }).join("");
    const deviceDetail = state.identity
      ? `<p><strong>${state.deviceLine}</strong> · ${state.device.os}</p>`
      : "";
    return `<section class="assistant-layout tone-${state.tone}" aria-labelledby="a-title">
      <div class="assistant-sheet">
        <header class="assistant-top">
          <div><span class="badge">A · 추천</span><h2 id="a-title">iPhone 연결</h2></div>
          <div class="progress-dots" aria-label="3단계 중 ${state.step}단계">${dots}</div>
        </header>
        ${ui.rail(state)}
        <div class="status-copy">
          <span class="state-mark">${state.mark}</span>
          <h3>${state.title}</h3>
          <p>${state.detail}</p>
          ${deviceDetail}
        </div>
        ${key === "multiple" ? ui.candidates() : ""}
        <footer class="assistant-foot">
          ${ui.actions(key)}
          <p class="fine-print">
            실제 갱신은 Xcode/CoreDevice가 수행하며,
            USB·네트워크 전송 경로는 Xcode가 선택합니다.
          </p>
          <button class="button quiet" type="button"
            data-toast="실험적 연결이 있는 고급 설정을 엽니다.">
            실험적 연결은 고급 설정에서…
          </button>
        </footer>
      </div>
    </section>`;
  };
})();
