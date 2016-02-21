# variables[i] は i 番目の変数の名前
variables = []

class Term

  constructor: (degrees) ->
    # degrees[i] は i 番目の変数の次数
    @degrees = degrees

  toString: ->
    if @isOne()
      "1"
    else
      indices(variables)
        .filter((i) => @degrees[i] isnt 0)
        .map((i) =>
          if @degrees[i] is 1
            "#{variables[i]}"
          else
            "#{variables[i]}^#{@degrees[i]}"
        ).join(" ")

  isOne: ->
    indices(variables).every((i) => this.degrees[i] is 0)

  totalDegree: ->
    @degrees.reduce(((x, y) => x + y), 0)

  equals: (that) ->
    indices(variables).every((i) => this.degrees[i] is that.degrees[i])

  divides: (that) ->
    indices(variables).every((i) => this.degrees[i] <= that.degrees[i])

  # 項順序
  lessThan: (that) ->

    this_deg = this.totalDegree()
    that_deg = that.totalDegree()
    if this_deg < that_deg
      return true
    if this_deg > that_deg
      return false

    for i in indices(variables)
      if this.degrees[i] < that.degrees[i]
        return true
      if this.degrees[i] > that.degrees[i]
        return false

    return false

  multiply: (that) ->
    degrees = indices(variables).map((i) => this.degrees[i] + that.degrees[i])
    new Term(degrees)

  divide: (that) ->
    degrees = indices(variables).map((i) => this.degrees[i] - that.degrees[i])
    new Term(degrees)

  gcd: (that) ->
    degrees = indices(variables).map((i) =>
      Math.min(this.degrees[i],that.degrees[i])
    )
    new Term(degrees)

  # i 番目以外の次数が 0 のとき true
  hasOnly: (i) ->
    indices(variables).filter((j) => j isnt i).every((j) => @degrees[j] is 0)

  @one = =>
    degrees = indices(variables).map((i) => 0)
    new Term(degrees)

  @parse = (input) =>
    degrees = indices(variables).map((i) => 0)
    input.split(/\s+/).forEach((str) =>

      match = str.match(/^(\w+)\^(\d+)$/)
      if match
        x = match[1]
        n = Number(match[2])
      else
        x = str
        n = 1

      i = variables.indexOf(x)
      if i is -1
        println "Illegal variable name: '#{x}'"
        throw "In Term.parse"

      degrees[i] += n
    )
    new Term(degrees)

class Monomial

  constructor: (coef, term) ->
    @coef = coef
    @term = term

  toString: ->
    if @coef is 1
      "#{@term}"
    else if @term.isOne()
      "#{@coef}"
    else
      "#{@coef} #{@term}"

  multiply: (that) ->
    new Monomial(this.coef * that.coef, this.term.multiply(that.term))

  divide: (that) ->
    new Monomial(this.coef / that.coef, this.term.divide(that.term))

  gcd: (that) ->
    new Monomial(gcd(this.coef, that.coef), this.term.gcd(that.term))

  derivative: (i) ->
    coef = @coef * @term.degrees[i]
    degrees = indices(variables).map((j) =>
      @term.degrees[j] - if j is i then 1 else 0
    )
    term = new Term(degrees)
    new Monomial(coef, term)

  # Number を Monomial にキャスト
  @from = (coef) =>
    new Monomial(coef, Term.one())

  @parse = (input) =>

    match = input.match(/^-?\d+$/)
    if match
      return Monomial.of(Number(input))

    match = input.match(/^(-?\d+)\s+(.*)$/)
    if match
      coef = Number(match[1])
      term = Term.parse(match[2])
    else
      coef = 1
      term = Term.parse(input)
    new Monomial(coef, term)

class Polynomial

  constructor: (monomials) ->
    # 自身を構成する単項式からなる配列
    # 項順序で降順にソートされ、
    # 同類項はまとめられ、
    # 係数 0 の単項式を持たない。
    @monomials = []
    monomials = sortBy(monomials, (m1, m2) => not m1.term.lessThan(m2.term))
    while monomials.length > 0
      coef = 0
      term = monomials[0].term
      while monomials.length > 0 and monomials[0].term.equals(term)
        coef += monomials.shift().coef
      if coef isnt 0
        @monomials.push(new Monomial(coef, term))

  toString: ->
    @monomials.map((m) => "#{m}").join(" + ")

  isZero: ->
    @monomials.length is 0

  add: (that) ->
    new Polynomial(this.monomials.concat(that.monomials))

  subtract: (that) ->
    this.add(that.multiply(Polynomial.from(Monomial.from(-1))))

  multiply: (that) ->
    monomials = concat(this.monomials.map((m1) =>
      that.monomials.map((m2) => m1.multiply(m2))
    ))
    new Polynomial(monomials)

  derivative: (i) ->
    new Polynomial(@monomials.map((m) => m.derivative(i)))

  # 項順序で先頭の項
  leading: ->
    @monomials[0]

  # S-polynomial
  sPolynomial: (that) ->
    if this.isZero() or that.isZero()
      throw "In Polynomial.prototype.sPolynomial"
    g = this.leading().gcd(that.leading())
    this.multiply(Polynomial.from(that.leading().divide(g)))
      .subtract(that.multiply(Polynomial.from(this.leading().divide(g))))

  # lead-reducible
  isReducibleBy: (that) ->
    if this.isZero()
      false
    else if that.isZero()
      throw "In Polynomial.prototype.isReducibleBy"
    else
      that.leading().term.divides(this.leading().term)

  reduce: (that) ->
    this.sPolynomial(that)

  # this を those に含まれる多項式を用いて
  # 簡約できなくなるまで簡約したものを返す。
  reduceByList: (those) ->
    result = this
    while true
      reduced = false
      for that in those
        if result.isReducibleBy(that)
          result = result.reduce(that)
          reduced = true
      if not reduced
        return result

  # (複数の) 単項式を多項式にキャスト
  @from = (monomials...) =>
    new Polynomial(monomials)

  @parse = (input) =>
    monomials = input.split(/\s*\+\s*/).map(Monomial.parse)
    new Polynomial(monomials)

