# mogui-agent-harness 프롬프트

> 한국어 문서입니다. English: [/PROMPTS.md](../../PROMPTS.md) (원문이 정본입니다. 두 언어가 어긋나면 영어판을 따릅니다.)

하네스를 새 repo에 복사한 뒤 AI host에 붙여넣는 실행용 프롬프트 모음입니다.

> 붙여넣은 뒤 실제로 오가는 대화를 미리 보려면 [bootstrap-walkthrough.md](./bootstrap-walkthrough.md)(worked example)를 읽습니다.

## 상황별 선택

| 상황 | 쓸 프롬프트 |
|---|---|
| 빈 새 프로젝트에 처음 적용 | **1. greenfield init** |
| 코드·문서가 이미 있는 프로젝트에 도입 | **2. 기존 프로젝트 ingest** |
| 팀 repo를 클론한 새 동료 / 멤버 추가 | **3. 동료 온보딩 + 멤버 추가** |
| 에이전트가 시스템을 이해했는지 확인 | **4. self-orientation 점검** |

## 1. 새 프로젝트에 적용 (greenfield init)

> 하네스 파일이 이미 새 프로젝트 루트에 복사돼 있다고 가정합니다(복사와 setup은 README Quick Start 참고). git repo가 아니면 `setup.sh`가 `git init`을 자동으로 실행합니다.

**아래 블록을 통째로 복사해 AI host에 붙여넣습니다.** AI가 파일을 읽고 제품·팀·스택을 물어보며 `{{...}}` 빈칸을 채웁니다. 붙여넣기 전에 파일을 손으로 고칠 필요가 없습니다. 첫 줄 괄호에 제품명과 한 줄 소개를 넣으면 AI가 덜 묻고 더 빨리 채웁니다.

```text
mogui-agent-harness를 이 repo에 적용해 줘. (내 프로젝트: {{product-name}}, {{one-line-intro}})

먼저 현재 host router를 읽고, 이어서 `.agent/Instructions.md`, `.agent/Context.md`, `.agent/Memory.md`를 직접 읽어. 그다음 이 프로젝트 기준으로 `{{...}}` placeholder와 `YYYY-MM-DD`를 치환해.

router 4종(`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`)은 byte 단위로 같아야 해. 하나에서 placeholder를 채운 뒤 그 결과를 나머지 셋에 복사해서 넷을 맞춰. router가 어긋나면 `verify-agent-ssot.sh`가 실패해.

`@git_author`는 `git config user.name` 기준으로 치환해. postmortem 파일명과 frontmatter 작성자도 개인명 고정이 아니라 git author 또는 팀 핸들 정책을 따른다고 명시해.

내가 쓰는 언어를 보고 이 프로젝트의 주 작업 언어를 감지하고, 불확실하면 물어봐. 그다음 언어별 hook을 설정해:
- 프로젝트 언어가 한국어가 아니면: `.claude/settings.json`과 `.codex/hooks.example.json`에서 `no-bak-slang-check`·`remind-korean-style` hook을 제거하고, `.agent/korean-persona.md`를 삭제하고, router 4종에서 "Optional: Korean-language projects" 섹션을 걷어내. 산문 품질은 이 host에 `stop-slop`(github.com/hardikpandya/stop-slop) 같은 de-slop skill이 있으면 문서 작성 때 쓰고, 없으면 평이하게 쓰고 em dash를 피해.
- 프로젝트 언어가 한국어면: 그 두 hook과 `.agent/korean-persona.md`를 유지해. 한국어 가이드를 원하면 `docs/wiki/guides/`를 `docs/wiki/guides/ko/`로 미러링해.
- `no-emoji-check`는 언어와 무관하니 어느 쪽이든 유지해.

의미 있는 결정은 `D-template.md`를 복사해 `docs/wiki/decisions/D-YYYYMMDD-<author>-<slug>.md`로 만들어(오늘 날짜, git author 핸들, 짧은 slug). 하나 쓰고 나면 `bash scripts/decisions-index.sh`를 실행해 index 표를 재생성해. 아직 닫히지 않은 질문은 ADR이 아니라 `.planning/threads/`에 둬.

이전 결정 여러 개가 하나의 논리적 결정으로 합쳐지면, 통합 결정을 새로 만들고 원본들은 `status: collapsed`, `collapsed_to: <id>`로 바꿔. 순번 관리가 없고, 날짜 접두 id는 이름순으로 시간순 정렬돼.

code-review-graph MCP는 코드 구조 탐색의 필수 도구로 설정해. 문서 검색 엔진처럼 설명하지 말고, 코드 구조와 영향 범위를 보는 도구라고 적어.

중요한 guide/ADR/postmortem을 쓰거나 큰 수정을 한 뒤에는 세 문항 이하의 Review Gate Quiz를 내. 긴 작업 뒤에는 다음 에이전트가 이어받을 snapshot을 `docs/wiki/postmortem/temp/`에 남겨.

마지막에 `bash scripts/setup.sh`, `bash scripts/verify-agent-ssot.sh`, `git diff --check` 결과를 보고해.
```

