-- 청소 유형별 평당 단가
INSERT INTO cleaning_types (code, name, price_per_pyeong) VALUES
  ('MOVE_IN',  '입주청소', 13000),
  ('MOVE_OUT', '이사청소', 12000),
  ('LIVING',   '거주청소', 15000);

-- 추가 옵션
INSERT INTO options (name, price) VALUES
  ('베란다 청소',     30000),
  ('곰팡이 제거',     50000),
  ('새집증후군 시공', 150000),
  ('줄눈 시공',       200000);

-- 후기 태그
INSERT INTO tags (name) VALUES
  ('응대가 친절해요'),
  ('꼼꼼해요'),
  ('시간 약속을 잘 지켜요'),
  ('추가비용이 없어요'),
  ('다시 이용하고 싶어요');