# 配列 arr の添字からなる配列を返す。
indices = (arr) =>
  [0 ... arr.length]

# 配列の配列を配列に i.e. concat([[a, b], [c, d]]) = [a, b, c, d]
concat = (arrs) =>
  [].concat(arrs...)

# 最大公約数
gcd = (x, y) =>
  while y isnt 0
    r = x % y
    x = y
    y = r
  x

# rel を用いてバブルソート
# rel(x, y) or rel(y, x) が常になりたつことを仮定し、
# rel(arr[i], arr[i + 1]) をみたす配列を返す。
sortBy = (arr, rel) =>
  arr = arr.slice()
  len = arr.length
  for i in [0 ... len].reverse()
    for j in [0 ... i]
      if not rel(arr[j], arr[j + 1])
        [arr[j], arr[j + 1]] = [arr[j + 1], arr[j]]
  arr

# 多項式からなる配列 fs を引数にとり
# fs の要素で生成される Grobner basis を
# Buchberger's algorithm で計算する。
computeGrobnerBasis = (fs) =>
  fs = fs.filter((f) => not f.isZero())
  while true
    added = false
    for s in allSPolynomials(fs)
      s = s.reduceByList(fs)
      if not s.isZero()
        fs.push(s)
        added = true
    if not added
      return fs

# fs の全てのペアに関する S-多項式の配列を返す。
allSPolynomials = (fs) =>
  len = fs.length
  concat([0 ... len].map((i) =>
    [i + 1 ... len].map((j) => fs[i].sPolynomial(fs[j]))
  ))

# 単項式からなる配列 generators を引数に取り
# generators による単項式イデアルの基底を返す。
# 無限次元になる場合は文字列 "Infinity" を返す。
basisOfQuotient = (generators) =>

  try
    upperBound = indices(variables).map((i) =>
      generators
        .filter((generator) => generator.hasOnly(i))
        .map((generator) => generator.degrees[i])
        .reduce(Math.min) # 空配列に対して reduce すると例外が投げられる。
      )
  catch error
    return "Infinity"

  # upperBound より全ての次数が小さい単項式全体
  allTerms = latticePointUnder(upperBound).map((lp) => new Term(lp))

  generators.reduce(((terms, generator) =>
    terms.filter((term) => not generator.divides(term))
  ), allTerms)

# upperBound より全ての要素が小さい配列全体
# i.e latticePointUnder([2, 3]) = [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2]]
latticePointUnder = (upperBound) =>
  if upperBound.length is 0
    return [[]]
  [head, tail...] = upperBound
  lps = latticePointUnder(tail)
  concat([0 ... head].map((i) =>
    lps.map((lp) => [i].concat(lp))
  ))

println = (mess = "") =>
  stdout = document.getElementById("stdout")
  stdout.appendChild(document.createTextNode(mess))
  stdout.appendChild(document.createElement("br"))
  stdout.scrollTop = stdout.scrollHeight

getValue = (id) =>
  document.getElementById(id).value

setValue = (id, value) =>
  document.getElementById(id).value = value

setEnable = (id) =>
  document.getElementById(id).disabled = false

setDisable = (id) =>
  document.getElementById(id).disabled = true

doSequentially = (fns) =>
  if fns.length is 0
    return
  [head, tail...] = fns
  head()
  setTimeout(=> doSequentially(tail))

onclick = =>

  f = dfs = basis = lts = qbasis = mu = null # 変数宣言の代わり

  doSequentially([
    =>
      ["variables", "f", "compute"].forEach(setDisable)
      println("Start!")
    =>
      variables = getValue("variables").split(/\s+/)
      println("variables: #{variables}")
    =>
      f = Polynomial.parse(getValue("f"))
      println("f = #{f}")
    =>
      # f の偏微分からなる配列
      dfs = indices(variables).map((i) => f.derivative(i))
      indices(variables).forEach((i) =>
        println("f_#{variables[i]} = #{dfs[i]}")
      )
    =>
      # dfs から生成される Grobner basis
      basis = computeGrobnerBasis(dfs)
      println("Grobner basis: {")
      for g in basis
        println("> #{g}")
      println("> }")
    =>
      # basis の leading term たち
      lts = basis.map((g) => g.leading().term)
      println("leading terms: {")
      for term in lts
        println("> #{term}")
      println("> }")
    =>
      qbasis = basisOfQuotient(lts)
      if qbasis is "Infinity"
        mu = "Infinity"
      else
        println("basis of quotient: {")
        qbasis.forEach((term) => println("> #{term}"))
        println("> }")
        mu = qbasis.length
      println("Milnor Number: #{mu}")
      setValue("mu", mu)
    =>
      ["variables", "f", "compute"].forEach(setEnable)
      println("Finish!")
      println()
  ])

main = =>
  setValue("variables", "x y")
  setValue("f", "x^3 + -1 x y^2")
  setValue("mu", "")
  ["variables", "f", "compute"].forEach(setEnable)
  document.getElementById("compute").onclick = onclick

main()
