# 変数は内部的には 0 から始まる整数として取り扱う。
variables = []

# 入出力のために変数と文字列をひもづける。
variableNames = []

grobnerBasis = (fs) ->
  fs = fs.filter((f) -> not f.isZero())
  while true
    println("in grobnerBasis, fs: #{fs}")
    added = false
    len = fs.length
    for i in [0 ... len]
      for j in [i + 1 ... len]
        s = sPolynomial(fs[i], fs[j])
        while true
          reduced = false
          for f in fs
            if reducible(s, f)
              s = reduce(s, f)
              reduced = true
          if not reduced
            break
        if not s.isZero()
          fs.push(s)
          added = true
    if not added
      return fs

sPolynomial = (f1, f2) ->
  if f1.isZero() or f2.isZero()
    throw "sPolynomial: zero"
  l1 = f1.leading()
  l2 = f2.leading()
  g = Monomial.gcd(l1, l2)
  f1.times(Polynomial.from(l2.divide(g)))
    .subtract(f2.times(Polynomial.from(l1.divide(g))))

reducible = (f1, f2) ->
  if f2.isZero()
    throw "reduce: try to reduce by zero"
  if f1.isZero()
    return false
  return f2.leading().term.divides(f1.leading().term)

reduce = (f1, f2) ->
  if f1.isZero()
    return f1
  l1 = f1.leading()
  if f2.isZero()
    throw "reduce: try to reduce by zero"
  l2 = f2.leading()
  if not l2.term.divides(l1.term)
    return f1
  g = Monomial.gcd(l1, l2)
  return f1.times(Polynomial.from(l2.divide(g)))
          .subtract(f2.times(Polynomial.from(l1.divide(g))))

quotientBasis = (generators) ->

  limits = variables.map((x) ->
    limit = notFound
    for generator in generators
      if generator.hasOnly(x)
        if limit is notFound or limit > generator.indices[x]
          limit = generator.indices[x]
    limit
  )

  for limit in limits
    if limit is notFound
      return notFound

  terms = gridsUnder(limits).map((grid) -> new Term(grid))

  for generator in generators
    terms = terms.filter((term) -> not generator.divides(term))

  terms

gridsUnder = (limits) ->
  if limits.length is 0
    [[]]
  else
    [limit, limits_...] = limits
    grids = gridsUnder(limits_)
    [].concat([0 ... limit].map((i) -> grids.map((grid) -> [i].concat(grid)))...)

class Polynomial

  constructor: (monomials) ->
    @monomials = []
    monomials = sortBy(monomials, (m1, m2) -> m2.term.lexle(m1.term))
    while monomials.length > 0
      coefficient = 0
      term = monomials[0].term
      while monomials.length > 0 and monomials[0].term.equals(term)
        coefficient += monomials.shift().coefficient
      if coefficient isnt 0
        @monomials.push(new Monomial(coefficient, term))

  toString: () ->
    if @isZero()
      "0"
    else
      @monomials.map((m) -> m.toString()).join(" + ")

  isZero: () -> @monomials.length is 0

  leading: () -> @monomials[0]

  derivative: (x) -> new Polynomial(@monomials.map((m) -> m.derivative(x)))

  add: (that) -> new Polynomial(@monomials.concat(that.monomials))

  subtract: (that) -> @add(that.times(Polynomial.from(Monomial.from(-1))))

  times: (that) ->
    monomials = []
    for m1 in @monomials
      for m2 in that.monomials
        monomials.push(m1.times(m2))
    new Polynomial(monomials)

  @parse: (str) -> new Polynomial(str.split(/\s*\+\s*/).map(Monomial.parse))

  @from: (monomials...) -> new Polynomial(monomials)

class Monomial

  constructor: (@coefficient, @term) ->

  toString: () ->
    if @term.isOne()
      "#{@coefficient}"
    else
      "#{@coefficient} #{@term}"

  derivative: (x) ->
    indices = @term.indices.slice()
    indices[x] -= 1
    new Monomial(@coefficient * @term.indices[x], new Term(indices))

  times: (that) ->
    new Monomial(@coefficient * that.coefficient, @term.times(that.term))

  divide: (that) ->
    new Monomial(@coefficient / that.coefficient, @term.divide(that.term))

  @from: (coefficient) -> new Monomial(coefficient, Term.one())

  @parse: (str) ->
    [cstr, xistrs...] = str.split(/\s+/)
    coefficient = Number(cstr)
    indices = variables.map((x) -> 0)
    for xistr in xistrs
      [xstr, istr] = xistr.split("^")
      x = variableNames.indexOf(xstr)
      if x is -1
        throw "Monomial#parse: illegal variable name `#{xstr}`"
      i = if istr? then Number(istr) else 1
      indices[x] += i
    new Monomial(coefficient, new Term(indices))

  @gcd: (m1, m2) ->
    coefficient = gcd(m1.coefficient, m2.coefficient)
    term = new Term.gcd(m1.term, m2.term)
    new Monomial(coefficient, term)

