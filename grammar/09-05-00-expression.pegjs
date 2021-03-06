
// 9.5. Expression Syntax
// http://dev.mysql.com/doc/refman/5.7/en/expressions.html

// 12.3.1. Operator Precedence
// http://dev.mysql.com/doc/refman/5.7/en/operator-precedence.html

// this is actually an extension
CONSTANT_EXPRESSION "constant expression"
  = expr:EXPRESSION {
      return options.resolveConstantExpression(expr);
    }


EXPRESSION
  = _ expr:ASSIGN_EXPR _ { return options.expression(expr); }

ASSIGN_EXPR // := assignment, can be simly '=' in some cases but here i avoid it
  = left:LOGICALOR_EXPR _ tail:( ':=' _ expr:LOGICALOR_EXPR { return expr; } )+ {
      tail.unshift(left);
      return {
        operator: ":=",
        expressions: tail
      };
    }
  / LOGICALOR_EXPR

LOGICALOR_EXPR // ||, OR
  = left:LOGICALXOR_EXPR _ 
      tail:( op:('||'/'OR'i) _ expr:LOGICALXOR_EXPR { return [op, expr]; } )+ 
    {
      var exprs = [left];
      var operators = [];
      tail.forEach(function(val){
        operators.push(val[0]); // operator
        exprs.push(val[1]); // expression
      });
      return options.orExpression({
        operators: operators,
        expressions: exprs
      });
    }
  / LOGICALXOR_EXPR

LOGICALXOR_EXPR // XOR
  = left:LOGICALAND_EXPR _ tail:( 'XOR'i _ expr:LOGICALXOR_EXPR { return expr; } )+ 
    {
      tail.unshift(left);
      return options.xorExpression({
        operator: "XOR",
        expressions: tail
      });
    }
  / LOGICALAND_EXPR

LOGICALAND_EXPR // &&, AND
  = left:LOGICALNOT_EXPR _ tail:( ('&&'/'AND'i) _ expr:LOGICALNOT_EXPR { return expr; } )+ 
    {
      tail.unshift(left);
      return options.andExpression({
        operator: "AND",
        expressions: tail
      });
    }
  / LOGICALNOT_EXPR

LOGICALNOT_EXPR // NOT
  = "NOT"i __ expr:COND_EXPR 
    {
      return options.notExpression({
        unary: "NOT",
        expression: expr
      });
    }
  / COND_EXPR 

COND_EXPR 
  // TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
  // BETWEEN, CASE, WHEN, THEN, ELSE
  = COMPARISON_EXPR

COMPARISON_EXPR // = (comparison), <=>, >=, >, <=, <, <>, !=, IS, LIKE, REGEXP, IN
  = expr:BITOR_EXPR _ "IS" _ 
      not:"NOT"i? _ 
      val:("TRUE"i / "FALSE"i / "UNKNOWN"i / "NULL"i) _
    {
      return options.isExpression({
        unary: 'IS',
        not: !!not,
        value: val.toUpperCase(),
        expression: expr
      });
    }
  / left:BITOR_EXPR _ tail:(
      op:('='/'<=>'/'>='/'>'/'<='/'<'/'<>'/'!='/'LIKE'i/'REGEXP'i/'IN'i) _ 
      val:BITOR_EXPR { return [op, val]; })+
    {
      var exprs = [left];
      var operators = [];
      tail.forEach(function(val){
        operators.push(val[0]); // operator
        exprs.push(val[1]); // expression
      });
      return options.comparisonExpression({
        operators: operators,
        expressions: exprs
      });
    }
  / BITOR_EXPR

BITOR_EXPR // |
  = left:BITAND_EXPR _ tail:( '|' _ expr:BITAND_EXPR { return expr; } )+ {
      tail.unshift(left);
      return options.bitwiseOrExpression({
        operator: "|",
        expressions: tail
      });
    }
  / BITAND_EXPR

BITAND_EXPR // &
  = left:BITSHIFT_EXPR _ tail:( '&' _ expr:BITSHIFT_EXPR { return expr; } )+ {
      tail.unshift(left);
      return options.bitwiseAndExpression({
        operator: "&",
        expressions: tail
      });
    }
  / BITSHIFT_EXPR

BITSHIFT_EXPR // <<, >>
  = left:ADD_EXPR _ tail:( op:('<<'/'>>') _ val:ADD_EXPR { return [op, val]; } )+ {
      var exprs = [left];
      var operators = [];
      tail.forEach(function(val){
        operators.push(val[0]); // operator
        exprs.push(val[1]); // expression
      });
      return options.bitShiftExpression({
        operators: operators,
        expressions: exprs
      });
    }
  / ADD_EXPR

ADD_EXPR // +, -
  = left:MULT_EXPR _ tail:( op:('+'/'-') _ val:MULT_EXPR { return [op, val]; } )+ {
      var exprs = [left];
      var operators = [];
      tail.forEach(function(val){
        operators.push(val[0]); // operator
        exprs.push(val[1]); // expression
      });
      return options.addExpression({
        operators: operators,
        expressions: exprs
      });
    }
  / MULT_EXPR

MULT_EXPR // *, /, DIV, %, MOD
  = left:BITXOR_EXPR _ tail:( 
      op:('*' / '/' / 'DIV'i / '%' / 'MOD'i) _ 
      val:BITXOR_EXPR { return [op, val]; } )+ 
    {
      var exprs = [left];
      var operators = [];
      tail.forEach(function(val){
        operators.push(val[0]); // operator
        exprs.push(val[1]); // expression
      });
      return options.mulDivExpression({
        operators: operators,
        expressions: exprs
      });
    }
  / BITXOR_EXPR

BITXOR_EXPR // ^
  = left:UNARY_EXPR _ tail:( '^' _ expr:UNARY_EXPR { return expr; } )+ {
      tail.unshift(left);
      return options.bitwiseXorExpression({
        operator: "^",
        expressions: tail
      });
    }
  / UNARY_EXPR

UNARY_EXPR // - (unary minus), ~ (unary bit inversion), + (unary plus)
  = op:('~' / '+' / '-') _ expr:UNARY_EXPR {
      return options.unaryExpression({
        unary: op,
        expression: expr
      });
    } 
  / HIGH_NOT_EXPR

HIGH_NOT_EXPR // !
  = '!' _ expr:HIGH_NOT_EXPR {
      return options.notExpression({
        unary: '!',
        expression: expr
      });
    } 
  / STRING_COLLATE_EXPR

STRING_COLLATE_EXPR // COLLATE
  = expr:STRING_BINARY_EXPR _ "COLLATE"i _ collation:COLLATION_NAME {
      return options.collateExpression({
        unary: 'COLLATE',
        collation: collation,
        expression: expr
      });
    }
  / STRING_BINARY_EXPR


COLLATION_NAME "collation name"
  = ID
  / STRING


STRING_BINARY_EXPR // BINARY MODIFIER
  = "BINARY"i __ expr:INTERVAL_EXPR {
      return options.modifierBinaryExpression({
        unary: 'BINARY',
        expression: expr
      });
    }
  / INTERVAL_EXPR

INTERVAL_EXPR
  // TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
  = PRIMARY_EXPR

PRIMARY_EXPR
  = CONSTANT_VALUE
  / "(" expr:EXPRESSION ")" { return expr; }


CONSTANT_VALUE
  = NULL
  / BOOLEAN
  / STRING
  / POSITIVE_NUMBER
  / CURRENT_TIMESTAMP