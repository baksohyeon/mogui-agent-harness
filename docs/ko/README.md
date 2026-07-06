# mogui-agent-harness: 복사해서 바로 쓰는 벤더중립 에이전트 운영 하네스

> 한국어 문서입니다. English: [/README.md](../../README.md) (원문이 정본입니다. 두 언어가 어긋나면 영어판을 따릅니다.)

핵심은 하나입니다. **AI는 세션이 끝나면 그 세션에서 정한 것을 잊습니다.** 그래서 규칙과 진행 상황, 결정을 사람 머릿속 대신 repo 파일에 적어 두고, AI가 일을 시작할 때 그 파일부터 읽게 합니다. 교대 근무자에게 남기는 인수인계 노트와 같습니다. 다음 차례(여기서는 다음 AI 세션)가 노트만 보면 이어서 일합니다.

이 하네스는 그 노트 체계를 새 repo에 한 번에 깔아 줍니다. `.agent/`(세션 규칙), `docs/wiki/`(장기 지식), `.planning/`(작업 진행 상태), Claude·Codex hook, Cursor 설정, code-review-graph(코드 구조 지도)까지 빈 골격으로 들어갑니다.

복사하고 `bash scripts/setup.sh`를 실행하면 빈 골격이 생깁니다. 원본 repo의 제품 결정이나 회고는 따라오지 않습니다. 새 repo는 첫 결정(`D-YYYYMMDD-<author>-<slug>`)부터 자기 결정을 쌓습니다.

> **한국 개발자에게**: 운영 문서(`CLAUDE.md`·`.agent/`·guides)는 영어가 기본이지만 그대로 써도 됩니다. AI host(작업 도구)는 영어 문서를 읽고 한국어로 답합니다. 한국어 프로젝트라면 `no-bak-slang`·`remind-korean-style`·`korean-persona` hook이 한국어 출력 스타일을 잡아 줍니다. 한국어 가이드가 더 필요하면 `docs/wiki/guides/ko/`에 추가합니다.

## Quick Start (빈 새 프로젝트)

두 단계입니다.

- **1단계 (스크립트)**: 아무것도 묻지 않습니다. 빈 골격만 깝니다. 제품 정보는 `{{product-name}}` 같은 placeholder(나중에 채울 빈칸)로 남습니다.
- **2단계 (AI host)**: AI가 제품·팀·스택을 물어보며 그 빈칸을 채웁니다. 그래서 손으로 미리 고칠 필요가 없습니다.

> "프로젝트 init"은 따로 마법사 명령으로 주지 않습니다. 1단계는 스크립트로 파일을 깔고, 2단계는 AI host에 프롬프트를 붙여넣어 대화로 채우는 방식입니다.

### 1단계: 골격 깔기 (질문 0개)

새 repo 루트에서 실행합니다. `setup.sh`는 git repo가 아니면 자동으로 `git init`을 합니다. `git init`을 먼저 하지 않아도 됩니다.

```bash
rsync -a --exclude .git <source-repo>/ .
chmod +x scripts/*.sh .claude/hooks/*.sh .githooks/* 2>/dev/null || true
bash scripts/setup.sh
```

> `rsync`가 필요합니다(macOS·대부분의 Linux에 기본 설치). 없으면: `tar --exclude .git -C <source-repo> -cf - . | tar -C . -xf -` — 하네스의 `.git`만 빼고 파일을 복사해, 타깃에 이미 있는 git 메타데이터를 건드리지 않고 새 repo가 깨끗하게 시작합니다.

`setup.sh`는 git init, git hook 설치, 골격 검증만 합니다. 이 단계에서는 제품 정보를 묻지 않습니다.

> `setup.sh`의 "Verify AI tools" 단계에서 gstack·GSD·code-review-graph가 없으면 경고가 뜹니다. 이 경고가 떠도 setup이 실패한 건 아닙니다. 골격은 이 도구들 없이도 동작합니다. 실제로 쓸 도구만 `CLAUDE.md`의 Install 명령으로 깝니다.

#### init commit을 분리하고 싶을 때

하네스 원형을 커밋으로 남기고 싶다면 1단계 직후 바로 커밋합니다.

```bash
git add .
git commit -m "chore: initialize mogui-agent-harness"
```

그다음 2단계로 빈칸을 채웁니다. 이렇게 하면 "하네스를 처음 깐 커밋"과 "우리 프로젝트 값으로 채운 커밋"이 나뉩니다. 나중에 원형과 프로젝트별 수정분을 비교하기 쉽습니다.

Codex를 쓸 머신에서는 로컬 설정 파일을 만듭니다. 이 두 파일은 `.gitignore` 대상입니다.

```bash
cp .codex/hooks.example.json .codex/hooks.json
cp .codex/config.example.toml .codex/config.toml
```

