(() => {
  const device = (name, model, os, suffix, online, detail) => ({
    name, model, os, suffix, tailnetOnline: online, tailnetDetail: detail
  });
  const devices = {
    personal: device(
      "My iPhone", "iPhone 13 Pro Max", "iOS 26.5.2", "A1B2", true,
      "personal-iphone · 100.64.10.20 · 식별자 …A1B2"
    ),
    studio: device(
      "Studio iPhone", "iPhone 16", "iOS 26.5", "9C12", null,
      "studio-iphone · 100.92.18.12 · 식별자 …9C12"
    )
  };
  const makeState = (tone, mark, title, detail, rail, step, identity) => ({
    tone, mark, title, detail, rail, step, identity
  });
  const states = {
    ready: makeState(
      "ok", "Xcode 기기 확인됨",
      "Xcode의 페어링된 기기 목록에서 이 iPhone을 확인했습니다.",
      "선택한 iPhone의 UDID를 확인했습니다."
        + " 현재 USB·Wi-Fi 등 실제 전송 경로는 구분하지 않습니다.",
      "페어링 목록 확인", 3, true
    ),
    empty: makeState(
      "warning", "iPhone 없음", "iPhone을 찾지 못했습니다.",
      "케이블로 연결하고 잠금을 해제한 뒤"
        + " ‘이 컴퓨터를 신뢰’를 허용하세요.",
      "찾을 수 없음", 1, false
    ),
    pairing: makeState(
      "warning", "처음 연결 필요", "이 iPhone은 연결 설정이 더 필요합니다.",
      "신뢰와 Developer Mode를 허용한 뒤 Xcode에서 페어링하세요.",
      "페어링 필요", 1, true
    ),
    multiple: makeState(
      "active", "2대 발견", "사용할 iPhone을 하나 선택하세요.",
      "선택한 기기의 Xcode 식별자가 실제 설치 대상을 결정합니다.",
      "선택 필요", 2, false
    ),
    error: makeState(
      "danger", "확인 오류", "연결 상태를 확인하지 못했습니다.",
      "선택한 iPhone은 유지됩니다. Xcode 상태를 확인한 뒤 다시 시도하세요.",
      "확인 실패", 3, true
    ),
    scanning: makeState(
      "active", "찾는 중", "Xcode에서 iPhone을 찾고 있습니다…",
      "최대 20초 동안 페어링된 실제 iPhone만 확인합니다.",
      "검색 중", 2, false
    )
  };
  const stateLabels = {
    ready: "Xcode 기기 확인됨", empty: "iPhone 없음",
    pairing: "처음 연결 필요", multiple: "여러 대 발견",
    error: "확인 오류", scanning: "찾는 중"
  };

  function resolve(key, deviceKey) {
    const device = devices[deviceKey] || devices.personal;
    return {
      ...states[key], key, device,
      deviceLine: `${device.name} · ${device.model}`,
      stateLabel: stateLabels[key]
    };
  }

  function rail(state) {
    return `<div class="connection-rail tone-${state.tone}">
      <div class="endpoint"><i class="device-glyph mac"></i><span>이 Mac</span></div>
      <div class="signal"><i class="signal-line"></i><span>${state.rail}</span></div>
      <div class="endpoint"><i class="device-glyph phone"></i><span>내 iPhone</span></div>
    </div>`;
  }

  function candidates() {
    return `<div class="candidate-list" aria-label="발견한 iPhone">
      ${Object.entries(devices).map(([key, device]) => `<button
        class="candidate" type="button" data-device="${key}" data-next="ready">
        <span class="candidate-icon">▯</span><span>
          <strong>${device.name} · ${device.model}</strong>
          <small>${device.os} · …${device.suffix}</small>
        </span><em>이 iPhone 사용</em>
      </button>`).join("")}
    </div>`;
  }

  window.ConnectionPrototypeUI = { resolve, rail, candidates, stateLabels };
})();