## 2. 기존 프로젝트에 ingest

코드와 문서가 이미 쌓인 repo에 도입할 때 씁니다. **`cp -R .../. .`로 전부 덮어쓰면 기존 `README.md`·`CLAUDE.md`·`.gitignore`가 날아갑니다.** 충돌하는 파일은 따로 복사해 손으로 머지합니다.

```text
mogui-agent-harness 구조를 이 기존 프로젝트에 ingest해 줘. 기존 파일은 덮어쓰지 마.

순서:
1. 하네스 repo 루트에서 `bash scripts/ingest.sh <이-기존-프로젝트-경로>`를 실행해(미리 보려면 `--dry-run`을 먼저). SOURCE는 하네스 repo 루트 자체로 잡히고, 골격을 비파괴로 복사하며, 타깃에 이미 있는 파일은 절대 덮어쓰지 않아. 이미 있으면서 내용이 다른 것(`CLAUDE.md`/`AGENTS.md`/`README.md`/`.gitignore`/`.agent` 파일 등)은 원본 옆에 `*.starter`로 저장돼.
2. `ingest.sh`가 출력한 gap report를 읽어: 추가된 파일, `*.starter`로 대기 중인 파일(수동 머지 필요), 이미 있고 동일한 파일. 차이를 나에게 보고해. `*.starter` 각각의 머지 여부는 내가 정해.
3. router는, `CLAUDE.md`가 이미 있으면 하네스의 "always read before answering" 섹션만 그 안에 머지하고, 그 router를 `AGENTS.md`/`.cursorrules`/`.windsurfrules`에 동기화해.
4. 흩어진 기존 문서의 레이어 분류를 제안해(확정은 내가): 행동 규칙·선호 → `.agent/`, 진행 중 작업 → `.planning/`, 닫힌 결정·가이드·회고 → `docs/wiki/`. 원본을 옮기기 전에 매핑 표를 먼저 보여줘.
5. 기존 README와 노트를 읽어 `.agent/Context.md`와 `.agent/Memory.md`를 초안으로 채우되, 불확실한 건 `{{...}}`로 남기고 나에게 물어봐.
6. 비공식적으로 이미 내려진 결정이 있으면 두 안을 제시해: ADR로 소급 기록(`D-YYYYMMDD-<author>-<slug>` 이름), 또는 새 결정만 ADR로 쌓고 옛것은 참고 자료로 유지. 내가 고른다.
7. setup 전 경고: `setup.sh`는 `git config core.hooksPath .githooks`로 hook 경로를 바꿔. `ingest.sh`가 기존 husky/lefthook 설정을 감지하면 경고를 출력하고 `core.hooksPath`는 직접 건드리지 않아. 그 경고가 떴다면 hook 설치는 건너뛰고 `.githooks/pre-commit`의 frontmatter 자동화만 기존 hook 체인에 머지해. 아니라면 `bash scripts/setup.sh`, `bash scripts/verify-agent-ssot.sh`, `git diff --check`를 실행하고 보고해. router 동기화 검증이 기존 내용과 DRIFT로 나오면 ingest 중에는 정상이야. 머지 후에 다시 맞춰.

금지: 허락 없이 기존 파일 덮어쓰기, 확인 없이 기존 문서를 wiki로 이동.
```

## 3. 동료 온보딩 + 멤버 추가

이미 이 시스템을 쓰는 팀 repo를 처음 클론한 동료용입니다. (a) 본인 온보딩, (b) 팀이 멤버로 추가.

