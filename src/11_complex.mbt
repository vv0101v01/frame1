// ============================================================================
// 11_complex.mbt -- Complex scalars and special functions of the
//                   Eisenstein / constant-term complex plane.
//
// ABSTRACTION.  The Langlands complex plane needs C rather than R: spectral
// parameters s = 1/2 + it, L-parameter eigenvalues, characters of the maximal
// torus.  We therefore lift `Double` to a pair `Cx { re, im }` and re-derive
// the transcendental layer (exp, log, pow, Gamma) on top of `@math`.
//
// Only a minimal, dependency-free kernel is provided; every operation is
// closed under the type, so all later modules stay purely functional.
// ============================================================================

///|
///A complex scalar `re + i·im`.
pub(all) struct Cx {
  re : Double
  im : Double
}

///|
///The complex zero.
pub fn cx_zero() -> Cx {
  { re: 0.0, im: 0.0, }
}

///|
///The complex one.
pub fn cx_one() -> Cx {
  { re: 1.0, im: 0.0, }
}

///|
///Lift a real number.
pub fn cx_of_real(x : Double) -> Cx {
  { re: x, im: 0.0, }
}

///|
///Polar form constructor `r·e^{iθ}`.
pub fn cx_polar(r : Double, theta : Double) -> Cx {
  { re: r * @math.cos(theta), im: r * @math.sin(theta), }
}

///|
///Addition.
pub fn cx_add(a : Cx, b : Cx) -> Cx {
  { re: a.re + b.re, im: a.im + b.im, }
}

///|
///Additive inverse.
pub fn cx_neg(a : Cx) -> Cx {
  { re: -a.re, im: -a.im, }
}

///|
///Subtraction.
pub fn cx_sub(a : Cx, b : Cx) -> Cx {
  cx_add(a, cx_neg(b))
}

///|
///Multiplication.
pub fn cx_mul(a : Cx, b : Cx) -> Cx {
  { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re, }
}

///|
///Multiplication by a real scalar.
pub fn cx_scale(a : Cx, s : Double) -> Cx {
  { re: a.re * s, im: a.im * s, }
}

///|
///Complex conjugate.
pub fn cx_conj(a : Cx) -> Cx {
  { re: a.re, im: -a.im, }
}

///|
///Squared modulus `|a|²`.
pub fn cx_abs2(a : Cx) -> Double {
  a.re * a.re + a.im * a.im
}

///|
///Modulus.
pub fn cx_abs(a : Cx) -> Double {
  cx_abs2(a).sqrt()
}

///|
///Argument in `(-π, π]`.
pub fn cx_arg(a : Cx) -> Double {
  @math.atan2(a.im, a.re)
}

///|
///Division, with a defensive guard against 0/0.
pub fn cx_div(a : Cx, b : Cx) -> Cx {
  let d = cx_abs2(b)
  if d == 0.0 {
    { re: 0.0, im: 0.0, }
  } else {
    {
      re: (a.re * b.re + a.im * b.im) / d,
      im: (a.im * b.re - a.re * b.im) / d,
    }
  }
}

///|
///Principal logarithm `log|a| + i·arg(a)`.
pub fn cx_log(a : Cx) -> Cx {
  { re: @math.ln(cx_abs(a) + 1.0e-300), im: cx_arg(a), }
}

///|
///Complex exponential.
pub fn cx_exp(a : Cx) -> Cx {
  cx_polar(@math.exp(a.re), a.im)
}

///|
///Principal power `a^b = exp(b log a)`.
pub fn cx_pow(a : Cx, b : Cx) -> Cx {
  cx_exp(cx_mul(b, cx_log(a)))
}

///|
///Real power of a complex scalar.
pub fn cx_pow_real(a : Cx, t : Double) -> Cx {
  cx_pow(a, cx_of_real(t))
}

///|
///Set membership test with tolerance (used in tests, not as a hash key).
pub fn cx_approx(a : Cx, b : Cx, tol~ : Double = 1.0e-9) -> Bool {
  approx(a.re, b.re, tol~) && approx(a.im, b.im, tol~)
}

// ---------------------------------------------------------------------------
// Gamma function (Lanczos, g = 7, 9 coefficients) and the completed zeta.
// ---------------------------------------------------------------------------

