(() => {
  window.SideRefreshVariants = window.SideRefreshVariants || {};
  function tailnetStatus(device, installation) {
    if (installation === "missing") {
      return `<div class="tailnet-state missing">
        <div class="tailnet-lockup">
          <span class="badge experimental">설치 필요</span>
          <div><strong>Mac에 Tailscale 설치 필요</strong>
            <span>Mac과 iPhone에 설치하고 같은 Tailnet에 로그인해야 합니다.</span>
          </div>
        </div>
        <button class="button" type="button"
          data-toast="공식 Tailscale 설치 안내를 엽니다.">설치 안내</button>
        <p>설치 전에는 저장과 갱신을 차단합니다.</p>
      </div>`;
    }
    const status = device.tailnetOnline === true
      ? "Tailscale 주소 확인 완료"
      : "iPhone의 Tailscale 상태 미확인";
    const detail = device.tailnetOnline === true
      ? `${device.tailnetDetail} · 다음으로 위의 ‘Xcode에서 iPhone 확인’을 누르세요.`
      : "설치·로그인·VPN 활성화 상태를 iPhone에서 확인하세요.";
    return `<div class="tailnet-state">
      <div class="tailnet-lockup">
        <span class="badge experimental">명령 확인됨</span>
        <div><strong>${status}</strong><span>${detail}</span></div>
      </div>
      <button class="button" type="button"
        data-toast="Tailscale의 iPhone 주소를 다시 확인합니다.">
        주소 다시 확인
      </button>
    </div>`;
  }
  function hybridLabel(number, identifier, title, detail) {
    return `<div class="hybrid-label"><b>${number}</b><div>
      <h3 id="${identifier}">${title}</h3><p>${detail}</p>
    </div></div>`;
  }
  window.SideRefreshVariants.d = ({ state: key, device, tailscale }) => {
    const ui = window.ConnectionPrototypeUI;
    const state = ui.resolve(key, device);
    const identityName = state.identity ? state.deviceLine : "iPhone 미선택";
    const identityDetail = state.identity
      ? `${state.device.os} · 식별자 …${state.device.suffix}`
      : "Xcode에서 설치할 iPhone을 선택하세요.";
    const changeAction = state.identity
      ? `<button class="button quiet" type="button" data-next="multiple">iPhone 변경</button>`
      : "";
    return `<section class="assistant-layout hybrid-layout tone-${state.tone}"
      aria-labelledby="d-title">
      <div class="assistant-sheet hybrid-sheet">
        <header class="assistant-top">
          <div><span class="badge">D · A+B 결합</span><h2 id="d-title">iPhone 연결</h2></div>
          <span class="state-mark">${state.mark}</span>
        </header>
        <div class="hybrid-stack">
          <section class="hybrid-panel" aria-labelledby="d-identity-title">
            ${hybridLabel(
              "1", "d-identity-title", "설치할 iPhone",
              "앱이 설치될 실제 기기"
            )}
            <div class="identity-lockup">
              <span class="candidate-icon" aria-hidden="true">▯</span>
              <div><strong>${identityName}</strong><span>${identityDetail}</span></div>
            </div>
          </section>
          <section class="hybrid-panel" aria-labelledby="d-route-title">
            ${hybridLabel(
              "2", "d-route-title", "Xcode/CoreDevice 연결",
              "갱신 실행 주체 · 전송 경로는 Xcode가 선택"
            )}
            ${ui.rail(state)}
            <button class="button" type="button"
              data-toast="Xcode/CoreDevice에서 설치할 iPhone을 다시 확인합니다.">
              Xcode에서 iPhone 확인
            </button>
          </section>
          <section class="hybrid-panel hybrid-tailnet" aria-labelledby="d-tailnet-title">
            ${hybridLabel(
              "3", "d-tailnet-title", "원격 주소 준비 · 선택 사항",
              "Tailscale · 실험적 · Xcode 확인 별도"
            )}
            ${tailnetStatus(state.device, tailscale)}
          </section>
        </div>
        ${key === "multiple" ? ui.candidates() : ""}
        <div class="status-copy"><h3>${state.title}</h3><p>${state.detail}</p></div>
        <footer class="assistant-foot">
          ${ui.actions(key)}
          <div class="hybrid-secondary">${changeAction}<button
            class="button quiet" type="button"
            data-toast="실험적 연결이 있는 고급 설정을 엽니다.">
            고급 설정…
          </button></div>
          <p class="fine-print">
            실제 빌드·설치·갱신은 항상 Xcode/CoreDevice가 수행합니다.
            Tailscale 온라인만으로 Xcode 연결·갱신 성공을 확인할 수 없습니다.
          </p>
        </footer>
      </div>
    </section>`;
  };
})();
