-- ================================================================
-- SAIBOKU 5S活動報告  DBセットアップ
-- Supabase ダッシュボード → SQL エディタ で全文を実行
-- ================================================================
--
-- 役割の定義：
--   5S担当者（s5_location_ids）    … 5Sを実施する人。表示のみ。
--   確認者  （review_location_ids）… 実施状況を確認して評価点を入力する人。
--

CREATE TABLE public.members (
  id                     uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  name                   text    NOT NULL,
  sort_order             int     NOT NULL DEFAULT 0,
  s5_location_ids        int[]   NOT NULL DEFAULT '{}',
  review_location_ids    int[]   NOT NULL DEFAULT '{}',
  is_reporter_this_month boolean NOT NULL DEFAULT false,
  in_rotation            boolean NOT NULL DEFAULT false,
  created_at             timestamptz DEFAULT now()
);

CREATE TABLE public.locations (
  id         serial  PRIMARY KEY,
  area       text    NOT NULL,
  sub_name   text,
  sort_order int     NOT NULL DEFAULT 0,
  active     boolean NOT NULL DEFAULT true
);

CREATE TABLE public.monthly_reports (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year_month  date NOT NULL UNIQUE,
  report_date date,
  deadline    date,
  status      text NOT NULL DEFAULT 'open' CHECK (status IN ('open','completed')),
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

CREATE TABLE public.checks (
  id                uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id         uuid     NOT NULL REFERENCES public.monthly_reports ON DELETE CASCADE,
  location_id       int      NOT NULL REFERENCES public.locations,
  score_seiri       smallint CHECK (score_seiri    BETWEEN 1 AND 5),
  score_seiton      smallint CHECK (score_seiton   BETWEEN 1 AND 5),
  score_seisou      smallint CHECK (score_seisou   BETWEEN 1 AND 5),
  score_seiketsu    smallint CHECK (score_seiketsu BETWEEN 1 AND 5),
  score_shitsuke    smallint CHECK (score_shitsuke BETWEEN 1 AND 5),
  memo              text,
  checked_at        date,
  reviewed_by_name  text,
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now(),
  UNIQUE(report_id, location_id)
);

CREATE VIEW public.v_summary AS
SELECT
  mr.id             AS report_id,
  mr.year_month,
  l.id              AS location_id,
  l.area,
  l.sub_name,
  l.sort_order,
  (SELECT string_agg(m.name,'・' ORDER BY m.sort_order)
     FROM public.members m WHERE l.id = ANY(m.s5_location_ids))     AS s5_names,
  (SELECT string_agg(m.name,'・' ORDER BY m.sort_order)
     FROM public.members m WHERE l.id = ANY(m.review_location_ids)) AS review_names,
  c.score_seiri, c.score_seiton, c.score_seisou, c.score_seiketsu, c.score_shitsuke,
  COALESCE(c.score_seiri,0)+COALESCE(c.score_seiton,0)+COALESCE(c.score_seisou,0)
    +COALESCE(c.score_seiketsu,0)+COALESCE(c.score_shitsuke,0) AS total_score,
  c.memo, c.checked_at, c.reviewed_by_name,
  c.id IS NOT NULL AS is_submitted
FROM public.locations l
CROSS JOIN public.monthly_reports mr
LEFT JOIN public.checks c ON c.location_id=l.id AND c.report_id=mr.id
WHERE l.active=true
ORDER BY mr.year_month DESC, l.sort_order;

ALTER TABLE public.members         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checks          ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_all" ON public.members         FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON public.locations       FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON public.monthly_reports FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON public.checks          FOR ALL TO anon USING (true) WITH CHECK (true);

-- 初期データ（定点観測場所 20か所）
INSERT INTO public.locations (area, sub_name, sort_order) VALUES
  ('現場休憩室','交配',1),('現場休憩室','分娩・離乳',2),
  ('現場休憩室','肥育',3),('現場休憩室','施設',4),
  ('現場トイレ','男性',5),('現場トイレ','女性',6),
  ('シャワー室','男性',7),('シャワー室','女性',8),
  ('更衣室','男性',9),('更衣室','女性',10),('更衣室','施設',11),
  ('休憩室','男性',12),('休憩室','女性',13),
  ('事務所',NULL,14),('飼料配合室',NULL,15),
  ('冷蔵庫周辺・ゴミ捨て',NULL,16),('シャッター小屋',NULL,17),
  ('薬品庫',NULL,18),('消毒棟',NULL,19),('貨車',NULL,20);

-- ================================================================
-- 既存DBへのアップデート（v5→v6 変更分）
-- schema.sql を初めて実行する場合は不要です。
-- 既存DBがある場合は以下のみ実行してください。
-- ================================================================

ALTER TABLE public.members ADD COLUMN IF NOT EXISTS in_rotation boolean NOT NULL DEFAULT false;

-- ================================================================
-- 既存レコードの締切日を25日に一括更新
-- ================================================================

-- 既存の monthly_reports の deadline が NULL のものを当月25日に設定
UPDATE public.monthly_reports
SET deadline = date_trunc('month', year_month) + interval '24 days'
WHERE deadline IS NULL;
