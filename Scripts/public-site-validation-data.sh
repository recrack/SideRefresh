#!/bin/bash

pages=("docs/index.html" "docs/ko/index.html" "docs/ja/index.html" "docs/zh-cn/index.html")
languages=("en" "ko" "ja" "zh-Hans")
canonicals=(
    "https://recrack.github.io/SideRefresh/"
    "https://recrack.github.io/SideRefresh/ko/"
    "https://recrack.github.io/SideRefresh/ja/"
    "https://recrack.github.io/SideRefresh/zh-cn/"
)
headlines=(
    "Keep the iOS app your coding agent built running on your own iPhone."
    "코딩 에이전트가 만든 iOS 앱을 내 iPhone에서 계속 사용하세요."
    "コーディングエージェントが作ったiOSアプリを、自分のiPhoneで使い続ける。"
    "让编码智能体构建的 iOS App 持续运行在你自己的 iPhone 上。"
)
app_languages=(
    "App interface: English · 한국어"
    "앱 인터페이스: 영어 · 한국어"
    "アプリの表示言語: 英語・韓国語"
    "应用界面语言：英语、韩语"
)
sample_labels=(
    "Sample preview · synthetic data"
    "샘플 미리보기 · 합성 데이터"
    "サンプルプレビュー · 合成データ"
    "示例预览 · 合成数据"
)
license_labels=(
    "Open source under Apache License 2.0."
    "Apache License 2.0으로 공개되는 오픈소스입니다."
    "Apache License 2.0のオープンソースです。"
    "采用 Apache License 2.0 的开源项目。"
)
current_language_hrefs=(
    './'
    '../ko/'
    '../ja/'
    '../zh-cn/'
)