```text
이 repo를 처음 클론한 새 협업자야. 두 가지를 도와줘.

(a) 내 온보딩:
1. host router(`CLAUDE.md` 등)와 `.agent/Instructions.md`, `.agent/Context.md`, `.agent/Memory.md`를 읽고, 이 팀의 일하는 방식을 세 줄로 요약해.
2. 환경 셋업 체크리스트를 줘: `git config user.name`/`user.email` 설정, `bash scripts/setup.sh` 실행, (Codex라면) `.codex/*.example` 로컬 복사, (Cursor라면) 새 chat에서 `.agent` 파일 셋을 읽었는지 확인.
3. `docs/wiki/decisions/`와 `docs/wiki/guides/`에서 "왜 이렇게 하는가"를 담은 핵심 결정 세 개를 골라줘. 먼저 읽어야 할 것들로.

(b) 나를 멤버로 추가:
4. `.agent/Context.md`의 Key People(또는 팀 구성)에 내 역할 한 줄을 더하는 diff를 제안해.
5. 이 팀의 작성자 identity 규칙을 확인해: frontmatter `@git_author`는 커밋 시점에 git identity로 자동 치환되니, 내 git identity로 커밋하면 자동 반영돼. 팀 핸들 정책이 따로 있으면 `.agent/Instructions.md`에서 그 규칙을 찾아 내 핸들 표기법을 알려줘.
6. 변경 후 `bash scripts/verify-agent-ssot.sh`와 `git diff --check`를 실행하고 보고해.
```

## 4. self-orientation 점검 (에이전트가 이해했는가)

게시 후 "파일만 보고 에이전트가 이 시스템을 이해할 수 있는가"를 사람이 확인하는 용도입니다. 새 세션의 에이전트에 붙여넣고 답의 정확도를 봅니다.

```text
이 repo의 파일만 근거로 답해(외부 지식 금지).
1. 이 시스템은 무엇이고, `.agent/`·`.planning/`·`docs/wiki/` 세 레이어의 차이는 뭐야?
2. 내가 "기능 X 만들어줘"라고 하면, 답하기 전에 뭘 먼저 읽고, 결과물은 어디에 남겨?
3. 닫힌 결정과 열린 질문은 각각 어디에 둬?
4. 파일에 없어서 추측한 게 있으면 그대로 말해줘(이게 제일 중요해).
```

## Host별 시작점

| host | 먼저 읽는 router | 비고 |
|---|---|---|
| Claude Code | `CLAUDE.md` | `.claude/settings.json` hook이 있으면 SessionStart/PreToolUse/PostToolUse가 돌 수 있습니다. |
| Codex | `AGENTS.md` | `.codex/hooks.json`과 `.codex/config.toml`은 로컬 파일입니다. example에서 복사합니다. |
| Cursor | `.cursor/rules/agentic-router.mdc` | `.cursorrules`는 legacy fallback입니다. 새 chat에서 `.agent` 파일 셋을 읽었는지 확인합니다. |
| Windsurf | `.windsurfrules` | 기본 제공은 router뿐입니다. |

## 운영 점검 프롬프트

```text
mogui-agent-harness 배선을 점검해 줘.

확인할 것:
- router 4종의 내용이 같은지
- Cursor project rule `.cursor/rules/agentic-router.mdc`와 `.cursor/mcp.json`이 있는지
- `.agent/Instructions.md`, `.agent/Context.md`, `.agent/Memory.md`가 현재 프로젝트 정보로 치환됐는지
- `.codex/hooks.example.json`이 실제로 존재하는 `.codex/hooks/*.sh`만 참조하는지
- `.planning/`과 `docs/wiki/` 골격이 `.gitkeep`으로 보존돼 있는지
- `.agents/skills/postmortem/SKILL.md`가 있고 작성자 기준이 git author인지
- `docs/wiki/_schema/frontmatter.md`가 decision/guide/postmortem/temp snapshot 필드를 설명하는지
- code-review-graph MCP가 코드 구조용 도구로 설명돼 있는지
- Review Gate Quiz와 `docs/wiki/postmortem/temp/` snapshot 규칙이 가이드에 있는지

검증 명령:
`bash scripts/verify-agent-ssot.sh`
`bash scripts/smoke-codex.sh` (Codex 동등성: .codex adapter 파일 파싱과 AGENTS.md == CLAUDE.md)
`git diff --check`
```

## Review Gate Quiz 예시

중요한 문서를 만든 뒤 commit/push/PR 전에 최대 세 문항을 냅니다.

```text
Review Gate Quiz:
1. 이 문서가 확정한 핵심 결정은?
2. 잘못 읽으면 agentic 시스템이 깨지는 지점은?
3. 다음 액션은 어디에 기록해야 하지?
```
