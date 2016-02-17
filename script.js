// Generated by CoffeeScript 1.10.0
(function() {
  var Monomial, Polynomial, Term, gcd, getValue, gridsUnder, grobnerBasis, notFound, println, quotientBasis, reduce, reducible, sPolynomial, setDisabled, setValue, sortBy, variableNames, variables,
    slice = [].slice;

  variables = [];

  variableNames = [];

  grobnerBasis = function(fs) {
    var added, f, i, j, k, l, len, len1, n, reduced, ref, ref1, ref2, s;
    fs = fs.filter(function(f) {
      return !f.isZero();
    });
    while (true) {
      println("in grobnerBasis, fs: " + fs);
      added = false;
      len = fs.length;
      for (i = k = 0, ref = len; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
        for (j = l = ref1 = i + 1, ref2 = len; ref1 <= ref2 ? l < ref2 : l > ref2; j = ref1 <= ref2 ? ++l : --l) {
          s = sPolynomial(fs[i], fs[j]);
          while (true) {
            reduced = false;
            for (n = 0, len1 = fs.length; n < len1; n++) {
              f = fs[n];
              if (reducible(s, f)) {
                s = reduce(s, f);
                reduced = true;
              }
            }
            if (!reduced) {
              break;
            }
          }
          if (!s.isZero()) {
            fs.push(s);
            added = true;
          }
        }
      }
      if (!added) {
        return fs;
      }
    }
  };

  sPolynomial = function(f1, f2) {
    var g, l1, l2;
    if (f1.isZero() || f2.isZero()) {
      throw "sPolynomial: zero";
    }
    l1 = f1.leading();
    l2 = f2.leading();
    g = Monomial.gcd(l1, l2);
    return f1.times(Polynomial.from(l2.divide(g))).subtract(f2.times(Polynomial.from(l1.divide(g))));
  };

  reducible = function(f1, f2) {
    if (f2.isZero()) {
      throw "reduce: try to reduce by zero";
    }
    if (f1.isZero()) {
      return false;
    }
    return f2.leading().term.divides(f1.leading().term);
  };

  reduce = function(f1, f2) {
    var g, l1, l2;
    if (f1.isZero()) {
      return f1;
    }
    l1 = f1.leading();
    if (f2.isZero()) {
      throw "reduce: try to reduce by zero";
    }
    l2 = f2.leading();
    if (!l2.term.divides(l1.term)) {
      return f1;
    }
    g = Monomial.gcd(l1, l2);
    return f1.times(Polynomial.from(l2.divide(g))).subtract(f2.times(Polynomial.from(l1.divide(g))));
  };

  quotientBasis = function(generators) {
    var generator, k, l, len1, len2, limit, limits, terms;
    limits = variables.map(function(x) {
      var generator, k, len1, limit;
      limit = notFound;
      for (k = 0, len1 = generators.length; k < len1; k++) {
        generator = generators[k];
        if (generator.hasOnly(x)) {
          if (limit === notFound || limit > generator.indices[x]) {
            limit = generator.indices[x];
          }
        }
      }
      return limit;
    });
    for (k = 0, len1 = limits.length; k < len1; k++) {
      limit = limits[k];
      if (limit === notFound) {
        return notFound;
      }
    }
    terms = gridsUnder(limits).map(function(grid) {
      return new Term(grid);
    });
    for (l = 0, len2 = generators.length; l < len2; l++) {
      generator = generators[l];
      terms = terms.filter(function(term) {
        return !generator.divides(term);
      });
    }
    return terms;
  };

  gridsUnder = function(limits) {
    var grids, k, limit, limits_, ref, results;
    if (limits.length === 0) {
      return [[]];
    } else {
      limit = limits[0], limits_ = 2 <= limits.length ? slice.call(limits, 1) : [];
      grids = gridsUnder(limits_);
      return (ref = []).concat.apply(ref, (function() {
        results = [];
        for (var k = 0; 0 <= limit ? k < limit : k > limit; 0 <= limit ? k++ : k--){ results.push(k); }
        return results;
      }).apply(this).map(function(i) {
        return grids.map(function(grid) {
          return [i].concat(grid);
        });
      }));
    }
  };

  Polynomial = (function() {
    function Polynomial(monomials) {
      var coefficient, term;
      this.monomials = [];
      monomials = sortBy(monomials, function(m1, m2) {
        return m2.term.lexle(m1.term);
      });
      while (monomials.length > 0) {
        coefficient = 0;
        term = monomials[0].term;
        while (monomials.length > 0 && monomials[0].term.equals(term)) {
          coefficient += monomials.shift().coefficient;
        }
        if (coefficient !== 0) {
          this.monomials.push(new Monomial(coefficient, term));
        }
      }
    }

    Polynomial.prototype.toString = function() {
      if (this.isZero()) {
        return "0";
      } else {
        return this.monomials.map(function(m) {
          return m.toString();
        }).join(" + ");
      }
    };

    Polynomial.prototype.isZero = function() {
      return this.monomials.length === 0;
    };

    Polynomial.prototype.leading = function() {
      return this.monomials[0];
    };

    Polynomial.prototype.derivative = function(x) {
      return new Polynomial(this.monomials.map(function(m) {
        return m.derivative(x);
      }));
    };

    Polynomial.prototype.add = function(that) {
      return new Polynomial(this.monomials.concat(that.monomials));
    };

    Polynomial.prototype.subtract = function(that) {
      return this.add(that.times(Polynomial.from(Monomial.from(-1))));
    };

    Polynomial.prototype.times = function(that) {
      var k, l, len1, len2, m1, m2, monomials, ref, ref1;
      monomials = [];
      ref = this.monomials;
      for (k = 0, len1 = ref.length; k < len1; k++) {
        m1 = ref[k];
        ref1 = that.monomials;
        for (l = 0, len2 = ref1.length; l < len2; l++) {
          m2 = ref1[l];
          monomials.push(m1.times(m2));
        }
      }
      return new Polynomial(monomials);
    };

    Polynomial.parse = function(str) {
      return new Polynomial(str.split(/\s*\+\s*/).map(Monomial.parse));
    };

    Polynomial.from = function() {
      var monomials;
      monomials = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return new Polynomial(monomials);
    };

    return Polynomial;

  })();

  Monomial = (function() {
    function Monomial(coefficient1, term1) {
      this.coefficient = coefficient1;
      this.term = term1;
    }

    Monomial.prototype.toString = function() {
      if (this.term.isOne()) {
        return "" + this.coefficient;
      } else {
        return this.coefficient + " " + this.term;
      }
    };

    Monomial.prototype.derivative = function(x) {
      var indices;
      indices = this.term.indices.slice();
      indices[x] -= 1;
      return new Monomial(this.coefficient * this.term.indices[x], new Term(indices));
    };

    Monomial.prototype.times = function(that) {
      return new Monomial(this.coefficient * that.coefficient, this.term.times(that.term));
    };

    Monomial.prototype.divide = function(that) {
      return new Monomial(this.coefficient / that.coefficient, this.term.divide(that.term));
    };

    Monomial.from = function(coefficient) {
      return new Monomial(coefficient, Term.one());
    };

    Monomial.parse = function(str) {
      var coefficient, cstr, i, indices, istr, k, len1, ref, ref1, x, xistr, xistrs, xstr;
      ref = str.split(/\s+/), cstr = ref[0], xistrs = 2 <= ref.length ? slice.call(ref, 1) : [];
      coefficient = Number(cstr);
      indices = variables.map(function(x) {
        return 0;
      });
      for (k = 0, len1 = xistrs.length; k < len1; k++) {
        xistr = xistrs[k];
        ref1 = xistr.split("^"), xstr = ref1[0], istr = ref1[1];
        x = variableNames.indexOf(xstr);
        if (x === -1) {
          throw "Monomial#parse: illegal variable name `" + xstr + "`";
        }
        i = istr != null ? Number(istr) : 1;
        indices[x] += i;
      }
      return new Monomial(coefficient, new Term(indices));
    };

    Monomial.gcd = function(m1, m2) {
      var coefficient, term;
      coefficient = gcd(m1.coefficient, m2.coefficient);
      term = new Term.gcd(m1.term, m2.term);
      return new Monomial(coefficient, term);
    };

    return Monomial;

  })();

  Term = (function() {
    function Term(indices1) {
      this.indices = indices1;
    }

    Term.prototype.toString = function() {
      var self;
      if (this.isOne()) {
        return "1";
      } else {
        self = this;
        return variables.filter(function(x) {
          return self.indices[x] !== 0;
        }).map(function(x) {
          if (self.indices[x] === 1) {
            return "" + variableNames[x];
          } else {
            return variableNames[x] + "^" + self.indices[x];
          }
        }).join(" ");
      }
    };

    Term.prototype.isOne = function() {
      var k, len1, x;
      for (k = 0, len1 = variables.length; k < len1; k++) {
        x = variables[k];
        if (this.indices[x] !== 0) {
          return false;
        }
      }
      return true;
    };

    Term.prototype.equals = function(that) {
      var k, len1, x;
      for (k = 0, len1 = variables.length; k < len1; k++) {
        x = variables[k];
        if (this.indices[x] !== that.indices[x]) {
          return false;
        }
      }
      return true;
    };

    Term.prototype.lexle = function(that) {
      var k, len1, x;
      for (k = 0, len1 = variables.length; k < len1; k++) {
        x = variables[k];
        if (this.indices[x] < that.indices[x]) {
          return true;
        }
        if (this.indices[x] > that.indices[x]) {
          return false;
        }
      }
      return true;
    };

    Term.prototype.divides = function(that) {
      var k, len1, x;
      for (k = 0, len1 = variables.length; k < len1; k++) {
        x = variables[k];
        if (this.indices[x] > that.indices[x]) {
          return false;
        }
      }
      return true;
    };

    Term.prototype.times = function(t2) {
      var indices, t1;
      t1 = this;
      indices = variables.map(function(x) {
        return t1.indices[x] + t2.indices[x];
      });
      return new Term(indices);
    };

    Term.prototype.divide = function(t2) {
      var indices, t1;
      t1 = this;
      indices = variables.map(function(x) {
        return t1.indices[x] - t2.indices[x];
      });
      return new Term(indices);
    };

    Term.prototype.hasOnly = function(x0) {
      var k, len1, x;
      for (k = 0, len1 = variables.length; k < len1; k++) {
        x = variables[k];
        if (x !== x0 && this.indices[x] !== 0) {
          return false;
        }
      }
      return true;
    };

    Term.one = function() {
      var indices;
      indices = variables.map(function(x) {
        return 0;
      });
      return new Term(indices);
    };

    Term.gcd = function(t1, t2) {
      var indices;
      indices = variables.map(function(x) {
        return Math.min(t1.indices[x], t2.indices[x]);
      });
      return new Term(indices);
    };

    return Term;

  })();

  notFound = -1;

  gcd = function(x, y) {
    var r;
    while (y !== 0) {
      r = x % y;
      x = y;
      y = r;
    }
    return x;
  };

  sortBy = function(arr, rel) {
    var i, j, k, l, len1, n, ref, ref1, ref2, ref3, results;
    arr = arr.slice();
    ref1 = (function() {
      results = [];
      for (var l = 0, ref = arr.length; 0 <= ref ? l < ref : l > ref; 0 <= ref ? l++ : l--){ results.push(l); }
      return results;
    }).apply(this).reverse();
    for (k = 0, len1 = ref1.length; k < len1; k++) {
      i = ref1[k];
      for (j = n = 0, ref2 = i; 0 <= ref2 ? n < ref2 : n > ref2; j = 0 <= ref2 ? ++n : --n) {
        if (!rel(arr[j], arr[j + 1])) {
          ref3 = [arr[j + 1], arr[j]], arr[j] = ref3[0], arr[j + 1] = ref3[1];
        }
      }
    }
    return arr;
  };

  println = function(mess) {
    var stdout;
    if (mess == null) {
      mess = "";
    }
    stdout = document.getElementById("stdout");
    stdout.appendChild(document.createTextNode(mess));
    stdout.appendChild(document.createElement("br"));
    stdout.scrollTop = stdout.scrollHeight;
    return mess;
  };

  getValue = function(id) {
    return document.getElementById(id).value;
  };

  setValue = function(id, value) {
    return document.getElementById(id).value = value;
  };

  setDisabled = function(id, value) {
    if (value == null) {
      value = true;
    }
    return document.getElementById(id).disabled = value;
  };

  setValue("variables", "x y");

  setValue("f", "1 x^3 + -1 x y^2");

  setValue("mu", "");

  setDisabled("variables", false);

  setDisabled("f", false);

  setDisabled("compute", false);

  document.getElementById("compute").onclick = function() {
    println("start!");
    setDisabled("variables");
    setDisabled("f");
    setDisabled("compute");
    return setTimeout(function() {
      var dfs, f, k, ref, results;
      variableNames = getValue("variables").split(/\s+/);
      variables = (function() {
        results = [];
        for (var k = 0, ref = variableNames.length; 0 <= ref ? k < ref : k > ref; 0 <= ref ? k++ : k--){ results.push(k); }
        return results;
      }).apply(this);
      println("variables: " + variableNames);
      f = Polynomial.parse(getValue("f"));
      println("f: " + f);
      dfs = variables.map(function(x) {
        return f.derivative(x);
      });
      println("dfs: " + dfs);
      return setTimeout(function() {
        var basis, lts;
        basis = grobnerBasis(dfs);
        println("basis: " + basis);
        lts = basis.map(function(f) {
          return f.leading().term;
        });
        println("lts: " + lts);
        return setTimeout(function() {
          var mu, qbasis;
          qbasis = quotientBasis(lts);
          if (qbasis === notFound) {
            println("qbasis: infinite");
            mu = "Infinity";
          } else {
            println("qbasis: " + qbasis);
            mu = qbasis.length;
          }
          println("mu: " + mu);
          setValue("mu", mu);
          println("finish!");
          setDisabled("variables", false);
          setDisabled("f", false);
          return setDisabled("compute", false);
        });
      });
    });
  };

}).call(this);
