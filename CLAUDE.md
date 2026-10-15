# CLAUDE.md — clean-booking

청소업체 **견적 신청·후기 서비스**를 만드는 개인 프로젝트입니다. 상세 설계는 **`docs/SPEC.md`**에 있고, 작업을 시작하기 전에 반드시 끝까지 읽습니다.

---

## 1. 나에 대해

- 프론트엔드 개발자입니다. Vue 3, React, Next.js, TypeScript, Vite, Pinia를 실무에서 씁니다.
- **Java, Spring, DB는 초보입니다.** 이 프로젝트의 목적은 백엔드를 배우면서 실무형 서비스를 끝까지 만들어 배포하는 것입니다.
- 하루 2~3시간씩, 3~4주 안에 끝내는 것이 목표입니다.
- 개발 PC는 Windows이고, 현재 설치된 DB 도구는 DBeaver뿐입니다. Docker는 쓰지 않습니다.
- 회사에서는 Java 17을 씁니다. 이 프로젝트는 Java 21로 합니다.

## 2. 작업 방식

### 설명
- 응답은 **한국어**로 합니다.
- **백엔드를 처음 배우는 사람도 이해할 수 있게** 설명합니다.
  - 전문 용어는 처음 나올 때 쉬운 말로 풀어 씁니다.
  - 내가 아는 프론트 개념(Vue, React, Next.js)에 빗대 설명합니다. 예: `@Transactional`은 "중간에 실패하면 전부 되돌리는 묶음", DTO는 "API 요청·응답용 타입", Controller는 "Next.js의 API Route 핸들러", Service는 "컴포넌트에서 분리한 비즈니스 로직 함수"
  - 요청이 어디를 거쳐 어디로 가는지는 화살표 흐름도로 보여줍니다. 예: `브라우저 → Controller → Service → Repository → DB`
  - 새 개념은 코드를 쓰기 전에 **3~5줄로 짧게** 설명하고, 코드를 쓴 뒤에는 핵심 줄이 무슨 일을 하는지 짚어줍니다.
  - 내가 "이해가 안 된다"고 하면 같은 설명을 반복하지 말고 다른 예시로 다시 설명합니다.
- 왜 이렇게 하는지 실무 이유를 한 줄 붙입니다. 대안이 있으면 추천 하나만 말하고 넘어갑니다.
- 한 단계가 끝나면 "이번 단계에서 배운 것"을 3줄로 정리합니다.

### 진행
- **한 번에 한 단계만** 합니다. 각 단계는 아래 순서로 진행합니다.
  1. 이번 단계 목표와 만들 파일 목록 안내
  2. 구현
  3. **내가 직접 확인할 방법** 안내: 실행 명령, curl, DBeaver에서 볼 쿼리, 브라우저에서 할 일
  4. 내가 확인했다고 하면 아래 진행 체크리스트를 갱신하고 커밋 메시지 제안
- **내가 확인하기 전에는 다음 단계로 넘어가지 않습니다.**
- 설치, 카카오 콘솔 설정, 비밀값 입력처럼 **내가 직접 해야 하는 일**은 체크리스트로 정확히 안내합니다. 메뉴 위치가 확실하지 않으면 그렇다고 말합니다.
- **비밀값(비밀번호, 카카오 키, JWT secret)을 대화창에 붙여넣으라고 하지 않습니다.** 환경변수나 git에 올라가지 않는 파일에 넣도록 안내합니다.
- 에러가 나면 바로 고치지 말고 **원인을 먼저 설명**한 뒤 고칩니다.
- 설계를 바꿔야 할 것 같으면 먼저 나에게 묻고, 합의하면 `docs/SPEC.md`를 먼저 고친 뒤 코드를 고칩니다.

## 3. 코딩 규칙

