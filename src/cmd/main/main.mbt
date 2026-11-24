///|
fn main {
  let cfg = @geo.default_config()
  let trace = @geo.run_emergence(cfg)
  println("# superemergence / MoonBit 0.10 / arena.superemergence")
  println(trace.summary())
  println("# BEGIN_CSV")
  println(trace.csv())
  println("# END_CSV")
  // ---- second pipeline: Eisenstein / Betti / ^G-operator -------------------
  let lcfg = @geo.langlands_default_config()
  let ltr = @geo.run_langlands(lcfg)
  println(
    "# langlands-emergence / Eisenstein series + non-semisimple L-parameters",
  )
  println(ltr.summary)
  println("# BEGIN_CSV_LANG")
  println(ltr.csv())
  println("# END_CSV_LANG")
  // ---- third pipeline: Frontier synthesis (M^{4|32} + B_2 Adelic + Oper + AD)
  let ftr = @geo.run_frontier_emergence()
  println(ftr.summary)
  println("# BEGIN_CSV_FRONTIER")
  println(ftr.csv())
  println("# END_CSV_FRONTIER")
  // ---- fourth pipeline: Grothendieck universes x Langlands x l-adic diamonds
  let utr = @geo.run_universe_emergence()
  println(utr.summary)
  println("# BEGIN_CSV_UNIVERSE")
  println(utr.csv())
  println("# END_CSV_UNIVERSE")
}
