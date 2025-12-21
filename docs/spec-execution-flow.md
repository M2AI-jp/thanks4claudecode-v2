# 実行動線仕様書

> 動線を1つの連結されたユニットとして定義する。内部実装は問わない。

---

## 定義

実行動線とは、playbook に基づいて Edit/Write を行い、適切にガードされて品質が保たれた変更が行われるまでの一連の流れである。

---

## 入力

```
playbook.active が設定された状態で、Claude が Edit または Write ツールを呼び出す
```

---

## 出力

```
1. playbook=null の場合: Edit/Write がブロックされる
2. playbook=active の場合: Edit/Write が許可される
3. 保護ファイル（CLAUDE.md等）への変更: ブロックされる
4. 危険コマンド（rm -rf等）: ブロックされる
5. main ブランチでの変更: ブロックまたは警告される
```

---

## 成功条件

以下の全てが満たされている:

```bash
# playbook=null で Edit がブロックされる
# (Hook の exit code 2 で判定)

# playbook=active で Edit が許可される
# (Hook の exit code 0 で判定)

# CLAUDE.md への Edit がブロックされる
# (HARD_BLOCK で判定)

# rm -rf がブロックされる
# (pre-bash-check で判定)
```

---

## 失敗条件

以下のいずれかが発生した場合、動線は失敗:

| 失敗パターン | 症状 |
|-------------|------|
| ガード未発火 | playbook=null なのに Edit が通る |
| 過剰ブロック | playbook=active なのに Edit がブロックされる |
| 保護漏れ | CLAUDE.md が編集できてしまう |
| 危険コマンド漏れ | rm -rf が実行できてしまう |

---

## E2Eテストシナリオ

### シナリオ1: 正常系（playbook=active）

```
前提: playbook=active, branch=feat/*
操作: 通常のファイルに Edit を実行
期待: Edit が成功する
判定: ファイルが変更される
```

### シナリオ2: 異常系（playbook=null）

```
前提: playbook=null
操作: ファイルに Edit を実行
期待: Edit がブロックされる（exit 2）
判定: エラーメッセージが表示され、ファイルは変更されない
```

### シナリオ3: 異常系（保護ファイル）

```
前提: playbook=active
操作: CLAUDE.md に Edit を実行
期待: Edit がブロックされる（HARD_BLOCK）
判定: CLAUDE.md は変更されない
```

### シナリオ4: 異常系（危険コマンド）

```
前提: playbook=active
操作: rm -rf / を Bash で実行
期待: コマンドがブロックされる
判定: コマンドは実行されない
```

---

## 備考

この動線が動かない場合、品質が保証されない変更が通ってしまう。または正当な変更がブロックされて作業が進まない。
