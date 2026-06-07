# SAIBOKU 5S活動報告

## ファイル構成（2ファイルのみ）

```
index.html   アプリ本体（これだけで動く）
schema.sql   DB初期設定（1回だけ実行）
```

## セットアップ

### 1. Supabase
1. [supabase.com](https://supabase.com) でプロジェクト作成
2. SQL エディタに `schema.sql` を貼り付けて実行
3. Settings → API から `URL` と `anon key` をコピー

### 2. index.html の先頭を書き換え

```html
<script>
  const SUPABASE_URL      = 'https://xxxx.supabase.co'  ← ここを書き換え
  const SUPABASE_ANON_KEY = 'eyJhbGci...'               ← ここを書き換え
</script>
```

### 3. Cloudflare Pages にデプロイ
- Pages → Create a project → Direct Upload（またはGitHub連携）
- `index.html` を `dist/` フォルダに入れてアップロード
- GitHub連携の場合、ビルドコマンドは不要（静的ファイルのため）

---

## アプリ内の初期設定（設定タブ）

1. **定点観測場所** — 不要な行を削除・必要な行を追加
2. **担当者** — メンバーを追加
3. **担当箇所** — 担当者ごとに「5S担当」「確認者」をチェック → 保存
4. **報告担当者** — 今月の報告担当者をON

## 毎月の運用

| 誰が | 何をする |
|---|---|
| 確認者 | 名前を選択 → 確認箇所に評価点を入力 → 保存 |
| 報告担当者 | レポートタブ → PDF出力（印刷） |
| 翌月頭 | 設定 → 報告担当者 を次の担当者に変更 |
