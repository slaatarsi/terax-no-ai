# Terax

**폴더 탐색기와 Git 변경 추적을 갖춘 가벼운 터미널. 내장 AI 에이전트는 없습니다.**

이 버전은 [crynta/terax-ai](https://github.com/crynta/terax-ai)를 수정한 포크이며 [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai)에서 독립적으로 관리됩니다. 원본 프로젝트의 공로는 Crynta와 업스트림 기여자에게 있습니다.

## 기능

- 탭, 분할 패널, 검색, 셸 통합을 지원하는 네이티브 터미널.
- 검색, 파일 관리, 실시간 갱신을 지원하는 폴더 탐색기.
- Git 상태, diff, 스테이징, 커밋, push, 그래프 이력.
- 편집기, 선택적 언어 서버, 미리보기, 테마는 보조 도구로 유지됩니다.

내장 AI 채팅, 에이전트, AI 공급자, AI 자동 완성, 음성 입력은 없습니다. CLI 프로그램은 수동으로 실행할 수 있습니다. 이전 AI 데이터와 외부 훅은 로드되거나 자동 삭제되지 않습니다.

## 소스에서 빌드

Rust stable, Node 22+, pnpm 및 [Tauri 사전 요구 사항](https://tauri.app/start/prerequisites/)이 필요합니다.

```bash
git clone https://github.com/slaatarsi/terax-no-ai.git
cd terax-no-ai
pnpm install
pnpm tauri dev
# 배포 패키지:
pnpm tauri build
```

**주의:** 업데이트 설정은 여전히 업스트림 릴리스를 가리킵니다. 업데이트를 수락하면 이 포크가 원본 버전으로 바뀔 수 있습니다. 업스트림 설치 프로그램과 패키지는 이 AI 없는 버전으로 간주해서는 안 됩니다. 포크 전용 서명은 보장되지 않습니다.

전체 지침과 배포 제한은 [영문 README](../../README.md)를 참고하세요. [문서](../README.md), [기여 가이드](../../CONTRIBUTING.md), [보안](../../SECURITY.md)도 확인하세요. 문제는 이 포크 저장소에 보고해 주세요.

라이선스는 [Apache-2.0](../../LICENSE)입니다. 원본 저작자 표시와 고지는 유지됩니다.