### 백엔드
- 의존성은 생성자 주입으로 받습니다(`@RequiredArgsConstructor` + `private final`).
- 엔티티에 setter를 두지 않습니다. 상태 변경은 `changeStatus()`, `hide()`처럼 의미 있는 메서드로 합니다.
- 엔티티를 API 응답으로 그대로 내보내지 않습니다. 요청·응답은 `record` DTO로 만듭니다.
- 컨트롤러는 얇게 두고 로직은 서비스에 둡니다. `@Transactional`은 서비스에만 붙입니다.
- 외부 API 호출(카카오)은 트랜잭션 밖에서 합니다.
- 예외는 `BusinessException(ErrorCode)` 하나로 통일하고 `GlobalExceptionHandler`에서 응답합니다.
- 이름은 축약하지 않습니다(`qt`가 아니라 `quote`).
- 주석은 핵심만 짧게 씁니다. 괄호로 부연 설명을 붙이지 않습니다.

### 프론트
- 모든 파일은 TypeScript(`.ts`, `.tsx`)로 쓰고, 컴포넌트는 함수 컴포넌트와 hooks로 만듭니다.
- API 호출은 `src/api/`의 함수를 통해서만 합니다. 컴포넌트에서 axios를 직접 부르지 않습니다.
- 서버에서 가져오는 데이터는 TanStack Query(`useQuery`, `useMutation`)로 다룹니다. 서버 데이터를 Zustand에 복사해 두지 않습니다.
- Zustand에는 로그인 상태처럼 클라이언트 전역 상태만 둡니다.
- 고객 Access 토큰은 Zustand 메모리에만 둡니다. 관리자 Access 토큰만 sessionStorage에 둡니다(SPEC 6장). localStorage는 쓰지 않습니다.

### 비밀값과 git
- 로컬 비밀값은 백엔드 `backend/src/main/resources/application-local.yml`, 프론트 `frontend/.env.local`에 넣고 git에 올리지 않습니다. 대신 `application-local.example.yml`, `frontend/.env.example`을 커밋합니다.
- 운영 비밀값은 호스팅 서비스의 환경변수에 넣습니다.
- 커밋 메시지는 `feat:`, `fix:`, `docs:`, `style:`, `chore:`, `refactor:` 중 하나로 시작합니다.
- 커밋은 내가 승인한 뒤에만 합니다.

## 4. 작업 순서와 진행 상황

완료한 단계는 `[x]`로 바꾸고, 진행 중 정한 내용이 있으면 해당 단계 아래에 한 줄로 남깁니다.

### 1주차 — 환경과 기반
- [x] **0. 개발 환경 확인**: `java -version`, `git --version`, `node -v` 확인. 없는 것 설치 안내
  - JDK 21, IntelliJ IDEA Community, Git, Node LTS
  - API 테스트 도구: curl 또는 Postman
  - 완료 기준: 위 명령이 모두 버전을 출력하고 Java가 21로 나옴
  - 결정: 이미 설치된 Oracle JDK 21 사용. 회사 프로젝트는 프로젝트별 SDK·toolchain 설정이라 영향 없음. Node는 20.19.6 유지
- [x] **1. 로컬 DB 준비**: 이 PC에 이미 설치된 로컬 MySQL 8.0 서비스 `MySQL80`, `localhost:3306`을 사용
  - 결정: 회사 서버가 아니라 이 PC의 로컬 MySQL입니다. 회사 프로젝트용 로컬 DB와 같은 MySQL에 DB `clean_booking`만 새로 만들고, 그 DB에만 권한이 있는 전용 계정을 씁니다. 기존 DB는 건드리지 않습니다. 8.0은 지원이 끝났지만 로컬 개발용으로 유지
  - DBeaver로 root 접속(SPEC 8장 1번 참고) → DB `clean_booking`과 앱 전용 계정 생성 SQL 안내
  - 완료 기준: 앱 전용 계정으로 DBeaver 접속이 되고, `SELECT NOW();`가 한국 시간, `SHOW VARIABLES LIKE 'character_set_server';`가 `utf8mb4`
  - 결과: DB `clean_booking`, 계정 `clean_booking@localhost` 생성 완료. 전용 계정에는 `clean_booking`과 시스템 DB만 보임. `@@character_set_server`·`@@collation_server`는 `utf8mb4`·`utf8mb4_0900_ai_ci`, `@@time_zone`은 `SYSTEM`
  - 주의: 한국어 Windows라 `system_time_zone` 값이 CP949 한글 "대한민국 표준시"로 들어가 있어 `SHOW VARIABLES`가 `Incorrect string value` 에러를 냄. 설정 확인은 `SELECT @@변수명`으로 함. JDBC URL에 `serverTimezone=Asia/Seoul` 필수. 회사 프로젝트도 쓰는 MySQL이라 `my.ini`는 수정하지 않음