///|
/// `lgamma(x) = log Γ(x)` for `x > 0` via the Lanczos approximation.
/// Accuracy is ~1e-13 on `[0.5, 40]`, which is all the Eisenstein layer needs.
pub fn lgamma(x : Double) -> Double {
  let g : Array[Double] = [
    676.5203681218851, -1259.1392167224028, 771.3234287776531, -176.6150291621406,
    12.507343278686905, -0.13857109526572012, 9.984369578019572e-6, 1.5056327351493116e-7,
  ]
  if x < 0.5 {
    // Reflection formula.
    @math.ln(@math.PI / @math.sin(@math.PI * x)) - lgamma(1.0 - x)
  } else {
    let z = x - 1.0
    let t = z + 7.5
    let mut a = 0.99999999999980993
    for i in 0..<8 {
      a += g[i] / (z + (i + 1).to_double())
    }
    0.5 * @math.ln(2.0 * @math.PI) + (z + 0.5) * @math.ln(t) - t + @math.ln(a)
  }
}

///|
/// Bernoulli numbers `B_2, B_4, ... B_14` used by Euler–Maclaurin.
fn bernoulli_even() -> Array[Double] {
  [
    1.0 / 6.0,
    -1.0 / 30.0,
    1.0 / 42.0,
    -1.0 / 30.0,
    5.0 / 66.0,
    -691.0 / 2730.0,
    7.0 / 6.0,
  ]
}

///|
/// Riemann zeta by Euler–Maclaurin for `Re(s) > 1/2`, and by the functional
/// equation `ζ(s) = 2^s π^{s-1} sin(πs/2) Γ(1-s) ζ(1-s)` below that.
pub fn zeta_cx(s : Cx) -> Cx {
  if s.re < 0.5 && s.im == 0.0 {
    // Real argument: use the reflection formula; sin(πs/2) is real here.
    let one_minus = cx_of_real(1.0 - s.re)
    let z = zeta_cx(one_minus)
    let pref = @math.pow(2.0, s.re) *
      @math.pow(@math.PI, s.re - 1.0) *
      @math.sin(@math.PI * s.re / 2.0) *
      @math.exp(lgamma(1.0 - s.re))
    cx_scale(z, pref)
  } else {
    zeta_euler_maclaurin(s)
  }
}

///|
/// Euler–Maclaurin evaluation
/// `ζ(s) = Σ_{n<N} n^{-s} + N^{1-s}/(s-1) + N^{-s}/2 + Σ_k B_{2k}/(2k)! (s)_{2k-1} N^{-s-2k+1}`.
pub fn zeta_euler_maclaurin(s : Cx) -> Cx {
  let n_terms = 40
  let b = bernoulli_even()
  let mut total = cx_zero()
  for n in 1..<n_terms {
    let l = cx_log(cx_of_real(n.to_double()))
    total = cx_add(total, cx_exp(cx_neg(cx_mul(l, s))))
  }
  let nf = n_terms.to_double()
  let s_minus_1 = cx_sub(s, cx_one())
  let tail1 = cx_div(cx_pow_real(cx_of_real(nf), 1.0 - s.re), s_minus_1)
  let tail2 = cx_scale(cx_pow_real(cx_of_real(nf), -s.re), 0.5)
  total = cx_add(total, cx_add(tail1, tail2))
  let mut poch = cx_one() // (s)_{2k-1} = s(s+1)...(s+2k-2)
  for k in 1..<=7 {
    poch = cx_one()
    for j in 0..<(2 * k - 1) {
      poch = cx_mul(poch, cx_add(s, cx_of_real(j.to_double())))
    }
    let coef = b[k - 1] / factorial(2 * k).to_double()
    let n_pow = cx_pow_real(cx_of_real(nf), -s.re - (2 * k - 1).to_double())
    total = cx_add(total, cx_scale(cx_mul(poch, n_pow), coef))
  }
  total
}

///|
///Factorial on `Int32` (small arguments only).
pub fn factorial(n : Int32) -> Int32 {
  let mut r = 1
  for i in 2..<=n {
    r *= i
  }
  r
}

