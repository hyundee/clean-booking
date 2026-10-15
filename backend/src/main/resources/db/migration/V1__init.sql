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
