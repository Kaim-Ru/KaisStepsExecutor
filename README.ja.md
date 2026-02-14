# PowerShell Steps Executor

[English version is here](README.md)

JSONで定義されたワークフローを実行するインタラクティブなPowerShell自動化ツール。質問、条件付きアクション、ファイル操作、拡張可能なフックシステムをサポートしています。

## 使い方

```powershell
.\generator.ps1                           # デフォルトのsteps.jsonを使用
.\generator.ps1 -StepPath "custom.json"  # カスタム設定を使用
```

## 設定

**基本構造:**

```json
{
  "steps": [
    {
      "question_id": "project_name",
      "question": "プロジェクト名を入力",
      "input_type": "input",
      "actions": [...]
    }
  ]
}
```

**ステップのプロパティ:**

- `question_id` - 回答を参照するための一意ID（省略可）
- `question` - 質問文（省略可）
- `input_type` - `input`、`select`、または `multiselect`（デフォルト: `input`）
- `options` - select/multiselectの選択肢配列
- `actions` - 実行するアクション配列

**アクション:**

1. **execute** - PowerShellコマンドを実行

   ```json
   { "type": "execute", "command": "git init" }
   ```

2. **replace** - ファイル内の文字列を置換（ワイルドカード対応）

   ```json
   {
     "type": "replace",
     "files": ["./template/**/*.txt"],
     "target": "[[[OLD]]]",
     "value": "[[[ANS:project_name]]]"
   }
   ```

   - `files`: パターン（配列または `{include: [...], exclude: [...]}`）、`*`、`**`、`?` をサポート
   - `target`: 文字列、正規表現 `{"regex": "..."}`、または配列（いずれかマッチ）
   - `value`: 置換後の値

3. **copy** - ファイル/フォルダをコピー

   ```json
   { "type": "copy", "source": "./template", "destination": "./output/" }
   ```

4. **symlink** - シンボリックリンクを作成（Windowsでは管理者権限が必要）

   ```json
   { "type": "symlink", "source": "./config", "destination": "./link" }
   ```

5. **mkdir** - ディレクトリを作成
   ```json
   { "type": "mkdir", "path": "./[[[ANS:project_name]]]/src" }
   ```

**条件:**

アクションは条件が満たされた場合のみ実行されます（AND論理）:

```json
{
  "conditions": [
    { "question_id": "use_git", "ans": "Yes" },
    { "question_id": "framework", "ans": ["React", "Vue"] }, // いずれかマッチ（OR）
    { "question_id": "name", "ans": { "regex": "^my-" } } // 正規表現マッチ
  ],
  "type": "execute",
  "command": "npm install"
}
```

**プレースホルダー:**

- `[[[ANS:question_id]]]` - 回答を参照
- `[[[UUIDv4]]]` - 一意なUUIDを生成
- `\[[[...]]]` - エスケープ（JSONでは `\\[[[...]]]` を使用）

プレースホルダーが使える場所: `question`、`options`、`command`、`target`、`value`、`source`、`destination`、`path`、条件の `ans` 値

## 例

```json
{
  "steps": [
    {
      "question_id": "name",
      "question": "プロジェクト名は？",
      "input_type": "input",
      "actions": [
        { "type": "mkdir", "path": "./[[[ANS:name]]]" },
        {
          "type": "replace",
          "files": ["./template/**"],
          "target": "[[[NAME]]]",
          "value": "[[[ANS:name]]]"
        },
        {
          "type": "copy",
          "source": "./template",
          "destination": "./[[[ANS:name]]]/"
        }
      ]
    },
    {
      "question_id": "typescript",
      "question": "TypeScriptを使用しますか？",
      "input_type": "select",
      "options": ["はい", "いいえ"],
      "actions": [
        {
          "conditions": [{ "question_id": "typescript", "ans": "はい" }],
          "type": "execute",
          "command": "npm install -D typescript"
        }
      ]
    }
  ]
}
```

## 拡張性

すべての入力タイプとアクションは `./hooks/` の**フック**として実装されています:

**組み込み:**

- 入力: `input.ps1`、`select.ps1`、`multiselect.ps1`
- アクション: `execute.ps1`、`replace.ps1`、`copy.ps1`、`symlink.ps1`、`mkdir.ps1`

**カスタムフック:**

`hooks/{type}.ps1` を作成:

```powershell
. "$PSScriptRoot/common.ps1"

# 入力タイプ用
function Get-UserInput {
    param([string]$Question, [array]$Options, [hashtable]$Answers)
    # 実装
    return $result
}

# アクションタイプ用
function Invoke-CustomAction {
    param([object]$Action, [hashtable]$Answers)
    $value = Invoke-Replacement -Text $Action.property -Answers $Answers
    # 実装
}
```

## ドキュメント

開発者およびAIエージェント向けの詳細は [AGENTS.md](AGENTS.md) を参照してください。アーキテクチャ、コーディング規約、拡張ガイドが記載されています。

## ライセンス

MIT
