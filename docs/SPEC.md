# 청소 견적·후기 서비스 설계서 (SPEC)

> 이 문서가 설계의 기준입니다. 구현 중 설계를 바꿔야 하면 먼저 사용자와 합의하고 이 문서를 갱신한 뒤 코드를 고칩니다.

---

## 1. 개요

**한 청소업체**의 고객용 웹사이트와 관리자 화면입니다.

- **고객**: 카카오 로그인 → 청소 견적 신청 → 진행 상태 확인 → 청소 완료 후 후기 작성
- **관리자**: 견적 상태 관리, 후기 숨김·베스트 지정, 간단한 통계
- **화면 참고**: 영구크린 메인(https://www.mcygclean.com/main/index.jsp)의 견적 신청, LIVE 견적 현황, 칭찬후기 구성
  - **영구크린의 이름·로고·문구·이미지는 쓰지 않습니다.** 가상 브랜드로 만들고 화면 구성만 참고합니다.

### 범위

| 포함 | 제외 |
|---|---|
| 카카오 로그인, 관리자 로그인 | 지점 개념 |
| 견적 금액 계산, 신청, 취소, 상태 관리 | 결제 |
| 후기 작성·수정·삭제, 태그, 평점 요약 | 비회원 견적 |
| 관리자 후기 관리, 통계 | 후기 이미지 업로드 |
| LIVE 견적 피드 | 알림톡·문자 실제 발송 |
| 배포 | |

일정이 밀리면 **LIVE 피드 → 통계 → 탈퇴** 순서로 뺍니다.

---

## 2. 기술 스택

| 영역 | 선택 |
|---|---|
| 언어 | Java 21 |
| 백엔드 | Spring Boot 3.5.x, Spring Web, Spring Data JPA, Spring Security, Validation, Lombok |
| 동적 쿼리 | QueryDSL, 관리자 견적 검색 단계에서 도입 |
| 인증 | JWT (jjwt 0.12.x), 카카오 로그인 REST API 방식 |
| DB | MySQL 8, Flyway. 운영 버전은 배포 단계에서 결정 |
| 로컬 DB 실행 | 이 PC에 이미 설치된 로컬 MySQL 8.0 Windows 서비스 `localhost:3306`, 전용 DB·계정 분리, Docker 사용 안 함 |
| DB 클라이언트 | DBeaver |
| 빌드 | Gradle (Groovy) |
| 프론트 | React + TypeScript + Vite, React Router, Zustand, TanStack Query, axios |
| 테스트 | JUnit 5, Spring Boot Test |

---

## 3. 폴더 구조

```
clean-booking/
├── CLAUDE.md
├── docs/SPEC.md
├── backend/
│   └── src/main/java/com/example/cleanbooking
│       ├── CleanBookingApplication.java
│       ├── global
│       │   ├── config     SecurityConfig, JpaConfig, AppProperties
│       │   ├── entity     BaseTimeEntity
│       │   ├── error      ErrorCode, BusinessException, ErrorResponse, GlobalExceptionHandler
│       │   └── security   Role, AuthUser, JwtProperties, JwtProvider, JwtAuthenticationFilter, SecurityErrorHandler
│       ├── auth           AuthController, AuthService, RefreshToken, RefreshCookieManager
│       │   ├── dto
│       │   └── kakao      KakaoClient, KakaoProperties, 카카오 응답 DTO
│       ├── user           User, UserService, MyProfileController
│       ├── admin          Admin, AdminAuthController, AdminInitializer
│       ├── catalog        CleaningType, CleaningOption, Tag, 조회 API
│       ├── quote          Quote, QuoteOption, QuoteStatus, QuoteStatusLog, 고객·관리자 API
│       └── review         Review, ReviewTag, 고객·관리자 API
└── frontend/
    └── src
        ├── api          axios 인스턴스, 도메인별 API 함수
        ├── stores       Zustand, 로그인 상태
        ├── hooks        TanStack Query 훅 등 재사용 훅
        ├── components   공용 컴포넌트
        ├── routes.tsx   React Router 라우트 정의와 로그인 가드
        └── pages
            ├── customer   Home, QuoteForm, MyQuotes, MyQuoteDetail, ReviewList, ReviewForm, MyReviews, Login, KakaoCallback
            └── admin      AdminLogin, AdminQuotes, AdminQuoteDetail, AdminReviews, AdminStats
```

- 백엔드는 **기능별 패키지**로 나누고, 여러 기능이 같이 쓰는 것만 `global`에 둡니다.
- 한 패키지 안의 파일은 `controller/service/repository` 하위 폴더로 더 나누지 않습니다. 파일 수가 적어서 오히려 찾기 어려워집니다.

---

## 4. DB 스키마

`backend/src/main/resources/db/migration/V1__init.sql`

```sql
CREATE TABLE users (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  kakao_id       BIGINT       NOT NULL UNIQUE,
  nickname       VARCHAR(50)  NOT NULL,
  email          VARCHAR(100) NULL,
  last_login_at  DATETIME     NOT NULL,
  deleted_at     DATETIME     NULL,
  created_at     DATETIME     NOT NULL,
  updated_at     DATETIME     NOT NULL
);

CREATE TABLE admins (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  login_id       VARCHAR(30)  NOT NULL UNIQUE,
  password_hash  VARCHAR(100) NOT NULL,
  name           VARCHAR(30)  NOT NULL,
  created_at     DATETIME     NOT NULL
);

CREATE TABLE refresh_tokens (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id     BIGINT       NOT NULL,
  token_hash  VARCHAR(100) NOT NULL UNIQUE,
  expires_at  DATETIME     NOT NULL,
  created_at  DATETIME     NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE cleaning_types (
  id                BIGINT AUTO_INCREMENT PRIMARY KEY,
  code              VARCHAR(20) NOT NULL UNIQUE,
  name              VARCHAR(30) NOT NULL,
  price_per_pyeong  INT         NOT NULL,
  active            BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE options (
  id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  name    VARCHAR(30) NOT NULL,
  price   INT         NOT NULL,
  active  BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE quotes (
  id                BIGINT AUTO_INCREMENT PRIMARY KEY,
  quote_no          VARCHAR(20)  NOT NULL UNIQUE,
  user_id           BIGINT       NOT NULL,
  cleaning_type_id  BIGINT       NOT NULL,
  customer_name     VARCHAR(30)  NOT NULL,
  customer_phone    VARCHAR(20)  NOT NULL,
  sido              VARCHAR(20)  NOT NULL,
  sigungu           VARCHAR(30)  NOT NULL,
  address_detail    VARCHAR(100) NOT NULL,
  area_pyeong       INT          NOT NULL,
  wish_date         DATE         NOT NULL,
  request_memo      VARCHAR(500) NULL,
  estimated_price   INT          NOT NULL,
  status            VARCHAR(20)  NOT NULL,
  version           INT          NOT NULL DEFAULT 0,
  created_at        DATETIME     NOT NULL,
  updated_at        DATETIME     NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (cleaning_type_id) REFERENCES cleaning_types(id),
  INDEX idx_quotes_user_created (user_id, created_at),
  INDEX idx_quotes_status_created (status, created_at)
);

CREATE TABLE quote_options (
  quote_id      BIGINT NOT NULL,
  option_id     BIGINT NOT NULL,
  option_price  INT    NOT NULL,
  PRIMARY KEY (quote_id, option_id),
  FOREIGN KEY (quote_id) REFERENCES quotes(id),
  FOREIGN KEY (option_id) REFERENCES options(id)
);

CREATE TABLE quote_status_logs (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  quote_id     BIGINT       NOT NULL,
  from_status  VARCHAR(20)  NULL,
  to_status    VARCHAR(20)  NOT NULL,
  admin_id     BIGINT       NULL,
  memo         VARCHAR(200) NULL,
  created_at   DATETIME     NOT NULL,
  FOREIGN KEY (quote_id) REFERENCES quotes(id),
  FOREIGN KEY (admin_id) REFERENCES admins(id)
);

CREATE TABLE reviews (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  quote_id       BIGINT       NOT NULL UNIQUE,
  rating         INT          NOT NULL,
  title          VARCHAR(100) NOT NULL,
  content        TEXT         NOT NULL,
  hidden         BOOLEAN      NOT NULL DEFAULT FALSE,
  hidden_reason  VARCHAR(200) NULL,
  best           BOOLEAN      NOT NULL DEFAULT FALSE,
  deleted_at     DATETIME     NULL,
  created_at     DATETIME     NOT NULL,
  updated_at     DATETIME     NOT NULL,
  FOREIGN KEY (quote_id) REFERENCES quotes(id),
  INDEX idx_reviews_created (created_at)
);

CREATE TABLE tags (
  id    BIGINT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE review_tags (
  review_id  BIGINT NOT NULL,
  tag_id     BIGINT NOT NULL,
  PRIMARY KEY (review_id, tag_id),
  FOREIGN KEY (review_id) REFERENCES reviews(id),
  FOREIGN KEY (tag_id) REFERENCES tags(id)
);
```

`V2__seed.sql`에는 청소 유형, 옵션, 태그 기초 데이터만 넣습니다. 관리자 계정은 SQL에 비밀번호 해시를 넣지 않고, 앱이 시작될 때 관리자가 한 명도 없으면 설정값 `ADMIN_LOGIN_ID`, `ADMIN_PASSWORD`로 만듭니다(`AdminInitializer`). 이 값은 로컬에서는 `application-local.yml`, 운영에서는 환경변수에 둡니다.

| 기초 데이터 | 예시 |
|---|---|
| 청소 유형 | `MOVE_IN` 입주청소, `MOVE_OUT` 이사청소, `LIVING` 거주청소 |
| 옵션 | 베란다 청소, 곰팡이 제거, 새집증후군 시공, 줄눈 시공 |
| 태그 | 응대가 친절해요, 꼼꼼해요, 시간 약속을 잘 지켜요, 추가비용이 없어요, 다시 이용하고 싶어요 |

### 설계 의도

| 항목 | 이유 |
|---|---|
| `estimated_price`, `option_price` 스냅샷 | 나중에 단가가 바뀌어도 이미 받은 견적 금액은 그대로 유지 |
| `quotes.version` | 관리자 상태 변경이 동시에 들어오면 낙관적 락(`@Version`)으로 충돌 감지 |
| `reviews.quote_id UNIQUE` | 후기 중복 작성을 DB 제약으로도 차단 |
| `hidden`과 `deleted_at` 분리 | 관리자 숨김과 고객 삭제는 의미와 복구 정책이 다름 |
| `quotes.customer_name/phone` | 로그인한 사람과 현장 연락처가 다를 수 있음. 카카오에서 전화번호를 받으려면 비즈앱 검수가 필요해서 폼으로 받음 |
| `reviews`에 `user_id` 없음 | 작성자는 `review → quote → user`로 알 수 있음 |
| `refresh_tokens`에 해시만 저장 | DB가 유출돼도 토큰을 그대로 쓸 수 없음 |
| `users.deleted_at` | 탈퇴해도 견적·후기 이력은 남겨야 함 |

---

## 5. 비즈니스 규칙

### 견적 상태

```
RECEIVED → CONSULTING → CONFIRMED → COMPLETED
   └──────────┴────────────┴──→ CANCELED
```

- 허용 전이는 `QuoteStatus` enum의 `canTransitTo()`에 둡니다.
- 고객은 `RECEIVED`일 때만 취소할 수 있습니다.
- `COMPLETED`, `CANCELED`는 최종 상태입니다.
- 상태를 바꿀 때마다 `quote_status_logs`에 기록하고, 상태 변경과 이력 저장은 한 트랜잭션입니다.
- 관리자 상태 변경 요청의 `version`이 현재 견적의 `version`과 다르면 `QUOTE_CONCURRENT_MODIFICATION`입니다. 이 비교는 서비스에서 직접 하고, 전이 규칙 검사보다 먼저 합니다. `@Version`만으로는 "화면을 연 뒤 다른 관리자가 먼저 바꾼 경우"를 잡지 못합니다.
- 견적을 신청할 때도 `from_status = NULL → RECEIVED` 이력을 남깁니다.

### 견적 금액과 입력값

- 금액은 `평수 × 청소유형 평당 단가 + 선택 옵션 가격 합`입니다.
- **프론트가 보낸 금액은 믿지 않습니다.** 신청할 때 서버가 다시 계산해서 저장합니다.
- 평수는 1~200, 희망일은 내일부터 60일 이내입니다.
- 비활성(`active = false`) 청소유형·옵션은 선택할 수 없습니다.
- 견적번호는 `Q` + `yyMMdd` + 대문자·숫자 6자리 랜덤입니다(예: `Q261006A7K2QX`). 중복되면 다시 만듭니다.

### 후기

- `COMPLETED`인 본인 견적에만 쓸 수 있고, 견적 하나에 후기 하나입니다.
- 평점은 1~5, 태그는 최대 3개입니다.
- 공개 목록에는 `hidden = false AND deleted_at IS NULL`인 후기만 나옵니다.

### LIVE 피드

- 최근 견적 10건을 `김OO · 강남구 · 12:08` 형태로 보여줍니다.
- 이름은 첫 글자만 남기고 나머지는 `OO`로 가립니다.

### 탈퇴

- `users.deleted_at`을 기록하고 Refresh 토큰을 모두 지운 뒤, 카카오 연결 끊기(unlink)를 호출합니다. unlink에는 카카오 **Admin 키**가 필요합니다.
- 탈퇴한 사람이 다시 카카오로 로그인하면 기존 계정을 복구합니다.

---

## 6. 인증

### 카카오 로그인 흐름

```
1. [프론트] https://kauth.kakao.com/oauth/authorize?client_id=...&redirect_uri=...&response_type=code&state=랜덤값
2. [카카오] 로그인·동의 후 redirect_uri?code=XXX&state=랜덤값 으로 이동
3. [프론트] state 일치 확인 → POST /api/auth/kakao { code }
4. [백엔드] code 로 카카오 토큰 교환 → 사용자 정보 조회 → kakao_id 로 회원 조회, 없으면 가입
           → 자체 Access JWT 는 응답 본문으로, Refresh 토큰은 HttpOnly 쿠키로 발급
5. [프론트] Access 토큰은 Zustand 메모리에만 두고 Authorization: Bearer 로 전송
```

- 카카오 토큰은 사용자 정보를 조회할 때만 쓰고 저장하지 않습니다.
- 카카오 API 호출은 **DB 트랜잭션 밖**에서 합니다. 응답을 기다리는 동안 DB 커넥션을 잡지 않기 위해서입니다.
- REST API 키는 프론트에 있어도 되지만, Client Secret과 Admin 키는 백엔드에만 둡니다. 로컬은 `application-local.yml`, 운영은 환경변수입니다.

### 토큰

| 항목 | 값 |
|---|---|
| Access 토큰 | JWT, claim에 `sub`(id)와 `role`(`USER`/`ADMIN`). 고객 30분, 관리자 8시간 |
| Refresh 토큰 | 랜덤 32바이트 문자열, 14일, DB에는 SHA-256 해시만 저장 |
| Refresh 쿠키 | `HttpOnly`, `Path=/api/auth`, `SameSite=Lax`, 운영에서만 `Secure` |
| 재발급 | 쓴 Refresh 토큰은 지우고 새로 발급 |
| 새로고침 | 메모리의 Access 토큰이 사라지므로 앱 시작 시 `/api/auth/refresh`로 복구 |

- JWT 필터에서 생긴 예외는 `@RestControllerAdvice`까지 가지 않습니다. 필터는 에러 코드를 request attribute에 담기만 하고, `AuthenticationEntryPoint`가 JSON 에러를 응답합니다.
- 관리자는 아이디·비밀번호(BCrypt)로 로그인하고 `role = ADMIN` JWT를 받습니다. 관리자에게는 Refresh 토큰을 발급하지 않습니다.
  - 그래서 관리자 Access 토큰은 메모리가 아닌 **sessionStorage**에 둡니다. 메모리에만 두면 새로고침할 때마다 다시 로그인해야 하기 때문입니다. 탭을 닫으면 로그아웃됩니다.

### 경로별 권한

| 경로 | 권한 |
|---|---|
| `/api/auth/**`, `/api/admin/auth/**` | 누구나 |
| `/api/my/**` | USER |
| `/api/admin/**` | ADMIN |
| 그 외 `/api/**` | 누구나 |

### 프론트·백엔드 연결 방식

- **로컬과 운영 모두 프록시로 같은 출처를 만듭니다.**
  - 로컬: Vite `server.proxy`로 `/api` → `http://localhost:8080`
  - 운영: 프론트 호스팅의 rewrite로 `/api/*` → 백엔드
- 그래서 axios `baseURL`은 비워 두고, CORS 설정도 하지 않습니다. 도메인이 다르면 Safari가 Refresh 쿠키를 막기 때문에 이렇게 합니다.

---

## 7. API

### 공통 에러 응답

```json
{ "code": "QUOTE_INVALID_STATUS_TRANSITION", "message": "완료된 견적은 상태를 변경할 수 없습니다." }
```

| code | HTTP | 언제 |
|---|---|---|
| `INVALID_INPUT` | 400 | 입력값 검증 실패 |
| `AUTH_REQUIRED` | 401 | 토큰 없음 |
| `AUTH_TOKEN_INVALID` | 401 | 위조되었거나 형식이 틀린 토큰 |
| `AUTH_TOKEN_EXPIRED` | 401 | Access 토큰 만료. 프론트는 refresh 호출 |
| `AUTH_REFRESH_INVALID` | 401 | Refresh 토큰이 없거나 만료됨. 다시 로그인 |
| `AUTH_KAKAO_FAILED` | 401 | 카카오 인가 코드가 잘못됐거나 만료됨 |
| `ADMIN_LOGIN_FAILED` | 401 | 관리자 아이디 또는 비밀번호 불일치 |
| `FORBIDDEN` | 403 | 권한 없음 |
| `USER_NOT_FOUND` | 404 | 회원 없음 또는 탈퇴 |
| `QUOTE_NOT_FOUND` | 404 | 견적이 없거나 본인 견적이 아님 |
| `REVIEW_NOT_FOUND` | 404 | 후기 없음 |
| `QUOTE_INVALID_STATUS_TRANSITION` | 409 | 허용되지 않는 상태 변경 |
| `QUOTE_CONCURRENT_MODIFICATION` | 409 | `version` 충돌 |
| `REVIEW_NOT_ALLOWED` | 400 | 완료되지 않은 견적에 후기 작성 |
| `REVIEW_ALREADY_EXISTS` | 409 | 후기 중복 작성 |

### 인증

| Method | URL | 설명 |
|---|---|---|
| POST | `/api/auth/kakao` | `{code}` → Access 토큰 반환, Refresh 쿠키 설정 |
| POST | `/api/auth/refresh` | Refresh 쿠키로 재발급, Refresh 토큰도 교체 |
| POST | `/api/auth/logout` | Refresh 토큰 삭제, 쿠키 제거 |
| POST | `/api/admin/auth/login` | `{loginId, password}` → 관리자 Access 토큰 |

### 공개

| Method | URL | 설명 |
|---|---|---|
| GET | `/api/cleaning-types` | 활성 청소 유형과 단가 |
| GET | `/api/options` | 활성 옵션 |
| GET | `/api/tags` | 태그 |
| POST | `/api/quotes/estimate` | 예상 금액 계산만 함 |
| GET | `/api/quotes/live` | 최근 견적 10건, 마스킹 |
| GET | `/api/reviews` | `?rating=&tagId=&sido=&sort=latest\|rating&page=&size=` |
| GET | `/api/reviews/{id}` | 후기 상세 |
| GET | `/api/reviews/summary` | 평균 평점, 총 건수, 태그별 건수 |

### 고객 (USER)

| Method | URL | 설명 |
|---|---|---|
| GET | `/api/my/profile` | 내 정보 |
| DELETE | `/api/my/profile` | 탈퇴 |
| POST | `/api/my/quotes` | 견적 신청 |
| GET | `/api/my/quotes` | 내 견적 목록 `?status=&page=` |
| GET | `/api/my/quotes/{id}` | 내 견적 상세, 옵션과 상태 이력 포함 |
| POST | `/api/my/quotes/{id}/cancel` | 취소 |
| POST | `/api/my/quotes/{id}/review` | 후기 작성 `{rating, title, content, tagIds}` |
| PATCH | `/api/my/quotes/{id}/review` | 후기 수정 |
| DELETE | `/api/my/quotes/{id}/review` | 후기 삭제 |
| GET | `/api/my/reviews` | 내가 쓴 후기 |

`/api/my/quotes/{id}` 계열은 항상 `id`와 **로그인 사용자 id**를 같이 조건으로 조회합니다. 남의 견적이면 403이 아니라 404를 돌려줘서 존재 여부도 알 수 없게 합니다.

### 관리자 (ADMIN)

| Method | URL | 설명 |
|---|---|---|
| GET | `/api/admin/quotes` | `?status=&cleaningTypeId=&from=&to=&keyword=&page=`, keyword는 견적번호·고객명·전화번호 |
| GET | `/api/admin/quotes/{id}` | 상세: 옵션, 상태 이력, 후기, 신청 회원 |
| PATCH | `/api/admin/quotes/{id}/status` | `{toStatus, memo, version}` |
| GET | `/api/admin/reviews` | `?hidden=&best=&rating=&page=` |
| PATCH | `/api/admin/reviews/{id}/visibility` | `{hidden, reason}` |
| PATCH | `/api/admin/reviews/{id}/best` | `{best}` |
| GET | `/api/admin/stats` | `?from=&to=` 기간별·청소유형별 견적 건수, 완료율, 평균 평점 |

### 목록 응답 형식

페이지 응답은 Spring `Page`를 그대로 내보내지 않고 아래 형식으로 통일합니다.

```json
{ "content": [], "page": 0, "size": 20, "totalElements": 0, "totalPages": 0 }
```

---

## 8. 구현할 때 부딪힐 곳

1. **MySQL 8 접속 오류 `Public Key Retrieval is not allowed`**: DBeaver 연결 설정의 드라이버 속성과 JDBC URL에 `allowPublicKeyRetrieval=true&useSSL=false`를 넣습니다. 로컬에서만 그렇게 합니다.
2. **카카오 인가 코드는 한 번만 쓸 수 있습니다**: 콜백이 두 번 실행되거나 콜백 주소에서 새로고침하면 `KOE320`이 납니다. **React 개발 모드의 StrictMode는 `useEffect`를 두 번 실행하므로** 콜백 페이지에서 `useRef`로 한 번만 요청하게 막습니다. 처리 후에는 `navigate(경로, { replace: true })`로 주소를 바꿉니다.
3. **redirect_uri 세 곳 일치**: 프론트 authorize 요청, 백엔드 token 요청, 카카오 콘솔 등록값이 한 글자도 달라선 안 됩니다.
4. **refresh 중복 호출**: Refresh 토큰은 한 번 쓰면 폐기되므로, 같은 토큰으로 refresh가 두 번 나가면 두 번째는 실패하고 로그아웃됩니다. 여러 요청이 동시에 만료될 때, 그리고 **StrictMode에서 앱 시작 시 복구 `useEffect`가 두 번 실행될 때**도 refresh는 한 번만 호출하고 그 결과를 공유합니다. 여러 탭에서 동시에 재발급하면 한쪽이 로그아웃될 수 있는데, 이 프로젝트에서는 허용합니다.
5. **후기 목록의 N+1**: 후기마다 태그·견적을 따로 조회하게 됩니다. 해결 전후 쿼리 수를 README 트러블슈팅에 기록합니다.
6. **컬렉션 fetch join과 페이징**: Hibernate가 메모리에서 페이징합니다(경고 `HHH90003004`). 후기 id를 먼저 페이징 조회하고 태그는 `IN` 쿼리로 따로 가져옵니다.
7. **엔티티를 API로 그대로 내보내지 않습니다**: 지연 로딩 예외와 순환 참조가 생깁니다. 응답은 항상 DTO(record)로 만듭니다.
8. **`open-in-view: false`**: 지연 로딩은 서비스 트랜잭션 안에서 끝내야 합니다.
9. **시간대**: MySQL, JDBC URL, JVM 모두 `Asia/Seoul`로 맞춥니다.
10. **`BaseTimeEntity`는 `created_at`과 `updated_at`이 둘 다 있는 테이블에만 씁니다**: `users`, `quotes`, `reviews`만 해당합니다. `admins`, `refresh_tokens`, `quote_status_logs`는 `created_at`만 있어서, 상속하면 `ddl-auto: validate`가 `updated_at` 컬럼이 없다고 실패합니다.

---

## 9. 배포 방침

- 백엔드는 Gradle 빌드 결과(jar)를 바로 실행해 주는 호스팅을 우선 고릅니다. Docker는 쓰지 않습니다.
- 운영 DB는 MySQL을 지원하는 관리형 서비스를 씁니다. 무료·저가 조건이 자주 바뀌므로 **배포 단계에서 그 시점 조건을 확인하고 결정**합니다(후보: Railway, Aiven, AWS RDS).
- 프론트는 정적 호스팅(Vercel 등)에 올리고 `/api/*`를 백엔드로 rewrite합니다.
- 운영 비밀값은 모두 호스팅 서비스의 환경변수에 넣습니다.
- 카카오 콘솔에 운영 도메인과 운영 redirect URI를 추가합니다.