### 2단계: 내용 채우기 (AI가 물어봅니다)

`PROMPTS.md`의 **"1. greenfield init"** 프롬프트를 통째로 복사해 지금 쓰는 AI host(Claude Code / Codex / Cursor 등)에 붙여넣습니다. 그러면 AI가 router와 `.agent/` 파일을 읽고, 제품·팀·스택·첫 결정을 물어보며 `{{...}}` 빈칸을 채우고 첫 결정을 만듭니다. 빈칸을 손으로 미리 고치지 않아도 됩니다.

붙여넣은 뒤 실제로 어떤 대화가 오가는지는 [bootstrap-walkthrough.md](./bootstrap-walkthrough.md)(한국어판)에서 미리 볼 수 있습니다.

### 기존 프로젝트라면? ingest를 쓰세요 (비파괴)

위 Stage 1 복사 명령은 빈 repo용입니다. 이미 코드·문서가 있는 repo에선 그대로 쓰면 안 됩니다. 기존 `README.md`·`CLAUDE.md`·`.gitignore`를 덮어씁니다. 대신 `scripts/ingest.sh`를 씁니다.

```bash
bash <하네스-repo-경로>/scripts/ingest.sh <기존-프로젝트-경로>
```

`--dry-run`을 붙이면 아무것도 쓰지 않고 gap report만 미리 봅니다. 또는 `PROMPTS.md`의 **"2. ingest into an existing project"** 프롬프트를 붙여넣어 AI host가 실행하고 머지를 안내하게 할 수도 있습니다. 무엇을 하고 왜 안전한지:

- **git 히스토리는 안 건드립니다.** `ingest.sh`는 대상의 git 히스토리를 건드리지 않고, `git config core.hooksPath`도 직접 실행하지 않습니다.
- **기존 파일은 절대 안 덮어씁니다.** ingest는 `rsync -a --ignore-existing`(없으면 `cp -Rn`)로 골격을 복사해, 이미 있는 건 그대로 두고 없는 것만 더합니다.
- **`docs/` 이름이 겹쳐도 괜찮습니다.** 하네스가 더하는 건 `docs/wiki/`·`docs/en/`·`docs/ko/`뿐입니다. `--ignore-existing` 덕에 기존 `docs/` 파일은 유지되고 하네스의 디렉터리만 옆에 더해집니다. 이미 `docs/wiki/`가 있으면 하네스 사본을 `*.starter` 이름으로 옆에 두고 diff를 보여줘, 머지를 직접 정합니다.
- **충돌하는 최상위 파일과 `.agent/` 디렉터리**(`CLAUDE.md`·`README.md`·`.gitignore`·`.agent/`)는 덮어쓰지 않고 `*.starter` 이름으로 옆에 둡니다. 머지는 손으로 합니다.
- **husky나 lefthook을 이미 쓴다면** `ingest.sh`가 이를 감지해 경고만 출력하고 hook은 건드리지 않습니다. `setup.sh`는 `core.hooksPath`를 `.githooks`로 바꿔 기존 체인을 가로챌 수 있으므로, 그 경고가 뜨면 hook 설치는 건너뛰고 `.githooks/pre-commit`의 frontmatter 자동화만 기존 hook에 머지합니다.

이미 이 시스템을 쓰는 repo를 클론한 동료는 **"3. coworker 온보딩"**을 씁니다.

## 어떻게 동작하나

앞에서 말한 인수인계 노트를 세 칸으로 나눠 둡니다. host router(AI가 세션을 시작할 때 먼저 읽는 진입점)가 AI를 필요한 칸으로 안내합니다.

```text
host router (CLAUDE.md / AGENTS.md / .cursorrules / .windsurfrules)
  -> .agent/      세션 규칙 + 압축한 제품·팀·스택 컨텍스트
  -> .planning/   작업 진행 상태 + 이어받기 슬롯
  -> docs/wiki/   사람이 승인한 장기 지식
  -> code-review-graph MCP   코드 구조 지도
```

세 칸은 맡는 일이 다릅니다.

- **`.agent/`**: 지금 세션에서 AI가 어떻게 행동할지 정합니다. 규칙, 압축한 제품·팀·스택 컨텍스트, 러닝 메모리를 둡니다. 결정 원문이나 긴 회의록은 넣지 않습니다.
- **`.planning/`**: 작업 진행 상태입니다. GSD(작업을 슬롯으로 나눠 관리하는 도구)의 workstream·quick·todo·thread·seed가 여기 들어갑니다. 실행 중인 plan은 아직 확정 지식으로 보지 않습니다.
- **`docs/wiki/`**: 사람이 승인한 장기 지식입니다. 닫힌 결정(`decisions/D-*.md`), 반복 규칙(`guides/`), 사고와 교훈(`postmortem/`)을 둡니다.
- **code-review-graph**: 코드 구조(import·호출 관계·변경 영향)를 보는 지도입니다. 결정 이유는 여기서 찾지 않고 wiki에서 찾습니다.

