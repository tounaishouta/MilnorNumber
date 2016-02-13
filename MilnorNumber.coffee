# ユーティリティ関数

getValue = (id) -> document.getElementById(id).value

setValue = (id, value) -> document.getElementById(id).value = value

setDisabled = (id, value = on) -> document.getElementById(id).disabled = value

println = (mess = "") ->
  stdout = document.getElementById("stdout")
  stdout.appendChild(document.createTextNode(mess))
  stdout.appendChild(document.createElement("br"))
  stdout.scrollTop = stdout.scrollHeight
  mess

# rel(arr[i], arr[i + 1]) となるようにバブルソートする。
# ∀ x y, rel(x, y) ∨ rel(y, x) を仮定
sortBy = (arr, rel) ->
  for i in [0 ... arr.length].reverse()
    for j in [0 ... i]
      if not rel(arr[j], arr[j + 1])
        [arr[j], arr[j + 1]] = [arr[j + 1], arr[j]]
  arr

gcd = (x, y) ->
  while y isnt 0
    r = x % y
    x = y
    y = r
  x

# 主な実装

# 使用する変数の配列
variables     = []
variableNames = []

# 項クラス
class Term

  @one = () -> new Term(variables.map(() -> 0))

  constructor: (indices) ->
    @indices = indices

  toString: () ->
    if @isOne()
      "1"
    else
      indices = @indices
      variables.filter((i) -> indices[i] isnt 0)
        .map((i) -> if indices[i] is 1 then "#{variableNames[i]}" else "#{variableNames[i]}^#{indices[i]}")
        .join(" ")

  isOne: () ->
    for index in @indices
      if index isnt 0
        return false
    return true

  # 辞書式項順序
  lexle: (that) ->
    for i in variables
      if @indices[i] < that.indices[i]
        return true
      if @indices[i] > that.indices[i]
        return false
    return true

  equiv: (that) -> @lexle(that) and that.lexle(this)

  divides: (that) ->
    for i in variables
      if @indices[i] > that.indices[i]
        return false
    return true

  hasOnly: (i0) ->
    for i in variables
      if i isnt i0 and @indices[i] isnt 0
        return false
    return true

# 単項式クラス
class Monomial

  @parse = (str) ->
    [cstr, xistrs...] = str.split(/\s+/)
    c = Number(cstr)
    indices = variables.map(() -> 0)
    for xistr in xistrs
      [x, indstr] = xistr.split("^")
      i = variableNames.indexOf(x)
      throw "illegal variable name" if i is -1
      index = if indstr? then Number(indstr) else 1
      indices[i] += index
    new Monomial(c, new Term(indices))

  @from = (c) -> new Monomial(c, Term.one())

  constructor: (coefficient, term) ->
    @coefficient = coefficient
    @term        = term

  toString: () ->
    if @term.isOne()
      "#{@coefficient}"
    else
      "#{@coefficient} #{@term}"

  derivative: (i) ->
    indices = @term.indices.slice()
    indices[i] -= 1
    new Monomial(@coefficient * @term.indices[i], new Term(indices))

  gcd: (m2) ->
    m1 = this
    c = gcd(m1.coefficient, m2.coefficient)
    indices = variables.map((i) -> Math.min(m1.term.indices[i], m2.term.indices[i]))
    new Monomial(c, new Term(indices))

  times: (m2) ->
    m1 = this
    indices = variables.map((i) -> m1.term.indices[i] + m2.term.indices[i])
    new Monomial(m1.coefficient * m2.coefficient, new Term(indices))

  divide: (m2) ->
    m1 = this
    indices = variables.map((i) -> m1.term.indices[i] - m2.term.indices[i])
    new Monomial(m1.coefficient / m2.coefficient, new Term(indices))

