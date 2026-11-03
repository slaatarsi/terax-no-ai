# Terax

**フォルダーエクスプローラーと Git の変更追跡を備えた軽量ターミナル。AI エージェントの組み込み機能はありません。**

このバージョンは [crynta/terax-ai](https://github.com/crynta/terax-ai) を改変したフォークで、[slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai) で独立して保守されています。元のプロジェクトは Crynta と upstream の貢献者によるものです。

## 機能

- タブ、分割ペイン、検索、シェル統合を備えたネイティブターミナル。
- 検索、ファイル管理、リアルタイム更新に対応するフォルダーエクスプローラー。
- Git の状態、差分、ステージング、コミット、push、履歴グラフ。
- エディター、任意の言語サーバー、プレビュー、テーマは補助機能として残っています。

組み込みの AI チャット、エージェント、AI プロバイダー、AI 補完、音声入力はありません。CLI プログラムは手動で実行できます。以前の AI データや外部フックは読み込まれず、自動削除もされません。

## ソースからビルド

Rust stable、Node 22+、pnpm、および [Tauri の前提条件](https://tauri.app/start/prerequisites/) が必要です。

```bash
git clone https://github.com/slaatarsi/terax-no-ai.git
cd terax-no-ai
pnpm install
pnpm tauri dev
# 配布用パッケージ:
pnpm tauri build
```

**注意:** 更新設定は現在も upstream のリリースを参照しています。更新を受け入れると、このフォークが元のバージョンに置き換わる可能性があります。upstream のインストーラーやパッケージは、この AI 非搭載版を提供するものではありません。このフォーク独自の署名は保証されません。

詳しい手順と配布上の制限は [英語版 README](../../README.md) を参照してください。[ドキュメント](../README.md)、[貢献ガイド](../../CONTRIBUTING.md)、[セキュリティ](../../SECURITY.md) もご覧ください。不具合はこのフォークのリポジトリに報告してください。

ライセンスは [Apache-2.0](../../LICENSE) です。元の著作権表示と通知は保持されています。