### 요청이 들어오면 AI가 하는 일

정리되지 않은 요청이 들어오면, AI는 파일을 쓰기 전에 먼저 분류합니다.

```text
요청
  -> 기존 decisions/guides + .agent 컨텍스트 읽기
  -> 규모와 확신 판단
  -> 라우팅 (아래 표)
  -> 실행하거나, 꼭 필요한 최소 질문만 던지기
  -> 검증 후 닫거나, 이어받기 snapshot 남기기
```

| 작업 | 어디로 |
|---|---|
| 작은 직접 수정 | direct / fast |
| 작지만 잃으면 안 되는 것 | `.planning/quick/` |
| 실행 가능하지만 지금은 아닌 것 | `.planning/todos/` |
| 닫히지 않은 결정 질문 | `.planning/threads/` |
| 확신 낮은 아이디어 | `.planning/seeds/` |
| 여러 단계 작업 | `.planning/workstreams/` |
| 닫힌 결정 | `docs/wiki/decisions/D-*.md` |
| 반복 규칙 | `docs/wiki/guides/` |
| 사고나 교훈 | `docs/wiki/postmortem/` |

## 가이드

더 자세한 문서는 `docs/wiki/guides/`에 있습니다. 위 요약으로 흐름을 잡고, 필요한 부분만 아래에서 봅니다.

- [Onboarding](../wiki/guides/01-onboarding.md): 사람·새 AI 세션의 시작점
- [Agentic Architecture](../wiki/guides/02-agentic-architecture.md): `.agent` / `.planning` / `docs/wiki` 분리, 상세
- [Host Runtime and Hooks](../wiki/guides/03-host-runtime-and-hooks.md): Claude Code·Codex·Cursor가 컨텍스트를 읽고 hook을 도는 법
- [GSD + LLM Wiki Agent Flow](../wiki/guides/04-gsd-llm-wiki-agent-flow.md): 요청이 진행 상태와 장기 지식 사이를 라우팅되는 법
- [Decisions and Postmortems](../wiki/guides/05-decisions-and-postmortems.md): ADR(결정 기록)과 postmortem 쓰는 법
- [Maintenance](../wiki/guides/maintenance.md): 운영 문서를 오래 유지하는 법

## 들어 있는 것

| 경로 | 역할 |
|---|---|
| `CLAUDE.md` `AGENTS.md` `.cursorrules` `.windsurfrules` | host router 4종. 내용은 같아야 합니다. |
| `.cursor/rules/agentic-router.mdc` `.cursor/mcp.json` | Cursor project rule adapter와 code-review-graph MCP 설정 |
| `.agent/` | 세션 운영 규칙, 압축 컨텍스트, 러닝 메모리 |
| `.agent/workflows/` | AI가 반복해서 따르는 내부 workflow (`triple-crown.md` 규모별 5 Phase, `automation-patterns.md` 성격별 4 패턴) |
| `.agent/loops/` | loop engineering 레이어: `LOOP.md` 루프 레지스트리(예산·kill switch·L1-L3 성숙도 사다리) + `daily-triage` read-only L1 루프(상태 파일 + append-only run log) |
| `.agents/skills/postmortem/` `.agents/skills/scope/` `.agents/skills/daily-triage/` | 증거 기반 postmortem 작성 skill, 작업 규모 판정 scope skill, daily-triage 루프 skill. 작성자는 git author 기준 |
| `.claude/` | Claude Code hook adapter와 `.claude/commands/scope.md` 슬래시 커맨드 |
| `.codex/` | Codex hook/MCP adapter template |
| `.githooks/` | wiki frontmatter와 audit log 보조 hook |
| `.planning/` | GSD 실행 상태 골격 |
| `docs/wiki/` | LLM wiki 골격. decisions/guides/postmortem/schema 포함 |
| `scripts/` | setup, git hook install, 하네스 wiring verify, ingest, Codex 동등성 smoke |
| `PROMPTS.md` | 첫 실행과 운영 점검 프롬프트 |
| `docs/en/bootstrap-walkthrough.md` | 빈 repo에서 첫 결정까지 한 세션을 따라간 worked example |
| `docs/ko/` | 이 README·`PROMPTS.md`·walkthrough의 한국어판 |

## 채울 값 (보통 2단계에서 처리)

아래는 greenfield 프롬프트가 묻고 채우는 값입니다. 직접 편집해도 되지만 손으로 다 채울 필요는 없습니다. 2단계에서 AI가 대화로 처리합니다. 이 목록은 무엇이 채워지는지 확인하는 용도입니다.

