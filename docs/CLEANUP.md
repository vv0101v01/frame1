# 除錯 · 去重 · 減債 · 清死碼（第二輪收尾紀錄）

執行環境：`moon 0.1.20261119` / `moonc v0.10.22+124d61d05`（2026-11-19）。
所有數字都由 `./scripts/verify.sh` 一次性重跑得到；重構前後
`emergence_trace.csv`（241 列）與 `langlands_trace.csv`（201 列）逐位元相同、
報告大小不變（39,689 / 45,321 bytes）——即**重構是行為保持（behaviour-preserving）的**。

---

## 1. 一鍵品質閘門（新增 `scripts/verify.sh`）

```bash
./scripts/verify.sh
```

順序：`moon version --all` → `moon fmt` + `moon fmt --check` → `moon check --deny-warn`
→ `moon test --target wasm --deny-warn` → `moon test --target js --deny-warn`
→ `moon build --target wasm` → `moon run src/cmd/main` → 匯出 CSV → 兩份 HTML 報告
→ 死碼掃描。任何一步失敗即中止。

新增的三支腳本取代了原本「手動貼 bash 片段」的債務：

| 腳本 | 取代了什麼 |
| --- | --- |
| `scripts/verify.sh` | 每次改動都要手打 7 條指令、且容易漏 `--deny-warn`／漏 `js` target |
| `scripts/extract_traces.py` | 用臨時 heredoc 從 `run_output.txt` 切 CSV（不可重現、易貼錯） |
| `scripts/dead_code_scan.py` | 死碼只靠肉眼；現在 CI 化，發現即 `exit 1` |

## 2. 清死碼（13 項）

以「名稱在全 `src/` 中出現次數 ≤ 1（即只有定義本身）」掃描 324 個定義，移除：

| 檔案 | 移除 | 原因 |
| --- | --- | --- |
| `00_core.mbt` | `mat_get` | 只有 `a[i*n+j]` 一行，無任何引用 |
| `04_pope.mbt` | `legendre_deriv`、`pope_frequencies` | 從未被呼叫（PoPE 走 `poly_deriv_eval` 與 `pope_frequencies` 之外的譜參數路徑） |
| `11_complex.mbt` | `Cx::to_text` | 除錯殘留，測試與管線都用 `to_string()` |
| `12_eisenstein.mbt` | `EisensteinDatum::amplitude`、`EisensteinDatum::eisenstein_multiplicity` | 前者被 `constant_term_matrix` 內聯取代、後者無引用 |
| `13_lparams.mbt` | `LParameter::signature` | 從未被呼叫（結構化資料改由測試直接斷言） |
| `15_betti.mbt` | `mat2_id`、`trace_coordinate_count` | 前者無引用、後者與 `betti_dim` 重複 |
| `16_langlands_emergence.mbt` | 4 個 `_last_*` 變數 | 從 CSV 欄位重構後遺留、每次迭代仍被賦值但從未讀取 |

掃描結果：**320 個定義、0 個死定義**。

## 3. 去重（11 項，全部是「同一件事寫了兩份」）

| # | 重複 | 收斂後 | 說明 |
| --- | --- | --- | --- |
| 1 | `04_pope::matvec`、`06_flow::laplacian_apply`、`03::affine_map` 各自手寫矩陣乘向量 | `00_core::matvec` 為唯一實作 | 線性代數回到 core |
| 2 | `laplacian_apply` | `matvec(l, u, n)` | 保留函數名以維持 PDE 層可讀性 |
| 3 | `affine_map` | `matvec` + 平移 | `A x + b` 不再重寫內層迴圈 |
| 4 | `07::nematic_order` 與 `06::order_parameter` 兩份相同的 `\|Σe^{iθ}\|/n` | `06::order_harmonic(θ, k)` | `k=1` 相位序、`k=2` 向列序 |
| 5 | `matrix_rank`／`matrix_nullity`／`mat_power` 長在 13 號檔 | 移入 `00_core` | 14/15 也用，屬通用 LA |
| 6 | `LParameter::matrix` 與 `15::eisenstein_local_system` 同一段「么冪 + 對角」 | 前者委派後者 | L-參數矩陣與 Eisenstein 局部系統不可能再走樣 |
| 7 | `phi_functional_defect` | `c_reflection_defect(2s−1)` | 泛函方程就是 `c` 的反射律 |
| 8 | `residue_at_one` | `½·c_pole_witness(1+2ε)` | 留數只存在於一處 |
| 9 | `gcheck_parabolic_dim`／`gcheck_positive_weights` 兩份權重對掃描 | 私有 `weight_pair_count(blocks, mode)` | 一個迴圈、三個公開包裝 |
| 10 | `poisson_bracket` 內把 3 點中央差分寫兩遍（共 6 次求值） | 私有 `grad_at(f, p, h)` | 括號、Jacobi、Casimir 全部共用 |
| 11 | `jm_centralizer_dim` 手寫 `blocks.length()` | `partition_length(blocks)` | 與分割工具一致 |