# 多項式クラス
class Polynomial

  @parse = (str) -> new Polynomial(str.split(/\s*\+\s*/).map(Monomial.parse))

  @zero = () -> new Polynomial([])

  constructor: (monomials) ->
    @monomials = []
    monomials = monomials.slice()
    sortBy(monomials, (m1, m2) -> m2.term.lexle(m1.term))
    while monomials.length > 0
      coefficient = 0
      term = monomials[0].term
      while monomials.length > 0 and monomials[0].term.equiv(term)
        coefficient += monomials.shift().coefficient
      if coefficient isnt 0
        @monomials.push(new Monomial(coefficient, term))

  toString: () ->
    if @isZero()
      "0"
    else
      @monomials.map((m) -> m.toString()).join(" + ")

  isZero: () -> @monomials.length is 0

  derivative: (i) -> new Polynomial(@monomials.map((m) -> m.derivative(i)))

  spolynomial: (f2) ->
    f1 = this
    return Polynomial.zero() if f1.isZero() or f2.isZero()
    g = f1.leading().gcd(f2.leading())
    q1 = f1.leading().divide(g)
    q2 = f2.leading().divide(g)
    f1.times(q2).subtract(f2.times(q1))

  leading: () -> @monomials[0]

  times: (that) ->
    that = new Polynomial([that]) if that instanceof Monomial
    monomials = []
    for m1 in @monomials
      for m2 in that.monomials
        monomials.push(m1.times(m2))
    new Polynomial(monomials)

  add: (that) -> new Polynomial(@monomials.concat(that.monomials))

  subtract: (that) -> @add(that.times(Monomial.from(-1)))

  reduce: (f2) ->
    f1 = this
    throw "Polynomial#reduce: divide by zero" if f2.isZero()
    l2 = f2.leading()
    while true
      return f1 if f1.isZero()
      l1 = f1.leading()
      return f1 if not l2.term.divides(l1.term)
      g = l1.gcd(l2) # 定数倍をのぞいて l2
      f1 = f1.times(l2.divide(g)).subtract(f2.times(l1.divide(g)))

grobner = (fs) ->
  basis = fs.slice()
  while true
    gs = []
    for i in [0 ... basis.length]
      for j in [i + 1 ... basis.length]
        s = basis[i].spolynomial(basis[j])
        for f in basis
          s = s.reduce(f)
        if not s.isZero()
          gs.push(s)
    if gs.length is 0
      return basis
    basis = basis.concat(gs)
  sortBy(basis, (f1, f2) -> f1.leading().term.lexle(f2.leading().term))

milnorNumber = (terms) ->
  limits = variables.map((i0) ->
    found = false
    min
    for term in terms
      if term.hasOnly(i0) and (not min? or min > term.indices[i0])
        min = term.indices[i0]
    min
  )
  println("limits: #{limits}")

  gs = gridsUnder(limits)

  ts = gs.map((g) -> new Term(g))

  for term in terms
    ts = ts.filter((t) -> not term.divides(t))

  ts.length

gridsUnder = (limits) ->
  if limits.length is 0
    [[]]
  else
    [limit, limits_...] = limits
    gs = gridsUnder(limits_)
    [].concat([0 ... limit].map((i) -> gs.map((g) -> [i].concat(g)))...)


# メイン

# 初期値を設定
setDisabled("variables", off)
setValue("variables", "x y")
setDisabled("f", off)
setValue("f", "1 x^3 + 1 x y^2")
setDisabled("compute", off)

document.getElementById("compute").addEventListener("click", ->

  println("start!")
  setDisabled("variables")
  setDisabled("f")
  setDisabled("compute")
  setValue("mu", "")

  setTimeout(->

    variableNames = getValue("variables").split(/\s+/)
    variables = [0 ... variableNames.length]
    println("variables: #{variableNames}")

    f = Polynomial.parse(getValue("f"))
    println("f: #{f}")

    dfs = variables.map((i) -> f.derivative(i))
    println("dfs: #{dfs}")

    basis = grobner(dfs)
    println("basis: #{basis}")

    lts = basis.map((f) -> f.leading().term)
    println("lts: #{lts}")

    mu = milnorNumber(lts)
    println("mu: #{mu}")

    setValue("mu", mu)

    println("finish!")
    setDisabled("variables", off)
    setDisabled("f", off)
    setDisabled("compute", off)
  )
)