- `{{product-name}}`, `{{repo}}`, `{{team}}`, `{{stack}}`, `{{domain}}`
- `YYYY-MM-DD`
- `@git_author`: staged docs frontmatter에서는 git hook이 `git config user.name`으로 자동 치환합니다. 첫 적용 때 직접 확인합니다.
- `.agent/Memory.md`의 초기 preference/correction
- `.agent/Context.md`의 제품 범위, 팀원, 기술 스택, 첫 결정
- `CLAUDE.md`의 코드 안전 규칙, 브랜치 정책, 검증 명령
- `.claude/hooks/memory-selfcheck.sh`의 `{{rule-1}}`부터 `{{rule-4}}`
- Cursor를 쓰면 새 chat에서 `.agent/Instructions.md`, `.agent/Context.md`, `.agent/Memory.md`를 읽었는지 확인합니다.

## 운영 규칙

- `.agent/`는 세션 운영 레이어입니다. 회의록이나 긴 실행 상태를 넣지 않습니다.
- `.planning/`은 GSD 실행 상태입니다. 열린 질문은 `threads/`, 작은 작업은 `quick/`, 낮은 확신은 `seeds/`, 큰 작업은 `workstreams/`로 보냅니다.
- `docs/wiki/`는 장기 지식입니다. 닫힌 결정은 `decisions/D-*.md`, 반복 규칙은 `guides/`, 사고와 교훈은 `postmortem/`에 둡니다.
- code-review-graph MCP는 코드 구조용입니다. 문서 검색 엔진처럼 쓰지 않습니다.
- 중요한 guide/ADR/postmortem을 만든 뒤에는 Review Gate Quiz를 최대 세 문항으로 냅니다.
- 긴 작업 뒤에는 `docs/wiki/postmortem/temp/`에 이어받기 snapshot을 남깁니다.
- postmortem 작성자는 개인명을 고정하지 않고 git author를 기준으로 합니다. 팀 핸들 정책이 따로 있으면 `.agent/Instructions.md`에 적습니다.

## Hook 옵션

greenfield init 프롬프트(`PROMPTS.md`)가 프로젝트 언어를 보고 한국어 전용 hook 설정을 정합니다. 한국어 프로젝트면 유지하고, 아니면 제거합니다. 아래 표는 수동 참고용입니다.

| hook | 기본 | 설명 |
|---|---|---|
| `load-context.sh` | 유지 | SessionStart에서 `.agent/Context.md`만 출력하고 Instructions/Memory는 직접 읽게 안내합니다. |
| `setup-check.sh` | 유지 | `.setup-done`이 없으면 `[AGENT-BOOTSTRAP]`를 내보내, 에이전트가 라우터의 autonomous bootstrap 흐름을 직접 실행하게 합니다(yes/no로 묻지 않음). |
| `memory-health.sh` | 권장 | repo명 기반 archive 경로와 Memory stale 상태를 경고합니다. |
| `memory-selfcheck.sh` | 권장 | 매 turn 중요한 사용자 피드백 규칙을 확인하게 합니다. placeholder 치환 필수. |
| `wiki-health.sh` | 권장 | active wiki 문서의 `last_verified_at`가 180일을 넘으면 경고합니다. |
| `no-emoji-check.sh` | 선택 | 이모지를 막고 텍스트 대안을 쓰게 합니다. |
| `no-bak-slang-check.sh` | 한국어 프로젝트 선택 | 한국어 직역 슬랭을 막습니다. 한국어 프로젝트가 아니면 settings에서 제거합니다. |
| `remind-korean-style.sh` | 한국어 프로젝트 선택 | 한국어 응답 스타일을 점검하게 합니다. 한국어 프로젝트가 아니면 settings에서 제거합니다. |

## 검증

```bash
bash scripts/setup.sh
bash scripts/verify-agent-ssot.sh
bash scripts/wiki-lint.sh
bash scripts/smoke-codex.sh
git diff --check
```

`wiki-lint.sh`는 `docs/wiki/`의 정합성(orphan·깨진 link·중복 id·dangling relations 등)을 점검합니다. python3만 있으면 됩니다. package.json이 있으면 `"wiki:lint": "bash scripts/wiki-lint.sh"` 별칭을 둬도 됩니다.

`smoke-codex.sh`는 Claude/Codex 동등성을 점검합니다. `.codex/` adapter 파일이 파싱되는지, 참조하는 hook 스크립트가 실제로 있는지, `AGENTS.md`가 `CLAUDE.md`와 byte 단위로 같은지 확인합니다. `codex` CLI가 있으면 라이브 동작 확인도 제안하고, 없으면 정적 검사만 돕니다.