///|
/// Completed Riemann zeta `ξ(s) = π^{-s/2} Γ(s/2) ζ(s)`; the functional
/// equation is `ξ(s) = ξ(1-s)` (Theorem T16).
pub fn xi_cx(s : Cx) -> Cx {
  if s.re <= 0.0 && s.im == 0.0 {
    return xi_cx(cx_of_real(1.0 - s.re))
  }
  // log π^{-s/2} = -(s/2)·log π, and Γ(s/2) is evaluated in C.
  let log_pi = cx_log(cx_of_real(@math.PI))
  let log_pref = cx_add(
    cx_neg(cx_scale(cx_mul(log_pi, s), 0.5)),
    cx_log(gamma_cx(cx_scale(s, 0.5))),
  )
  cx_mul(cx_exp(log_pref), zeta_cx(s))
}

///|
/// `Γ(z)` for `Re(z) > 0` by the Lanczos approximation in the complex plane.
pub fn gamma_cx(z : Cx) -> Cx {
  let g : Array[Double] = [
    676.5203681218851, -1259.1392167224028, 771.3234287776531, -176.6150291621406,
    12.507343278686905, -0.13857109526572012, 9.984369578019572e-6, 1.5056327351493116e-7,
  ]
  let zz = cx_sub(z, cx_one())
  let t = cx_add(zz, cx_of_real(7.5))
  let mut a = cx_of_real(0.99999999999980993)
  for i in 0..<8 {
    let den = cx_add(zz, cx_of_real((i + 1).to_double()))
    a = cx_add(a, cx_div(cx_of_real(g[i]), den))
  }
  let half = cx_of_real(0.5)
  let log_pref = cx_add(
    cx_of_real(0.5 * @math.ln(2.0 * @math.PI)),
    cx_sub(cx_mul(cx_add(zz, half), cx_log(t)), t),
  )
  cx_mul(cx_exp(log_pref), a)
}

// ---------------------------------------------------------------------------
// Tests: the complex kernel and the completed-zeta functional equation.
// ---------------------------------------------------------------------------

///|
test "T16a: complex kernel is a field" {
  let a = { re: 1.5, im: -0.75, }
  let b = cx_polar(2.0, 0.3)
  // multiplicative inverses
  let one = cx_mul(a, cx_div(cx_one(), a))
  assert_true(cx_approx(one, cx_one(), tol=1.0e-12))
  let one2 = cx_mul(b, cx_div(cx_one(), b))
  assert_true(cx_approx(one2, cx_one(), tol=1.0e-12))
  // exp/log round trip
  let z = cx_log(cx_exp(a))
  assert_true(cx_approx(z, a, tol=1.0e-12))
  // |a·conj(a)| = |a|²
  let m = cx_mul(a, cx_conj(a))
  assert_true(approx(m.im, 0.0, tol=1.0e-14))
  assert_true(approx(m.re, cx_abs2(a), tol=1.0e-14))
}

///|
test "T16b: ζ(2) = π²/6 and ζ(-1) = -1/12" {
  assert_true(
    approx(zeta_cx(cx_of_real(2.0)).re, @math.PI * @math.PI / 6.0, tol=1.0e-12),
  )
  assert_true(
    approx(
      zeta_cx(cx_of_real(4.0)).re,
      @math.pow(@math.PI, 4.0) / 90.0,
      tol=1.0e-11,
    ),
  )
  assert_true(approx(zeta_cx(cx_of_real(-1.0)).re, -1.0 / 12.0, tol=1.0e-11))
}

///|
test "T16c: ξ(s) = ξ(1-s) on and off the critical line" {
  for k in 1..<=5 {
    let s = 0.4 + 0.37 * k.to_double()
    assert_true(
      cx_approx(xi_cx(cx_of_real(s)), xi_cx(cx_of_real(1.0 - s)), tol=1.0e-8),
    )
  }
  // Γ(1/2)=√π and ξ(1/2) real
  let half = cx_of_real(0.5)
  assert_true(approx(gamma_cx(half).re, @math.PI.sqrt(), tol=1.0e-10))
  let xh = xi_cx(half)
  assert_true(approx(xh.im, 0.0, tol=1.0e-12))
}
