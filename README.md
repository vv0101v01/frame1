# 類智能體湧現的超幾何抽象 · MoonBit 0.10

以 **數學結構 ⟶ 計算機抽象 ⟶ 資料型別 ⟶ 可執行定律 ⟶ 定理 ⟶ 演算法** 的順序，把下列數學名詞實作成一個可編譯、可測試、可執行的 MoonBit 專案，並把抽象過程中浮現的定理與演算法整理在 [`docs/THEORY.md`](docs/THEORY.md)（第一輪，T1–T15 / A1–A12）與 [`docs/LANGLANDS.md`](docs/LANGLANDS.md)（第二輪，T16–T24 / A13–A20）。

**第一輪（超幾何）**
> 龐加萊–黎曼超流形 $\mathcal{M}^{m|n}$ · 仿射張量空間 · PoPE 位置編碼 · 非交換幾何與超矩陣方程 · 偏微分演化流 · 超雅可比恆等式 · 二階超質量張量軌道空間 · 符號–神經合一算子 · 自然梯度與費雪資訊度量

**第二輪（Langlands 幾何）**
> 愛森斯坦級數與常數項函子 · 非半單 L-參數 · Ĝ-算子 · 貝蒂模空間與特徵簇

第二輪同樣以「抽象 → 定理 → 演算法」進行，並且額外要求**每個定理都要有可判定的數值憑證**
（例如「常數項矩陣 = |W|·冪等投影」、「么冪軌道維度 = n² − Σ(λ'_i)²」，
全部由 `moon test` 鎖定），結果見第 8 節。

---

## 1. 工具鏈（已實際下載並驗證）

| 項目 | 值 |
| --- | --- |
| 安裝來源 | `curl -fsSL https://cli.moonbitlang.com/install/unix.sh \| bash` |
| 通道 | `latest`（官方穩定通道，非 nightly） |
| `moon` | `0.1.20261119 (738607b 2026-11-19)`（第二輪重裝，`latest` 通道；第一輪為 `0.1.20261104`） |
| `moonc` | `v0.10.22+124d61d05 (2026-11-19)`（第一輪為 `v0.10.20+65efd5b93`） |
| `moonrun` | `0.1.20261119 (738607b 2026-11-19)` |
| 官方 Release Notes 標示版本 | `v0.10.19`（2026-11-05），`latest` 通道供應同日之後的補丁組建 |
| SHA-256 (`moonbit-linux-x86_64.tar.gz`) | 第一輪：`80d987523308fa490eba9f1baf98df996a5a7891e118357553b7c2608c0597c5` ✅ `sha256sum -c` 通過（由 `scripts/install-moonbit.sh` 自動驗證） |

官方 2026-11-05 的更新頁標示 `moonc version: v0.10.19`，而 CLI 的 `latest` 通道實際供應同日的補丁組建 `v0.10.20+65efd5b93`；本專案以 `latest` 實測通過。詳見 [`docs/MOONBIT_0_10_SYNTAX.md`](docs/MOONBIT_0_10_SYNTAX.md)。

重現安裝：

```bash
./scripts/install-moonbit.sh            # 或 ./scripts/install-moonbit.sh latest
export PATH="$HOME/.moon/bin:$PATH"
moon version --all
```

## 2. 品質閘門（全部通過，一條指令）

```bash
./scripts/verify.sh
```

它依序執行：`moon fmt` + `moon fmt --check` → `moon check --deny-warn` →
`moon test --target wasm --deny-warn` → `moon test --target js --deny-warn`
→ `moon build --target wasm` → 跑兩條管線 → 由 `scripts/extract_traces.py` 匯出 CSV
→ 生成兩份 HTML 報告 → `scripts/dead_code_scan.py` 死碼掃描。

| 檢查 | 結果 |
| --- | --- |
| `moon fmt --check` | no work to do |
| `moon check --deny-warn` | 通過（0 warning） |
| `moon test --target wasm --deny-warn` | `Total tests: 55, passed: 55, failed: 0` |
| `moon test --target js --deny-warn` | `Total tests: 55, passed: 55, failed: 0` |
| 死碼掃描 | 320 個定義、**0 個零引用定義** |

## 3. 專案結構

```
moonbit-superagent/
├── moon.mod                      # 0.10 DSL 模組設定（source = "src"）
├── src/
│   ├── moon.pkg                  # 0.10 DSL 套件設定（core/math, core/debug）
│   ├── 00_core.mbt               # 分次維度、位元運算、矩陣/線性代數、LCG
│   ├── 01_super_algebra.mbt      # Λ(n) Grassmann 超代數、Berezin 積分、超括号
│   ├── 02_supermanifold.mbt      # M^{2|2}、Poincaré 上半平面、Berezinian 體積
│   ├── 03_affine_tensor.mbt      # (r,s) 張量、仿射映射、聯絡、曲率
│   ├── 04_pope.mbt               # Legendre PoPE + Polar PoPE + 譜三元組統一
│   ├── 05_supermatrix.mbt        # Mat(2|1)、超跡、Berezinian、分次 Sylvester、Connes 距離
│   ├── 06_flow.mbt               # 熱流 CFL、Kuramoto 非線性 PDE 流、序參量
│   ├── 07_orbit.mbt              # 二階超質量張量、SO(2) 軌道空間、向列序
│   ├── 08_fisher.mbt             # Fisher cometric、KL Hessian、阻尼 CG 自然梯度
│   ├── 09_unify.mbt              # Term ADT、重寫、一階合一、符號–神經 U 算子
│   ├── 10_emergence.mbt          # 耦合湧現管線 + CSV 導出
│   ├── 11_complex.mbt            # ℂ、Γ、完備 ζ（Euler–Maclaurin + 反射）
│   ├── 12_eisenstein.mbt         # Eisenstein 級數、c-函數、常數項矩陣、|W|·冪等投影
│   ├── 13_lparams.mbt            # L-參數、Jordan 型、Cent(N)、Ext¹、么冪軌道
│   ├── 14_gcheck.mbt             # Ĝ-算子 = ad(h/2)（Jacobson–Morozov 分級）
│   ├── 15_betti.mbt              # 貝蒂模空間、Fricke κ、Goldman Poisson 結構
│   ├── 16_langlands_emergence.mbt# 四機制耦合管線 + CSV 導出
│   └── cmd/main/                 # 可執行範例（兩條管線）
├── docs/
│   ├── THEORY.md                 # 第一輪：定理 T1–T15、演算法 A1–A12
│   ├── LANGLANDS.md              # 第二輪：定理 T16–T24、演算法 A13–A20、限制、文獻
│   ├── MOONBIT_0_10_SYNTAX.md    # 最新語法核查筆記（含來源）
│   ├── report.html               # 第一輪自包含報告（內嵌 SVG）
│   └── report_langlands.html     # 第二輪自包含報告（7 個內嵌 SVG 圖）
├── scripts/
│   ├── install-moonbit.sh        # 官方 latest 通道 + SHA-256 驗證
│   ├── verify.sh                 # 一鍵品質閘門（fmt/check/test/build/run/report/死碼）
│   ├── extract_traces.py         # run_output.txt → 兩份 CSV（可重現）
│   ├── dead_code_scan.py         # 零引用定義掃描（CI 化）
│   ├── make_report.py            # 第一輪報告
│   └── make_report_langlands.py  # 第二輪報告
├── emergence_trace.csv           # 第一輪：240 步軌跡
├── langlands_trace.csv           # 第二輪：200 步軌跡（9 欄）
├── run_output.txt                # 完整執行輸出（兩條管線）
└── .gitignore                    # 排除 _build/ 等衍生物
```

## 4. 一句話說明「怎麼把數學變成程式」

| 數學物件 | 計算機抽象 | MoonBit 型別 |
| --- | --- | --- |
| $\Lambda(\theta_1..\theta_n)$ | 單項式 = 位元遮罩；冪零 = `(a & b) == 0` | `SuperNumber { n, coeff : Array[Double] }` |
| $\mathcal{M}^{m|n}$ | 偶部取 Poincaré 上半平面，奇部取辛形式 | `SuperManifold { dim, points, odd_form }` |
| 張量 | `(shape, variance, flat data)` | `Tensor` |
| PoPE | 位置核 = 自伴算子 J 的譜測度 | `trait PosKernel` + `PolarPoPE` / `LegendrePoPE` |
| Mat(m\|n) | 分塊列優先 + 分次標籤 | `SuperMatrix` |
| PDE 流 | 圖拉普拉斯離散化 $\Delta$ | `ring_laplacian`, `heat_flow`, `kuramoto_flow` |
| 軌道空間 | 排序特徵值 = Weyl chamber 投影 | `SuperMassTensor::canonical_form` |
| 合一算子 | 閉包算子 = 正規式 + 排序 | `Hybrid::canonical`, `unification_operator` |
| Fisher 度量 | cometric `F = diag(p) − ppᵀ`，無矩陣 CG | `fisher_apply`, `natural_gradient_cg` |

## 5. 執行結果（預設 32 個 agent、240 步）

```
agents: 32, steps: 240
R(0)  = 0.18998172824288795  →  R(T) = 0.9999562102000173   # U(1) 對稱自發破缺
nematic(0) = 0.21297         →  0.99982                    # 二階張量捕捉向列序
belief dispersion 0.28917    →  3.11e-9                    # Fisher 自然梯度共識
concept dispersion 0.18187   →  0.00261                    # 符號–神經 U 共識
max Super-Jacobi defect      = 1.55e-15                    # 代數封閉性憑證
Connes distance = 1/K        = 0.3125                     # 幾何 = 耦合強度倒數
orbit eigenvalues ≈ [0.9999124, 0.0000876]
```

`emergence_trace.csv` 的八個欄位：`step, order_R, nematic, concept_dispersion, belief_dispersion, kl_to_consensus, fisher_grad, jacobi_defect`。

## 6. 兩個同名 PoPE

文獻中 PoPE 有兩個不同構造，本專案都實作，並用**譜三元組**統一：

- **Legendre PoPE**：`PE(pos,i) = P_pos(x_i)`，取自 [arXiv:2405.04585](https://arxiv.org/abs/2405.04585)。
- **Polar Coordinate PoPE**：`a(t,s) = Σ_c μ_q μ_k cos((s−t)θ_c + δ_c)`，取自 [arXiv:2509.10534](https://arxiv.org/abs/2509.10534)（ICML 2026 camera-ready）。

## 7. 第二輪：Langlands 幾何（愛森斯坦 / 非半單 L-參數 / Ĝ-算子 / 貝蒂模空間）

| 數學名詞 | 計算抽象 | 定理 | 數值憑證 |
| --- | --- | --- | --- |
| 愛森斯坦級數 + 常數項函子 | `A(λ)[u][v] = c(uv⁻¹, vλ)`，`c(t) = ξ(t)/ξ(t+1)` | T17–T20 | `A² = \|W\|A`、`tr Π = 1`、`det A = 0`（rank 2/3/4） |
| 非半單 L-參數 | `(eigenvalues, Jordan λ ⊢ n)`，`defect = Σ(λᵢ−1)` | T21 | `dim Cent(N) = Σ(λ'_i)²`（零空間計算）、GL₄ 軌道 `0,6,8,10,12`、`p(6)=11` |
| Ĝ-算子 | `Θ = ad(h/2)`，`(e,h,f)` = JM 三元組 | T22 | `[h,e]=2e`、`[e,f]=h` 精確；`χ_Θ(t)` 分解；`χ_Θ(−1)` 為完全平方 |
| 貝蒂模空間 / 特徵簇 | 痕跡坐標 `(x,y,z)`、`κ = x²+y²+z²−xyz` | T23 | Fricke `κ = 2+tr[A,B]`、Goldman 括號 Jacobi、`rank P = 2`、`CT∘Eis = id` |
| 四者耦合（湧現） | 24 智能體 × 200 步 | T24 | `R: 4.5e-13 → 0.9999999999999988`、`κ` 散度 `2.2 → 2.7e-15` |

四機制管線（`16_langlands_emergence.mbt`）：

1. **c-函數閘門** `g = |c(w₀,λ)|` —— 愛森斯坦 intertwining 振幅；
2. **么冪冷卻** —— 非半單 L-參數趨向半單（可以「解鎖」）；
3. **Hamiltonian 對齊** `p ← p + dt·{p,H}` 並投影回辛葉 —— `κ` 精確守恆，故**不能**跨葉合併；
4. **愛森斯坦投影** `p ← p + η·(p̄−p)` —— rank-one 投影 `Π` 的族群版本，唯一能跨葉的機制，
   也就是共識。

執行摘要（see `langlands_trace.csv`，9 欄：`step, order_R, kappa_spread, trace_spread,
jacobi_defect, unipotent_defect, eisenstein_fraction, casimir_drift, gcheck_fixed_ratio`）：

```
agents: 24, steps: 200, surface: genus 1 with 1 puncture(s)
dim M_B(SL_2) = 2 (Poisson rank 2, one Casimir kappa)
R(0) = 4.5e-13 -> R(T) = 0.9999999999999988, kappa spread 2.199 -> 2.66e-15
unipotent defect 0.66667 -> 8.46e-4
max |{kappa,H}| (Casimir certificate) = 3.92e-8
max Jacobi defect over the whole run = 1.09e-8
Eisenstein projection defect (rank 2) = 0 ; (rank 3) = 6.66e-16
c-function functional-equation defect = 1.55e-15
CT-Eis defect (GL_4, type (2,2)) = 0
unipotent orbit dim (2,2) = 8, ^G fixed algebra = 8, total = 16
dim ker Theta (3,1) = dim Cent(N) = Ext^1 = 6
nilpotent orbits in GL_6 = 11
```

視覺化：[`docs/report_langlands.html`](docs/report_langlands.html)（自包含，7 個內嵌 SVG：序參量、
半單化、憑證對數圖、維度條形圖、常數項矩陣熱圖）。完整推導見 [`docs/LANGLANDS.md`](docs/LANGLANDS.md)。

## 8. 除錯／去重／減債（第三輪：收尾）

完整紀錄見 [`docs/CLEANUP.md`](docs/CLEANUP.md)，摘要：

* **清死碼 13 項**：`mat_get`、`legendre_deriv`、`pope_frequencies`、`Cx::to_text`、
  `EisensteinDatum::{amplitude, eisenstein_multiplicity}`、`LParameter::signature`、
  `mat2_id`、`trace_coordinate_count`、4 個 `_last_*` 變數。
* **去重 11 組**：`matvec` 收斂到 `00_core`（`laplacian_apply`、`affine_map` 委派）、
  `order_parameter`/`nematic_order` → `order_harmonic`、
  `LParameter::matrix` → `eisenstein_local_system`、
  `phi_functional_defect` → `c_reflection_defect`、`residue_at_one` → `c_pole_witness`、
  權重對掃描 → `weight_pair_count`、Poisson 梯度 → `grad_at`、
  `matrix_rank`/`matrix_nullity`/`mat_power` 移入 `00_core`。
* **抓到 1 個真 bug**：把 `ker Θ` 的「權值重數」誤換成 `ad(h/2)` 的「權空間重數」，
  被 T22c/T22d/T23d 三個測試立刻擋下（放大 `n` 倍）。
* **減債**：`.gitignore`、`scripts/verify.sh`、`scripts/extract_traces.py`、
  `scripts/dead_code_scan.py`、本節與 `docs/CLEANUP.md`。
* 重構後 `src/` 由 6,172 行降到 6,094 行，測試仍 55 個全綠，
  `emergence_trace.csv` / `langlands_trace.csv` 與重構前**逐位元相同**。

## 9. 限制

- Grassmann 纖維以 `Int32` 位元遮罩編碼，建議 `n ≤ 16`（`2^n` 個係數）。
- 偶部具體化為雙曲上半平面 $\mathbb{H}^2$；更高維 `m` 只需擴充 `points` 與度量。
- 體積／Berezinian 使用區塊對角超度量；一般含奇偶混合的超矩陣方程由 `graded_sylvester_solve` 處理。
- 數值比較一律用 `approx`（相對 + 絕對容差），避免 IEEE NaN 比較陷阱（0.10.19 明確規範 `compare` 遇 NaN 未定義）。
- 這是「可執行的數學模型」，不是訓練好的大型神經網路；`embed` 是決定性特徵映射，用於展示符號／神經通道的代數耦合。
- 第二輪：`Ĝ` 以 `GL_n^ = GL_n`、`𝔤𝔩_n` 建模；愛森斯坦只做 `SL₂`（阿基米德、`x` 方向數值積分）
  與 `r ≤ 4` 的 minimal parabolic；p-進 Euler 乘積未實作。
- 「常數項矩陣 `A² = |W|A`」是本專案對 Langlands/Gindikin–Karpelevich 公式在有限 Weyl 群上的
  **形式化版本**，不是文獻定理原文；測試只鎖定此形式化陳述。
- 「Ĝ-算子」按「Langlands 對偶群的分級算子 `ad(h/2)`」實作；若原意是 oper 等其他物件，
  定義需重新指定。
- 貝蒂側取實點 `SL₂(ℝ)`；與 de Rham / Dolbeault 的 Deligne–Simpson 對應未實作。

授權：Apache-2.0。
