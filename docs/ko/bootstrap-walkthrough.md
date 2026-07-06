# Bootstrap Walkthrough: 빈 repo에서 첫 결정까지

> 한국어 문서입니다. English: [../en/bootstrap-walkthrough.md](../en/bootstrap-walkthrough.md) (원문이 정본입니다. 두 언어가 어긋나면 영어판을 따릅니다.)

mogui-agent-harness를 처음 쓰는 사람이 *실제로 어떤 대화가 오가는지* 미리 볼 수 있게 만든 worked example입니다. 명령어 목록이 아니라 한 세션을 따라간 기록입니다. `README.md`가 "무엇이 들어 있나"를, `PROMPTS.md`가 "무엇을 붙여넣나"를 다룬다면, 이 문서는 "붙여넣은 다음에 무슨 일이 생기나"를 다룹니다.

예시 프로젝트는 가상입니다. **사내 도서 대출 관리 앱(가칭 `booklog`)**, 풀스택 개발자 한 명과 백엔드 동료 한 명. 스택은 TypeScript + Postgres로 가정합니다. 읽으면서 자기 프로젝트로 바꿔 생각하면 됩니다.

세 독자를 염두에 두고 썼습니다.

- **에이전트(AI)**: 새 repo에서 "답하기 전에 무엇을 읽는지"를 똑같이 익힙니다.
- **혼자 쓰는 사람**: 명령어를 외우지 않고 골격을 깔고 빈칸을 채웁니다.
- **팀 동료**: 같은 구조를 자기 프로젝트에 심어 같은 규칙으로 협업합니다.

---

## Step 0: 복사와 setup

새 프로젝트 루트에서 실행합니다. `<source-repo>`는 하네스를 받아 둔 경로입니다.

```bash
rsync -a --exclude .git <source-repo>/ .
chmod +x scripts/*.sh .claude/hooks/*.sh .githooks/* 2>/dev/null || true
bash scripts/setup.sh
```

`rsync -a`는 `.agent`·`.claude` 같은 숨김 폴더까지 전부 복사하고, `--exclude .git`은 하네스 자체의 git 히스토리를 빼고 가져옵니다. 그래서 새 repo는 깨끗한 git 상태로 시작합니다. (`rsync`가 없으면 README Quick Start의 fallback 명령을 씁니다.)

setup 출력은 대략 이렇게 나옵니다.

```text
==> 1/4 Install git hooks
  git hooks enabled (core.hooksPath = .githooks)
==> 2/4 Multi-host router verify
  [OK] host instruction files in sync
==> 3/4 Verify AI tools
  [OK] gstack / GSD / code-review-graph  (없으면 CHECK, 진행은 막지 않음)
==> 4/4 Harness wiring verify
  mogui-agent-harness verify passed.
```

도구가 `CHECK`로 나와도 멈추지 않습니다. 하네스는 골격이지 도구 설치기가 아닙니다.

`setup.sh`를 건너뛰고 AI 세션을 먼저 열면, SessionStart hook이 `.setup-done` 표식이 없는 걸 알아채고 `[AGENT-BOOTSTRAP]` 신호를 내보냅니다. 그러면 에이전트가 사람에게 명령어를 치라고 하는 대신 bootstrap 흐름을 직접 실행합니다.

---

## Step 1: 첫 실행 프롬프트

`PROMPTS.md`의 "1. greenfield init" 프롬프트를 현재 host에 그대로 붙여넣습니다. AI에게 전하는 내용의 핵심:

> mogui-agent-harness를 이 repo에 적용해 줘. 먼저 현재 host router와 `.agent/Instructions.md`, `.agent/Context.md`, `.agent/Memory.md`를 읽어. 그다음 이 프로젝트 기준으로 `{{...}}` placeholder와 `YYYY-MM-DD`를 치환해. 닫힌 결정은 `D-YYYYMMDD-<author>-<slug>`로 이름 짓고, 열린 질문은 `.planning/threads/`로 보내. 마지막에 검증 명령 결과를 보고해.

에이전트는 먼저 읽습니다. 이 단계에서 좋은 에이전트는 *바로 치환하지 않고* 모르는 빈칸부터 묻습니다.

> **에이전트**: router 4종과 `.agent/` 파일 셋을 읽었습니다. 치환하려면 다음이 필요합니다.
> 1. 제품 한 줄 설명과 범위(하는 것과 안 하는 것)
> 2. 팀 구성과 역할
> 3. 스택, 그리고 "조용한 실패"가 잘 생기는 지점(예: migration 적용을 잊는 것)
> 4. 이미 정해진 선호나 규칙

여기서 사람이 답합니다.

> **사람**: 사내 도서 대출 관리 앱이야. 대출, 반납, 연체 알림. 추천 기능과 외부 공개는 범위 밖. 나(풀스택)와 백엔드 동료 한 명. TypeScript + Postgres. migration을 추가하면 로컬 적용을 꼭 확인해야 해. 답변은 짧게, 한국어로.

---

## Step 2: placeholder 치환

에이전트가 `.agent/Context.md`와 `CLAUDE.md`의 빈칸을 채웁니다. 예를 들어 `CLAUDE.md`의 "code safety" 섹션은 이렇게 됩니다.

```markdown
## Code safety (load-bearing)

- migration을 추가하거나 바꾸면 로컬 적용을 확인한다 (`<apply command>`).
- secret과 credential은 출력하지도 커밋하지도 않는다.
- 대출 상태 전이는 transaction으로 처리한다 (중복 대출 방지).
```