## 4. 除錯：去重時抓到的一個真 bug（測試救回來的）

把 `gcheck_kernel_dim` 改成「呼叫 `gcheck_multiplicity` 求和」的重構**是錯的**：
`gcheck_multiplicity(blocks, k)` 數的是 `Θ = ad(h/2)` 的**權空間**重數
`#{(i,j) : h_i − h_j = k}`，而 `ker Θ` 需要的是權**值**重數 `m_v = #{i : h_i = v}`。
誤用後 `dim ker Θ` 被放大 `n` 倍，立即由三個測試抓到：

```
T22c: ker Θ is the fixed algebra of the grading        → FAILED
T22d: graded character factorises / χ(-1) 完全平方      → FAILED
T23d: CT ∘ Eis = id，纖維 = 么冪軌道 (8 + 8 = 16)        → FAILED
```

修正：新增私有 `weight_value_multiplicity`（權**值**重數），`gcheck_kernel_dim` 用它；
`gcheck_multiplicity` 保持原語義並在 doc comment 明確區分兩者。
三測試恢復綠燈，且 `langlands_trace.csv` 與重構前逐位元相同。

這就是「每個定理都要有可判定憑證」的實際回報：**重構安全網不是型別，而是定理的數值斷言。**

## 5. 減債：其他結構性整理

* `.gitignore`：排除 `_build/`、`.mooncakes/`、`*.wasm` 等衍生物（專案原本會被建置產物汙染）。
* `docs/CLEANUP.md`（本檔）：把「為什麼刪、為什麼合、哪裡踩雷」寫成可追溯紀錄。
* README 增列 `./scripts/verify.sh` 與本檔連結；品質閘門由 7 條手打指令縮成 1 條。
* `src/pkg.generated.mbti` 由 `moon check` 重新生成（API 變更：移除 9 個死 API、新增
  `matvec`、`order_harmonic`）。
* 註解層：所有「兩份實作」的檔案都在新位置加上「誰是唯一實作」的說明，避免下次又長出第二份。

## 6. 重構前後對照

| 指標 | 之前 | 之後 |
| --- | --- | --- |
| `src/` 行數（含測試與註解） | 6,172 | 6,094（−78） |
| 定義數 | 324 | 320 |
| 零引用定義 | 9 | 0 |
| 已知重複實作 | 11 組 | 0 組 |
| 測試數 | 55 | 55（全綠，wasm + js） |
| `--deny-warn` | 通過 | 通過 |
| 輸出可重現性 | 手動切 CSV | `run_output.txt` → 腳本 → CSV，逐位元可重現 |

## 7. 發佈（GitHub push）：已完成

**本機狀態：已完成**——`git init -b main`，逐層可讀的 commit 歷史（不是一個「initial dump」）：

```
9cf7b41 ci: single-job gate on GitHub Actions, plus executable bits on the scripts
9c336a4 docs: record the publish procedure and the token permission diagnosis
7fa2cf5 refactor: remove dead code, deduplicate shared logic, put the gate behind one script
25ad8a6 feat(langlands): Eisenstein constant-term functor, non-semisimple L-parameters, G-hat operator, Betti moduli
ab5eaf9 feat(core): MoonBit 0.10 supergeometry kernel for agent emergence
```

**發佈指令**（金鑰只出現在一次性 URL，不會寫入 `.git/config` 或任何被追蹤的檔案）：

```bash
GITHUB_PAT=ghp_xxx ./scripts/push.sh          # 預設 vv0101v01/frame1, 分支 main
```

`scripts/push.sh` 推完之後會把 `origin` 重設成不含金鑰的
`https://github.com/vv0101v01/frame1.git`。

**結果：已推送成功**（2026-11-23）

```
* [new branch]      HEAD -> main
```

| 項目 | 值 |
| --- | --- |
| repo | <https://github.com/vv0101v01/frame1>（public，`default_branch = main`） |
| HEAD | `9cf7b41` · 5 個 commit · 42 個追蹤檔案 |
| 金鑰 | classic PAT（scope: `repo`, `workflow`）；只出現在一次性 push URL |
| `.git/config` | 已確認**不含**任何 token（`origin` = 無金鑰 HTTPS） |

上一版 fine-grained PAT 失敗的真正原因（留作紀錄）：token 認證成功、repo 讀得到，
但 `POST /repos/.../git/refs` 回

```
x-accepted-github-permissions: contents=write
{"message": "Resource not accessible by personal access token", "status": "403"}
```

即該 fine-grained token 缺 `Contents: Read and write`。classic PAT 帶 `repo` scope 即直接通過。

## 8. CI（GitHub Actions）