- [x] **2. 저장소와 프로젝트 생성**: git 초기화, `.gitignore`. start.spring.io로 `backend/` 생성(Spring Boot 3.5.x, Java 21, Gradle Groovy). Vite React TypeScript 템플릿으로 `frontend/` 생성
  - 처음 의존성은 Web, JPA, MySQL Driver, Flyway, Validation, Lombok만 넣습니다. **Spring Security는 5단계에서 추가합니다.** 지금 넣으면 모든 API가 기본 로그인 화면으로 막혀서 이 단계의 확인이 안 됩니다
  - `application.yml`(공통)과 `application-local.yml`(비밀값, git 제외) 분리. IntelliJ 실행 설정에서 `local` 프로필 활성화
  - Vite `server.proxy`로 `/api` → `localhost:8080`
  - 완료 기준: 백엔드와 프론트가 둘 다 뜨고, 프론트에서 백엔드 테스트 API 호출 성공
  - 결정: start.spring.io 는 4.x만 제공해서 4.0.8 뼈대를 받은 뒤 `build.gradle`을 Boot 3.5.16 기준으로 다시 씀. Gradle Wrapper는 9.7.1
  - 결정: Gradle 8.14.3은 이 PC에서 빌드 스크립트용 jar를 캐시로 옮기다 `AccessDeniedException`으로 실패함. AhnLab V3 실시간 검사가 새 jar를 잡는 것으로 추정. 9.7.1에서는 같은 빌드가 성공해서 9.7.1로 올림. Boot 3.5.16과 함께 `compileJava`, `bootJar` 정상
  - 결정: 로컬 프로필은 IntelliJ 설정 대신 `application.yml`의 `spring.profiles.active: ${SPRING_PROFILES_ACTIVE:local}` 기본값으로 켬
  - 결정: 확인용 `GET /api/ping`은 `pong`과 DB `NOW()`를 돌려줌. 프론트 템플릿은 React 19, Vite 8, TypeScript 6
  - 주의: Claude가 `gradlew`를 실행할 때는 항상 `--no-daemon`을 붙임. Claude 실행 환경에서 뜬 데몬이 남으면 사용자 터미널 빌드가 그 데몬을 재사용해 엉뚱한 오류를 낼 수 있음
- [x] **3. 스키마와 기초 데이터**: Flyway `V1__init.sql`(SPEC 4장 그대로), `V2__seed.sql`. `ddl-auto: validate`
  - 완료 기준: 앱을 띄우면 DBeaver에서 테이블과 기초 데이터가 보이고 `flyway_schema_history`에 두 줄이 있음
- [ ] **4. 공통 기반**: `BaseTimeEntity`, JPA Auditing, `ErrorCode`·`BusinessException`·`GlobalExceptionHandler`, 페이지 응답 DTO
  - 완료 기준: 일부러 예외를 던지는 임시 API가 SPEC 형식의 JSON 에러를 응답함. 확인 후 임시 API 삭제

### 2주차 — 로그인과 견적
- [ ] **5. 보안과 JWT**: Spring Security·jjwt 의존성 추가, `SecurityConfig`, `JwtProvider`, `JwtAuthenticationFilter`, `SecurityErrorHandler`
  - 완료 기준: 토큰 없이 `/api/my/**` 호출 시 `AUTH_REQUIRED`, 공개 API는 정상 응답
