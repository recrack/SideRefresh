(() => {
  function button(label, attributes, primary = false) {
    const style = primary ? "button primary" : "button";
    return `<button class="${style}" type="button" ${attributes}>${label}</button>`;
  }

  function actions(key) {
    const first = {
      ready: button("완료", 'data-toast="설정 화면으로 돌아갑니다."', true),
      empty: button("다시 찾기", 'data-next="scanning"', true),
      pairing: button(
        "Xcode 열기", 'data-toast="Xcode Device Hub를 엽니다."', true
      ),
      error: button("다시 시도", 'data-next="scanning"', true),
      scanning: button("검색 결과 보기", 'data-next="ready"', true)
    }[key] || button("다시 찾기", 'data-next="empty"');
    const second = {
      empty: button("연결 도움", 'data-toast="케이블 연결 도움말을 엽니다."'),
      pairing: button("연결 다시 확인", 'data-next="ready"'),
      error: button("진단 보기", 'data-toast="연결 진단을 엽니다."'),
      scanning: button("취소", 'data-next="empty"')
    }[key] || "";
    return `<div class="actions">${first}${second}</div>`;
  }

  window.ConnectionPrototypeUI.actions = actions;
})();