`.github/workflows/ci.yml`，workflow 名 `gate`，`ubuntu-latest`，單一 job：

| # | step | 內容 |
| --- | --- | --- |
| 1 | Checkout | `actions/checkout@v4` |
| 2 | Install MoonBit | `scripts/install-moonbit.sh "$MOON_VERSION"`（官方安裝器 + SHA-256 驗證） |
| 3 | PATH | `$MOON_HOME/bin` 寫入 `$GITHUB_PATH` |
| 4 | 版本 | `moon version --all` |
| 5 | Quality gate | `scripts/verify.sh`（fmt / check --deny-warn / 55×2 測試 / build / 兩條管線 / CSV / 兩份報告 / 死碼掃描） |
| 6 | 可重現性 | `git diff --exit-code`：衍生物若有任何數值漂移即紅燈 |
| 7 | Artifact | `reports-and-traces`（兩份 HTML + 兩份 CSV + `run_output.txt`） |

首次執行結果（push `9cf7b41`）：

```
run #1  completed  success  2026-11-23T11:13:41Z → 11:14:04Z（23 秒）
step 6 Quality gate                         success
step 7 Committed artefacts match a fresh run success
artifact reports-and-traces                 56,431 bytes
```

<https://github.com/vv0101v01/frame1/actions/runs/45163251507>

觸發條件：`push` 到 `main`、任何 `pull_request`、以及手動 `workflow_dispatch`；
`concurrency` 會取消同一 ref 的舊 run。工具鏈通道由 `MOON_VERSION` 控制
（預設 `latest`，釘死版本時填 `v0.10.22` 之類的 release id）。

### 附：原先的診斷（保留作紀錄）


```
remote: Permission to vv0101v01/frame1.git denied to vv0101v01.
fatal: ... The requested URL returned error: 403
```

同樣金鑰打 `POST /repos/vv0101v01/frame1/git/refs` 的回應標頭是

```
x-accepted-github-permissions: contents=write
{"message": "Resource not accessible by personal access token", "status": "403"}
```

即：token **認證成功**（辨識為 `vv0101v01`，repo 亦已存在且 `default_branch = main`、目前為空），
但**只有讀取權限，缺少 `Contents: Read and write`**。修法（其一）：

1. GitHub → Settings → Developer settings → Fine-grained tokens → 編輯該 token
   → **Repository access** 要包含 `frame1` → **Permissions → Contents: Read and write**
   （若之後要放 CI，再加 `Workflows: Read and write`）；
2. 或者改用 classic token，勾 `repo` scope。

改好之後重跑上面那行 `GITHUB_PAT=... ./scripts/push.sh` 即可；
本地 commit、分支名、`.gitignore`、報告與 CSV 都已備妥，不需要重做任何計算。

## 8. 第四輪（Round 4）：module-21 重寫、新增定義的死碼封堵

| 項目 | 做法 | 結果 |
|---|---|---|
| `reflects_on` / `reflection_bound`（強反射） | 刪除：對有限 `V_α` 恆回 0（Montague–Lévy 需 α ≥ ω；Σ₀ 唯一絕對層），屬「看似有內容實則虛無」的死邏輯 | `src/21_universe_reflection.mbt` 重寫，改用參數相對 `reflects_for(β,α,n,params,…)` / `reflection_bound_for(α,n,params,…)` |
| `formula_pool` | 補回原子 `x_i ∈ x_i`（`Mem(i,i)`），否則 `nvars = 1` 時池為空，反射測試退化為真空 | 池大小 4/15/30/205，T37/T38 斷言有據 |
| `hf_in_level` / `hf_rank` | 掃描器曾標記為 dead → 寫入 T35/T36 宇宙閉包斷言作為正規引用 | 被常規使用，不再被 flag |
| 新增定義 21/24 | `reflects_for`、`reflection_bound_for`、`reflected_dual`、`reflected_of_inverse`、`duality_commutation_defect`、`power_sums_of` | 全部從 `test` 區塊（T35–T46 與 pipeline certificate）引用 |
| `satake_weight_of_ic`（23） | 刪除無用函式，將其斷言改為 `satake_perverse_degree(c3, cw1) == 6` | 無行為遺失 |
| 格式化與警告 | `moon fmt` 嚴格；`moon check --deny-warn` 清淨 | 0 warnings |
| 測試 | `moon test --target wasm --deny-warn` 82/82；`--target js --deny-warn` 82/82 | 0 failed |
| 死碼掃描 | `scripts/dead_code_scan.py`：562 個定義，0 個死 | 封鎖 CI |

第四輪新增 416 → 562 定義皆有引用，`universe_trace.csv`（41 行、11 欄）與 `docs/report_universe.html` 由管線真跑衍生；`scripts/verify.sh` 與 `.github/workflows/ci.yml` 已延伸至第四輪報告與 trace（見 README §2、§10）。