- [ ] **6. 카카오 로그인**: 카카오 개발자 콘솔 설정 안내 → `KakaoClient`, `AuthService`, `AuthController`, Refresh 쿠키 → 프론트 로그인 버튼, 콜백 페이지(StrictMode 중복 실행 대응, SPEC 8장 2번), axios 인터셉터, 새로고침 시 복구
  - 완료 기준: 로그인 후 `users`·`refresh_tokens`에 행이 생기고, `/api/my/profile` 응답, Access 토큰을 10초로 줄였을 때 자동 재발급, 새로고침 후에도 로그인 유지
- [ ] **7. 관리자 로그인**: `Admin` 엔티티, `AdminInitializer`, `/api/admin/auth/login`, 프론트 관리자 로그인
  - 완료 기준: 관리자 토큰으로 `/api/admin/**` 접근 가능, 고객 토큰으로는 `FORBIDDEN`, 관리자 화면에서 새로고침해도 로그인 유지
- [ ] **8. 견적 신청**: 청소유형·옵션·태그 조회, 금액 계산, 견적 신청(번호 생성, 옵션 스냅샷, 첫 상태 이력)
  - 이 단계부터 12단계까지는 API만 만들고 curl로 확인합니다. 화면은 13단계에서 만듭니다
  - 완료 기준: 요청에 금액을 넣어 보내도 무시되고 서버 계산값으로 저장됨. DBeaver에서 `quotes`, `quote_options`, `quote_status_logs`를 조인해서 확인
- [ ] **9. 내 견적**: 목록, 상세, 취소
  - 완료 기준: 다른 회원의 견적 id로 요청하면 `QUOTE_NOT_FOUND`, `RECEIVED`가 아닌 견적은 취소 불가

### 3주차 — 관리자와 후기
- [ ] **10. 관리자 견적 관리**: QueryDSL 설정, 동적 검색 목록, 상세, 상태 변경(전이 규칙, 이력, 낙관적 락)
  - 완료 기준: 잘못된 전이는 409, 같은 `version`으로 두 번 변경하면 두 번째가 `QUOTE_CONCURRENT_MODIFICATION`
- [ ] **11. 후기**: 작성·수정·삭제, 태그, 공개 목록(필터·정렬·페이징), 상세, 요약, 내 후기
  - 완료 기준: 완료 전 견적에는 작성 불가, 중복 작성 불가. 목록 조회 쿼리 수를 로그로 확인하고 N+1 해결
- [ ] **12. 관리자 후기·통계**: 숨김, 베스트, 통계 API
- [ ] **13. 프론트 화면 마무리**: 고객 화면(메인, LIVE 피드, 견적 폼, 내 견적, 후기, 내 후기)과 관리자 화면

### 4주차 — 품질과 배포
- [ ] **14. 테스트**: 금액 계산, 상태 전이, 후기 작성 조건 단위 테스트와 견적 신청 통합 테스트
  - 통합 테스트는 개발 DB를 건드리지 않도록 별도 DB `clean_booking_test`와 `test` 프로필을 씁니다
- [ ] **15. 탈퇴**: soft delete, Refresh 토큰 삭제, 카카오 unlink
- [ ] **16. 배포**: 운영 DB와 백엔드 호스팅 결정(SPEC 9장), 백엔드·프론트 배포, rewrite, 운영 환경변수, 카카오 운영 redirect URI
  - 완료 기준: 운영 주소에서 카카오 로그인부터 후기 작성까지 전체 흐름 동작
- [ ] **17. README**: 소개, 화면, ERD, 기술 스택, 실행 방법, 트러블슈팅(N+1, 동시성, 쿠키 등)

일정이 밀리면 LIVE 피드 → 통계 → 탈퇴 순서로 뺍니다.

## 5. 실행 방법

단계를 진행하면서 실제 명령으로 채웁니다.

```
# DB
# 백엔드
# 프론트
```