`{{product-name}}`은 `booklog`, `{{stack}}`은 `TypeScript + Postgres`, `YYYY-MM-DD`는 오늘 날짜가 됩니다. `@git_author`는 그대로 둡니다. 커밋 시점에 git hook이 `git config user.name`으로 치환합니다.

`.claude/hooks/memory-selfcheck.sh`의 `{{rules-1-to-4}}`도 채웁니다. 이 네 줄은 매 turn "응답 전에 이걸 확인했나"를 에이전트에게 되묻는 장치라, 샘플 문구를 그대로 두면 의미가 없습니다. 이 프로젝트에서 가장 자주 어기는 규칙으로 바꿉니다.

```text
- migration 추가 시 로컬 적용 먼저 확인
- secret 출력 금지
- 답하기 전에 .agent 파일 셋 읽기
- 대출 상태 전이는 transaction으로
```

---

## Step 3: 첫 결정, 열린 질문은 thread로

치환이 끝나면 진짜 작업이 시작됩니다. 닫힌 결정이 하나 나옵니다.

> **사람**: DB는 Postgres로 확정. 동료가 익숙하고 transaction이 필요해서.

에이전트는 `D-template.md`를 `docs/wiki/decisions/D-20260623-dana-postgres-over-sqlite.md`(오늘 날짜, git 핸들, slug)로 복사하고, `bash scripts/decisions-index.sh`를 실행해 index를 재생성합니다. 본문에는 선택지(예: SQLite vs Postgres), 기각 이유, 번복 조건을 기록합니다.

반대로 아직 닫히지 않은 질문은 ADR이 되지 않습니다.

> **사람**: 연체 알림을 이메일로 할지 push로 할지는 아직 모르겠어.

이건 결정 파일로 만들지 않고 `.planning/threads/`에 둡니다. ADR에는 "닫힌 결정"만 둡니다. 결론이 나면 그때 승격합니다.

> 다음 번호를 계산할 필요가 없습니다. 결정 id는 오늘 날짜 + 내 git 핸들 + slug(`D-YYYYMMDD-<author>-<slug>`)라서, 두 사람이 병렬 브랜치에서 써도 충돌하지 않습니다. 파일을 쓴 뒤 `bash scripts/decisions-index.sh`로 index를 갱신합니다.

---

## Step 4: git hook이 하는 일

결정 파일을 커밋하면 pre-commit hook이 두 가지를 자동으로 처리합니다.

```text
[bumped] frontmatter `updated_at:` -> 2026-06-22:
  - docs/wiki/decisions/D-20260623-dana-postgres-over-sqlite.md
[substituted] frontmatter `@git_author` -> <git user.name>:
  - docs/wiki/decisions/D-20260623-dana-postgres-over-sqlite.md
```

`updated_at`을 오늘로 갱신하고 `@git_author`를 실제 커밋 작성자로 치환합니다. prepare-commit-msg hook은 `audit_log`에 한 줄을 덧붙입니다. 사람이 날짜를 매번 손으로 고치지 않아도 됩니다.

`gitleaks`가 설치돼 있으면 secret 스캔도 합니다. 없으면 조용히 건너뜁니다(커밋을 막지 않습니다).

---

## Step 5: 검증

```bash
bash scripts/setup.sh
bash scripts/verify-agent-ssot.sh
bash scripts/wiki-lint.sh
git diff --check
```

- `verify-agent-ssot.sh`: 골격 배선을 확인합니다(4 router 동기화, `.agent` 링크, hook 문법).
- `wiki-lint.sh`: `docs/wiki/` 정합성을 확인합니다(orphan, 깨진 link, 중복 id, dangling relations). 방금 만든 결정 파일이 index에 등록됐는지도 잡아냅니다.
- `git diff --check`: trailing whitespace 같은 잔실수를 잡습니다.

마지막으로 권하는 단계는 *smoke check*입니다. 하네스를 빈 디렉터리에 한 번 복사해 setup/verify를 끝까지 돌려 봅니다. 처음 쓰는 사람이 밟는 경로를 그대로 걸어 봐야 "내 머신에서만 되는" 함정이 드러납니다.

---

## 한 세션이 남긴 것

| 파일 | 들어간 것 |
|---|---|
| `CLAUDE.md` + router 3종 | 제품명, 스택, code safety 규칙 치환 |
| `.agent/Context.md` | 제품 범위, 팀, 스택 요약 |
| `.agent/Memory.md` | "답변은 짧게, 한국어로" 같은 선호 한두 줄 |
| `.claude/hooks/memory-selfcheck.sh` | 이 프로젝트의 load-bearing 규칙 4개 |
| `docs/wiki/decisions/D-20260623-dana-postgres-over-sqlite.md` | 첫 닫힌 결정 (DB = Postgres) |
| `.planning/threads/` | 열린 질문 (알림 방식) |

다음 세션의 에이전트는 이 파일들을 읽고, 사람이 다시 설명하지 않아도 "DB는 Postgres로 정해졌고 알림 방식은 아직 열려 있다"를 압니다. 이 골격의 목적이 그것입니다.

---

## 하네스가 보장하는 것 / 안 하는 것

| 보장 | 보장 안 함 |
|---|---|
| 빈 운영 골격 (레이어, router, hook, wiki, planning) | 제품 지식 (새 프로젝트가 채우는 몫) |
| router 동기화와 `.agent` 링크 배선 검증 | 모든 host에서 동일한 동작 (Cursor는 새 chat에서 직접 확인 필요) |
| 재실행 가능한 setup | 도구 자체 설치 (gstack/GSD/code-review-graph) |

하네스는 출발점이지 framework가 아닙니다. 복사한 뒤 치환·설치·검증은 직접 통과해야 합니다.