class Term

  constructor: (@indices) ->

  toString: () ->
    if @isOne()
      "1"
    else
      self = this
      variables
        .filter((x) -> self.indices[x] isnt 0)
        .map((x) ->
          if self.indices[x] is 1
            "#{variableNames[x]}"
          else
            "#{variableNames[x]}^#{self.indices[x]}"
        )
        .join(" ")

  isOne: () ->
    for x in variables
      if @indices[x] isnt 0
        return false
    return true

  equals: (that) ->
    for x in variables
      if @indices[x] isnt that.indices[x]
        return false
    return true

  # 辞書式順序に基づく項順序
  lexle: (that) ->
    for x in variables
      if @indices[x] < that.indices[x]
        return true
      if @indices[x] > that.indices[x]
        return false
    return true

  divides: (that) ->
    for x in variables
      if @indices[x] > that.indices[x]
        return false
    return true

  times: (t2) ->
    t1 = this
    indices = variables.map((x) -> t1.indices[x] + t2.indices[x])
    new Term(indices)

  divide: (t2) ->
    t1 = this
    indices = variables.map((x) -> t1.indices[x] - t2.indices[x])
    new Term(indices)

  hasOnly: (x0) ->
    for x in variables
      if x isnt x0 and @indices[x] isnt 0
        return false
    return true

  @one: () ->
    indices = variables.map((x) -> 0)
    new Term(indices)

  @gcd: (t1, t2) ->
    indices = variables.map((x) -> Math.min(t1.indices[x], t2.indices[x]))
    new Term(indices)

###############################################################################

# ユーティリティ関数

notFound = -1

gcd = (x, y) ->
  while y isnt 0
    r = x % y
    x = y
    y = r
  x

# rel(arr[i], arr[i + 1]) となるようにバブルソート
# 任意の x, y について rel(x, y) と rel(y, x) のどちらかが成り立つと仮定
sortBy = (arr, rel) ->
  arr = arr.slice()
  for i in [0 ... arr.length].reverse()
    for j in [0 ... i]
      if not rel(arr[j], arr[j + 1])
        [arr[j], arr[j + 1]] = [arr[j + 1], arr[j]]
  arr

println = (mess = "") ->
  stdout = document.getElementById("stdout")
  stdout.appendChild(document.createTextNode(mess))
  stdout.appendChild(document.createElement("br"))
  stdout.scrollTop = stdout.scrollHeight
  mess

getValue = (id) -> document.getElementById(id).value

setValue = (id, value) -> document.getElementById(id).value = value

setDisabled = (id, value = on) -> document.getElementById(id).disabled = value

###############################################################################

# メイン

setValue("variables", "x y")
setValue("f", "1 x^3 + -1 x y^2")
setValue("mu", "")

setDisabled("variables", off)
setDisabled("f", off)
setDisabled("compute", off)

document.getElementById("compute").onclick = () ->

  println("start!")
  setDisabled("variables")
  setDisabled("f")
  setDisabled("compute")

  setTimeout ->

    variableNames = getValue("variables").split(/\s+/)
    variables = [0 ... variableNames.length]
    println("variables: #{variableNames}")

    f = Polynomial.parse(getValue("f"))
    println("f: #{f}")

    dfs = variables.map((x) -> f.derivative(x))
    println("dfs: #{dfs}")

    setTimeout ->

      basis = grobnerBasis(dfs)
      println("basis: #{basis}")

      lts = basis.map((f) -> f.leading().term)
      println("lts: #{lts}")

      setTimeout ->

        qbasis = quotientBasis(lts)
        if qbasis is notFound
          println("qbasis: infinite")
          mu = "Infinity"
        else
          println("qbasis: #{qbasis}")
          mu = qbasis.length

        println("mu: #{mu}")

        setValue("mu", mu)

        println("finish!")
        setDisabled("variables", off)
        setDisabled("f", off)
        setDisabled("compute", off)
