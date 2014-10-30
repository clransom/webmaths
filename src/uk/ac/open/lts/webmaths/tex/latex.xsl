<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:m="http://www.w3.org/1998/Math/MathML"
    xmlns:w="http://ns.open.ac.uk/lts/webmaths">
<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="m:mtext"/>

<!--
  List of characters with accent=true. Obtained from operator dictionary file 'dict'
  saved from http://www.w3.org/TR/MathML2/appendixf.html using following Unix
  command:
  grep accent= dict | awk '{print $1}' | awk '{printf("%s",$0);}' | sed -e 's/"//g;'
  -->
<xsl:variable name="DICT_ACCENTS">
  &Breve;&Cedilla;&DiacriticalGrave;&DiacriticalDot;&DiacriticalDoubleAcute;&LeftArrow;&LeftRightArrow;&LeftRightVector;&LeftVector;&DiacriticalAcute;&RightArrow;&RightVector;&DiacriticalTilde;&DoubleDot;&DownBreve;&Hacek;&Hat;&OverBar;&OverBrace;&OverBracket;&OverParenthesis;&TripleDot;&UnderBar;&UnderBrace;&UnderBracket;&UnderParenthesis;
</xsl:variable>

<!-- Letters and numbers -->
<xsl:variable name="LETTERSNUMBERS">abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789</xsl:variable>

<!-- Characters which get made italic in TeX, including normal letters plus lower Greek -->
<xsl:variable name="TEXITALIC">abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ&#x03b1;&#x03b2;&#x03c7;&#x03b4;&#x03dd;&#x03f5;&#x03b7;&#x03b3;&#x03b9;&#x03ba;&#x03bb;&#x03bc;&#x03bd;&#x03c9;&#x03d5;&#x03c0;&#x03c8;&#x03c1;&#x03c3;&#x03c4;&#x03b8;&#x03c5;&#x03b5;&#x03f0;&#x03c6;&#x03d6;&#x03f1;&#x03c2;&#x03d1;&#x03be;&#x03b6;</xsl:variable>

<!--
  Root template
  -->
<xsl:template match="/m:math">
  <result>
    <xsl:apply-templates/>
  </result>
</xsl:template>

<!--
  For escapes, output escaped content
  -->
<xsl:template match="w:esc">
  <xsl:value-of select="@tex"/>
</xsl:template>
<xsl:template match="w:esc[not(@mathmode)]">
  <xsl:text>\textrm{</xsl:text>
  <xsl:call-template name="mark-text-mode-start"/>
  <xsl:value-of select="@tex"/>
  <xsl:call-template name="mark-text-mode-end"/>
  <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="w:esc[not(@textmode)]" mode="textmode">
  <xsl:call-template name="mark-text-mode-end"/>
  <xsl:text>$</xsl:text>
  <xsl:value-of select="@tex"/>
  <xsl:text>$</xsl:text>
  <xsl:call-template name="mark-text-mode-start"/>
</xsl:template>
<xsl:template match="w:esc[@textmode]" mode="textmode">
  <xsl:value-of select="@tex"/>
</xsl:template>

<!--
  We mark text mode with special sequences used by the Java code later.
  -->
<xsl:template name="mark-text-mode-start">
  <xsl:text>&#x2022;TEXT-START&#x2022;</xsl:text>
</xsl:template>
<xsl:template name="mark-text-mode-end">
  <xsl:text>&#x2022;TEXT-END&#x2022;</xsl:text>
</xsl:template>

<!--
  Basic elements passed through
  -->
<xsl:template match="m:semantics|m:mn|m:mrow">
  <xsl:apply-templates select="@*|node()"/>
</xsl:template>

<!-- mtext should turn into \textrm -->
<xsl:template match="m:mtext">
  <xsl:apply-templates select="@*"/>
  <xsl:call-template name="mathvariant-to-tex-font">
    <xsl:with-param name="PREFIX">\text</xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="collect-preceding-spaces">
  <!--
    By precedence, it glues spaces to the END of a text not the start, so
    check there isn't one before.
    -->
  <xsl:variable name="TEXTBEFORE">
    <!-- Only check first time -->
    <xsl:if test="self::m:mtext">
      <xsl:for-each select="preceding-sibling::*[not(self::m:mspace and @width='mediummathspace')][1][self::m:mtext]">
        <xsl:call-template name="is-this-a-normal-mtext"/>
      </xsl:for-each>
    </xsl:if>
  </xsl:variable>

  <xsl:if test="$TEXTBEFORE = ''">
    <xsl:for-each select="preceding-sibling::*[1]">
      <xsl:if test="self::m:mspace[@width='mediummathspace']">
        <xsl:call-template name="collect-preceding-spaces"/>
        <xsl:text> </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:if>
</xsl:template>

<xsl:template name="collect-following-spaces">
  <xsl:for-each select="following-sibling::*[1]">
    <xsl:if test="self::m:mspace[@width='mediummathspace']">
      <xsl:call-template name="collect-following-spaces"/>
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:for-each>
</xsl:template>

<!-- Styled text -->
<xsl:template match="m:mtext[@mathvariant]">
  <xsl:apply-templates select="@*[local-name() != 'mathvariant' and local-name() != 'fontstyle']"/>
  <xsl:call-template name="mathvariant-to-tex-font">
    <xsl:with-param name="PREFIX">\text</xsl:with-param>
    <xsl:with-param name="FAILCOMMAND">\text</xsl:with-param>
  </xsl:call-template>
</xsl:template>

<!--
  mtext special cases (PUNCT_AND_SPACE in LatexToMathml.java)
  NOTE: There is basically a copy of this list up above, take care to edit
  both.
  -->

<xsl:template match="m:mtext[string(.) = '&emsp;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\quad </xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '&emsp;&emsp;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\qquad </xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '&ensp;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\thickspace </xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '&emsp14;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\medspace </xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '&ThinSpace;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\thinspace </xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '&ZeroWidthSpace;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\! </xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '&nbsp;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>~</xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '.' or string(.) = ';' or string(.) = '?']">
  <xsl:apply-templates select="@*"/>
  <xsl:value-of select="."/>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '&#x220e;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\blacksquare </xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '&#x2b1c;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\qedsymbol </xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '#']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\#</xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '&#x00a3;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\pounds </xsl:text>
</xsl:template>
<xsl:template match="m:mtext[string(.) = '$']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\$ </xsl:text>
</xsl:template>

<!-- mi -->
<xsl:template match="m:mi">
  <xsl:apply-templates select="@*[local-name() != 'mathvariant' and local-name() != 'fontstyle']"/>
  <xsl:variable name="FN">
    <xsl:choose>
      <xsl:when test="contains(string(.), '&ThinSpace;') and substring-after(string(.), '&ThinSpace;') = ''">
        <xsl:value-of select="substring-before(string(.), '&ThinSpace;')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="string(.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <!-- Use mathop if it is main part of munder/mover (when not used for accents) -->
    <xsl:when test="not(preceding-sibling::*) and
        (parent::m:munder or parent::m:mover or parent::m:munderover) and
        not (parent::*/@accent = 'true') and
        @mathvariant='italic'">
      <xsl:text>\mathop{</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>}</xsl:text>
    </xsl:when>
    <!-- Single letters with bold italic -->
    <xsl:when test="string-length($FN) = 1 and contains($TEXITALIC, $FN) and
        @mathvariant = 'bold-italic'">
      <xsl:text>\boldsymbol{</xsl:text>
      <xsl:apply-templates select="@*[local-name() != 'mathvariant']|node()"/>
      <xsl:text>}</xsl:text>
    </xsl:when>
    <!-- Single letters with bold -->
    <xsl:when test="string-length($FN) = 1 and not(contains($TEXITALIC, $FN)) and
        @mathvariant = 'bold'">
      <xsl:text>\boldsymbol{</xsl:text>
      <xsl:apply-templates select="@*[local-name() != 'mathvariant']|node()"/>
      <xsl:text>}</xsl:text>
    </xsl:when>
    <!-- Single letters with no style or italic -->
    <xsl:when test="string-length($FN) = 1 and contains($TEXITALIC, $FN) and
        (not(@mathvariant) or (@mathvariant = 'italic'))">
      <xsl:apply-templates select="@*[local-name() != 'mathvariant']|node()"/>
    </xsl:when>
    <!-- Single not-ASCII (or lower Greek)-letters with normal style -->
    <xsl:when test="string-length($FN) = 1 and not(contains($TEXITALIC, $FN)) and
        @mathvariant = 'normal'">
      <xsl:apply-templates select="@*[local-name() != 'mathvariant']|node()"/>
    </xsl:when>
    <!-- \dotsm is treated same as above even though it is multiple characters (sigh) -->
    <xsl:when test="count(node()) = 1 and w:esc/@tex = '\dotsm '">
      <xsl:apply-templates select="@*[local-name() != 'mathvariant']|node()"/>
    </xsl:when>
    <!-- Use styling for non-normal style -->
    <xsl:when test="@mathvariant and @mathvariant != 'normal'">
      <xsl:call-template name="mathvariant-to-tex-font">
        <xsl:with-param name="PREFIX">\math</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <!-- Supported functions -->
    <xsl:when test="$FN = 'arccos'"><xsl:text>\arccos </xsl:text></xsl:when>
    <xsl:when test="$FN = 'arcsin'"><xsl:text>\arcsin </xsl:text></xsl:when>
    <xsl:when test="$FN = 'arctan'"><xsl:text>\arctan </xsl:text></xsl:when>
    <xsl:when test="$FN = 'arg'"><xsl:text>\arg </xsl:text></xsl:when>
    <xsl:when test="$FN = 'cos'"><xsl:text>\cos </xsl:text></xsl:when>
    <xsl:when test="$FN = 'cosh'"><xsl:text>\cosh </xsl:text></xsl:when>
    <xsl:when test="$FN = 'cot'"><xsl:text>\cot </xsl:text></xsl:when>
    <xsl:when test="$FN = 'coth'"><xsl:text>\coth </xsl:text></xsl:when>
    <xsl:when test="$FN = 'csc'"><xsl:text>\csc </xsl:text></xsl:when>
    <xsl:when test="$FN = 'deg'"><xsl:text>\deg </xsl:text></xsl:when>
    <xsl:when test="$FN = 'det'"><xsl:text>\det </xsl:text></xsl:when>
    <xsl:when test="$FN = 'dim'"><xsl:text>\dim </xsl:text></xsl:when>
    <xsl:when test="$FN = 'exp'"><xsl:text>\exp </xsl:text></xsl:when>
    <xsl:when test="$FN = 'gcd'"><xsl:text>\gcd </xsl:text></xsl:when>
    <xsl:when test="$FN = 'hom'"><xsl:text>\hom </xsl:text></xsl:when>
    <xsl:when test="$FN = 'ker'"><xsl:text>\ker </xsl:text></xsl:when>
    <xsl:when test="$FN = 'lg'"><xsl:text>\lg </xsl:text></xsl:when>
    <xsl:when test="$FN = 'ln'"><xsl:text>\ln </xsl:text></xsl:when>
    <xsl:when test="$FN = 'log'"><xsl:text>\log </xsl:text></xsl:when>
    <xsl:when test="$FN = 'Pr'"><xsl:text>\Pr </xsl:text></xsl:when>
    <xsl:when test="$FN = 'sec'"><xsl:text>\sec </xsl:text></xsl:when>
    <xsl:when test="$FN = 'sin'"><xsl:text>\sin </xsl:text></xsl:when>
    <xsl:when test="$FN = 'sinh'"><xsl:text>\sinh </xsl:text></xsl:when>
    <xsl:when test="$FN = 'tan'"><xsl:text>\tan </xsl:text></xsl:when>
    <xsl:when test="$FN = 'tanh'"><xsl:text>\tanh </xsl:text></xsl:when>
    <xsl:when test="$FN = 'inf'"><xsl:text>\inf </xsl:text></xsl:when>
    <xsl:when test="$FN = 'inj lim'"><xsl:text>\injlim </xsl:text></xsl:when>
    <xsl:when test="$FN = 'lim'"><xsl:text>\lim </xsl:text></xsl:when>
    <xsl:when test="$FN = 'lim inf'"><xsl:text>\liminf </xsl:text></xsl:when>
    <xsl:when test="$FN = 'lim sup'"><xsl:text>\limsup </xsl:text></xsl:when>
    <xsl:when test="$FN = 'max'"><xsl:text>\max </xsl:text></xsl:when>
    <xsl:when test="$FN = 'min'"><xsl:text>\min </xsl:text></xsl:when>
    <xsl:when test="$FN = 'proj lim'"><xsl:text>\projlim </xsl:text></xsl:when>
    <xsl:when test="$FN = 'sup'"><xsl:text>\sup </xsl:text></xsl:when>
    <!-- Otherwise do styling for mathrm -->
    <xsl:otherwise>
      <xsl:call-template name="mathvariant-to-tex-font">
        <xsl:with-param name="PREFIX">\math</xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>


<xsl:template match="m:mn[@mathvariant]">
  <xsl:apply-templates select="@*[local-name() != 'mathvariant' and local-name() != 'fontstyle']"/>
  <xsl:call-template name="mathvariant-to-tex-font">
    <xsl:with-param name="PREFIX">\math</xsl:with-param>
  </xsl:call-template>
</xsl:template>

<!-- Font style using mstyle -->
<xsl:template match="m:mstyle[@mathvariant]">
  <xsl:apply-templates select="@*[local-name() != 'mathvariant' and local-name() != 'fontstyle']"/>
  <xsl:call-template name="mathvariant-to-tex-font">
    <xsl:with-param name="PREFIX">\math</xsl:with-param>
  </xsl:call-template>
</xsl:template>

<!--
  Using @mathvariant, outputs TeX font code.
  PREFIX - First part of TeX command e.g. \text, \math
  FAILCOMMAND - Optional; if specified uses this command e.g. \text for
    unrecognised fonts
  -->
<xsl:template name="mathvariant-to-tex-font">
  <xsl:param name="PREFIX"/>
  <xsl:param name="FAILCOMMAND"/>
  <xsl:variable name="FONT">
    <xsl:choose>
      <xsl:when test="@mathvariant='double-struck'">
        <xsl:text>bb</xsl:text>
      </xsl:when>
      <xsl:when test="@mathvariant='italic'">
        <xsl:text>it</xsl:text>
      </xsl:when>
      <xsl:when test="@mathvariant='bold'">
        <xsl:text>bf</xsl:text>
      </xsl:when>
      <xsl:when test="@mathvariant='monospace'">
        <xsl:text>tt</xsl:text>
      </xsl:when>
      <xsl:when test="@mathvariant='fraktur'">
        <xsl:text>frak</xsl:text>
      </xsl:when>
      <xsl:when test="@mathvariant='script'">
        <xsl:text>scr</xsl:text>
      </xsl:when>
      <xsl:when test="@mathvariant='normal' or not(@mathvariant)">
        <xsl:text>rm</xsl:text>
      </xsl:when>
      <xsl:when test="@mathvariant='sans-serif'">
        <xsl:text>sf</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="$FONT = ''">
      <xsl:text>\UNSUPPORTED{Unsupported mathvariant: {</xsl:text>
      <xsl:value-of select="@mathvariant"/>
      <xsl:text>}</xsl:text>
      <xsl:choose>
        <xsl:when test="$FAILCOMMAND=''">
          <xsl:apply-templates/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$FAILCOMMAND"/>
          <xsl:text>{</xsl:text>
          <xsl:apply-templates/>
          <xsl:text>}</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$PREFIX"/>
      <xsl:value-of select="$FONT"/>
      <xsl:text>{</xsl:text>
      <xsl:choose>
        <xsl:when test="$PREFIX = '\text'">
          <xsl:call-template name="mark-text-mode-start"/>
          <xsl:call-template name="collect-preceding-spaces"/>
          <xsl:apply-templates mode="textmode"/>
          <xsl:call-template name="collect-following-spaces"/>
          <xsl:call-template name="mark-text-mode-end"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>}</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- mo for \sum, \int might need to change into \tsum, \dint, etc. -->
<xsl:template match="m:mo[(string(.) = '&Sum;' or string(.)='&int;') and
    (parent::m:munder or parent::m:mover or parent::m:munderover or
    parent::m:msub or parent::m:msup or parent::m:msubsup) and
    not(preceding-sibling::*) and parent::*/parent::m:mstyle]" priority="+1">
  <xsl:apply-templates select="@*"/>
  <xsl:variable name="TDFRAC">
    <xsl:for-each select="parent::*/parent::m:mstyle">
      <xsl:call-template name="is-tdfrac"/>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="THING" select="substring-after(string(w:esc/@tex), '\')"/>
  <xsl:choose>
    <xsl:when test="../parent::m:mstyle[@displaystyle='true'] and $TDFRAC = 'y'">
      <xsl:text>\d</xsl:text><xsl:value-of select="$THING"/>
    </xsl:when>
    <xsl:when test="../parent::m:mstyle[@displaystyle='false'] and $TDFRAC = 'y'">
      <xsl:text>\t</xsl:text><xsl:value-of select="$THING"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="node()"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Direct passthrough for mo that is a single letter non-alpha, or TeX escape -->
<xsl:template match="m:mo[(w:esc and count(node()) = 1) or string-length(normalize-space(.)) = 1]">
  <xsl:apply-templates select="@*"/>
  <xsl:apply-templates/>
</xsl:template>

<!-- Special-case for prime symbol - only use \prime when in super/subscript -->
<xsl:template match="m:mo[w:esc[@tex='\prime '] and not(
    (parent::m:msup or parent::m:msubsup or parent::m:msub) and preceding-sibling::*)]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>'</xsl:text>
</xsl:template>

<!-- mo that has font style -->
<xsl:template match="m:mo[@mathvariant]">
  <xsl:apply-templates select="@*[local-name() != 'mathvariant' and local-name() != 'fontstyle']"/>
  <xsl:call-template name="mathvariant-to-tex-font">
    <xsl:with-param name="PREFIX">\math</xsl:with-param>
  </xsl:call-template>
</xsl:template>

<!-- Skip <mo> that contains no content (generated due to buggy TeX) -->
<xsl:template match="m:mo[string-length(normalize-space(.)) = 0]">
  <!-- Note: We don't care if it has attributes. -->

  <!-- Let's do a space just in case -->
  <xsl:text> </xsl:text>
</xsl:template>

<!-- Things which can be handled as stretchy brackets with \left and \right -->
<xsl:variable name="BRACKETS">([{&LeftAngleBracket;&LeftCeiling;&LeftFloor;\|+/&Vert;&RightFloor;&RightCeiling;&RightAngleBracket;}])</xsl:variable>

<!-- Handle <mo>, possibly with specified minsize / maxsize, as generated by \big etc -->
<xsl:template match="m:mo[(string-length(normalize-space(.)) = 1 and
    contains($BRACKETS, normalize-space(.))) or normalize-space(.) = '']" priority="+1">
  <!-- Note: We actually ignore maxsize altogether -->
  <xsl:apply-templates select="@*[local-name(.) != 'minsize' and local-name(.) != 'maxsize']"/>

  <!-- Get size as TeX name -->
  <xsl:variable name="SIZE">
    <xsl:choose>
      <xsl:when test="@minsize = '2'"><xsl:text>\big</xsl:text></xsl:when>
      <xsl:when test="@minsize = '3'"><xsl:text>\Big</xsl:text></xsl:when>
      <xsl:when test="@minsize = '4'"><xsl:text>\bigg</xsl:text></xsl:when>
      <xsl:when test="@minsize &gt;= '5'"><xsl:text>\Bigg</xsl:text></xsl:when>
    </xsl:choose>
  </xsl:variable>

  <!-- Is this left or right? -->
  <xsl:variable name="LR">
    <xsl:choose>
      <xsl:when test="not(parent::m:mrow)"/>
      <!--
        In TeX, \left and \right MUST pair or it might not render. We detect
        these as being at the start/end of an mrow (this should be correct
        because of normalise.xsl).
        -->
      <xsl:when test="not(preceding-sibling::*) and parent::m:mrow/child::m:mo[
          preceding-sibling::* and not(following-sibling::*) and @minsize and
          ((w:esc and count(node()) = 1) or string-length(normalize-space(.)) &lt;= 1)]">
        <xsl:choose>
          <xsl:when test="string-length($SIZE) != 0"><xsl:text>l</xsl:text></xsl:when>
          <xsl:otherwise><xsl:text>\left</xsl:text></xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="not(following-sibling::*) and parent::m:mrow/child::m:mo[
          following-sibling::* and not(preceding-sibling::*) and @minsize and
          ((w:esc and count(node()) = 1) or string-length(normalize-space(.)) &lt;= 1)]">
        <xsl:choose>
          <xsl:when test="string-length($SIZE) != 0"><xsl:text>r</xsl:text></xsl:when>
          <xsl:otherwise><xsl:text>\right</xsl:text></xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:value-of select="$SIZE"/>
  <xsl:value-of select="$LR"/>
  <!-- TeX uses \left. when there is a blank/hidden left or right marker -->
  <xsl:if test="$LR and normalize-space(.) = ''">
    <xsl:text>.</xsl:text>
  </xsl:if>
  <xsl:apply-templates/>

  <!-- Put a space after it, but only if we added one of the extras -->
  <xsl:if test="string-length(concat($SIZE, $LR)) != 0">
    <xsl:text> </xsl:text>
  </xsl:if>
</xsl:template>


<!-- Special-case for mod -->
<xsl:template match="m:mo[normalize-space(.) = 'mod']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\mod </xsl:text>
</xsl:template>

<!-- mo with combining 'not' operator -->
<xsl:template match="m:mo[string-length(.) = 2 and substring(., 2) = '&#x0338;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\not</xsl:text>
  <xsl:choose>
    <!-- Just in case the first character needs escaping  -->
    <xsl:when test="w:esc"><xsl:apply-templates select="w:esc"/></xsl:when>
    <!-- Maybe it had a letter/number? Then we need a space -->
    <xsl:when test="contains($LETTERSNUMBERS, substring(., 1, 1))">
      <xsl:text> </xsl:text>
      <xsl:value-of select="substring(., 1, 1)"/>
    </xsl:when>
    <!-- Otherwise just output it -->
    <xsl:otherwise><xsl:value-of select="substring(., 1, 1)"/></xsl:otherwise>
  </xsl:choose>
  <!-- Space after for niceness -->
  <xsl:text> </xsl:text>
</xsl:template>

<!-- Other mo uses operatorname -->
<xsl:template match="m:mo">
  <xsl:apply-templates select="@*"/>

  <xsl:text>\operatorname{</xsl:text>
  <xsl:apply-templates/>
  <xsl:text>}</xsl:text>
</xsl:template>


<!--
  fontstyle = normal on mi can be ignored (eh maybe)
  -->
<xsl:template match="m:mi/@fontstyle[string(.)='normal']"/>

<!-- Detect constructs we do not support, and mark result equation. -->
<xsl:template match="*" priority="-100">
  <xsl:text>\UNSUPPORTED{element </xsl:text>
  <xsl:value-of select="local-name(.)"/>
  <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="@*" priority="-100">
  <xsl:text>\UNSUPPORTED{attribute </xsl:text>
  <xsl:value-of select="local-name(..)"/>
  <xsl:text>/@</xsl:text>
  <xsl:value-of select="local-name(.)"/>
  <xsl:text>}</xsl:text>
</xsl:template>

<!-- Skip elements -->
<xsl:template match="m:annotation"/>
<xsl:template match="m:annotation-xml"/>

<!-- mtable as matrix -->
<xsl:template match="m:mrow[count(*) = 3 and *[2][self::m:mtable and not(@columnalign)] and
    *[1][self::m:mo and not(@minsize)] and *[3][self::m:mo and not(@minsize)] and
    ((string(*[1]) = '(' and string(*[3]) = ')') or
    (string(*[1]) = '[' and string(*[3]) = ']') or
    (string(*[1]) = '{' and string(*[3]) = '}') or
    (string(*[1]) = '|' and string(*[3]) = '|') or
    (string(*[1]) = '&Verbar;' and string(*[3]) = '&Verbar;')
    )]">
  <xsl:apply-templates select="@*"/>
  <xsl:apply-templates select="m:mo/@*[local-name() != 'stretchy']"/>
  <xsl:variable name="TYPE">
    <xsl:choose>
      <xsl:when test="string(*[1]) = '('">
        <xsl:text>pmatrix</xsl:text>
      </xsl:when>
      <xsl:when test="string(*[1]) = '['">
        <xsl:text>bmatrix</xsl:text>
      </xsl:when>
      <xsl:when test="string(*[1]) = '{'">
        <xsl:text>Bmatrix</xsl:text>
      </xsl:when>
      <xsl:when test="string(*[1]) = '|'">
        <xsl:text>vmatrix</xsl:text>
      </xsl:when>
      <xsl:when test="string(*[1]) = '&Verbar;'">
        <xsl:text>Vmatrix</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>
  <xsl:text>\begin{</xsl:text>
  <xsl:value-of select="$TYPE"/>
  <xsl:text>} </xsl:text>
  <xsl:for-each select="m:mtable">
    <xsl:call-template name="matrix"/>
  </xsl:for-each>
  <xsl:text>\end{</xsl:text>
  <xsl:value-of select="$TYPE"/>
  <xsl:text>} </xsl:text>
</xsl:template>

<!-- mtable as cases -->
<xsl:template match="m:mrow[count(*) = 2 and *[2][self::m:mtable and @columnalign = 'left left'] and
    *[1][self::m:mo] and string(*[1]) = '{']">
  <xsl:apply-templates select="@*"/>
  <xsl:apply-templates select="m:mo/@*"/>
  <xsl:text>\begin{cases} </xsl:text>
  <xsl:for-each select="m:mtable">
    <xsl:apply-templates select="@*[local-name() != 'columnalign']"/>
    <xsl:call-template name="matrix">
      <xsl:with-param name="DONEATTRIBUTES">y</xsl:with-param>
    </xsl:call-template>
  </xsl:for-each>
  <xsl:text>\end{cases} </xsl:text>
</xsl:template>

<!-- mtable as \begin{align*} -->
<xsl:template match="m:mtable[m:mtr and @rowspacing='2ex']">
  <xsl:apply-templates select="@*[local-name() != 'rowspacing' and local-name() != 'columnalign']"/>
  <xsl:text>\begin{align*} </xsl:text>

  <xsl:call-template name="matrix">
    <xsl:with-param name="DONEATTRIBUTES">y</xsl:with-param>
  </xsl:call-template>

  <xsl:text>\end{align*} </xsl:text>
</xsl:template>

<!-- Default mtable treated as \begin{array} -->
<xsl:template match="m:mtable[m:mtr]" priority="-1">
  <xsl:apply-templates select="@*[local-name() != 'columnalign']"/>
  <xsl:text>\begin{array}{</xsl:text>
  <xsl:choose>
    <xsl:when test="@columnalign != ''">
      <xsl:call-template name="column-align">
        <xsl:with-param name="ALIGN" select="@columnalign"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <!-- By default we had better left-align everything -->
      <xsl:for-each select="m:mtr[1]/m:mtd">
        <xsl:text>l</xsl:text>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>} </xsl:text>

  <xsl:call-template name="matrix">
    <xsl:with-param name="DONEATTRIBUTES">y</xsl:with-param>
  </xsl:call-template>

  <xsl:text>\end{array} </xsl:text>
</xsl:template>

<!--
  $ALIGN - @columnalign value like 'left center right'
  Returns - LaTeX value like 'lcr'
 -->
<xsl:template name="column-align">
  <xsl:param name="ALIGN"/>

  <xsl:variable name="START">
    <xsl:choose>
      <xsl:when test="contains($ALIGN, ' ')">
        <xsl:value-of select="substring-before($ALIGN, ' ')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$ALIGN"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$START = 'left'"><xsl:text>l</xsl:text></xsl:when>
    <xsl:when test="$START = 'center'"><xsl:text>c</xsl:text></xsl:when>
    <xsl:when test="$START = 'right'"><xsl:text>r</xsl:text></xsl:when>
  </xsl:choose>

  <xsl:if test="contains($ALIGN, ' ')">
    <xsl:call-template name="column-align">
      <xsl:with-param name="ALIGN" select="substring-after($ALIGN, ' ')"/>
    </xsl:call-template>
  </xsl:if>

</xsl:template>

<!--
  Converts an mtable (must be context node) into a matrix format like
  a & b \\ c & d
  -->
<xsl:template name="matrix">
  <xsl:param name="DONEATTRIBUTES"/>
  <xsl:if test="$DONEATTRIBUTES != 'y'">
    <xsl:apply-templates select="@*"/>
  </xsl:if>
  <xsl:for-each select="m:mtr">
    <xsl:apply-templates select="@*"/>
    <xsl:if test="preceding-sibling::*">
      <xsl:text> \\ </xsl:text>
    </xsl:if>
    <xsl:for-each select="m:mtd">
      <xsl:apply-templates select="@*"/>
      <xsl:if test="preceding-sibling::*">
        <xsl:text> &amp; </xsl:text>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:for-each>
  </xsl:for-each>
</xsl:template>

<!-- mtable as \substack (single-column table within limits) -->
<xsl:template match="m:mtable[count(m:mtr[count(m:mtd) != 1]) = 0 and
    (parent::m:munder or parent::m:mover or parent::m:munderover or
    parent::m:msub or parent::m:msup or parent::m:msubsup) and
    preceding-sibling::* and count(m:mtr) &gt; 1 and not(@columnalign)]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\substack{</xsl:text>
  <xsl:for-each select="m:mtr">
    <xsl:apply-templates select="@*"/>
    <xsl:apply-templates select="m:mtd/@*"/>
    <xsl:if test="preceding-sibling::m:mtr">
      <xsl:text> \\ </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="m:mtd/*"/>
  </xsl:for-each>
  <xsl:text>}</xsl:text>
</xsl:template>

<!-- mrow as \bmod -->
<xsl:template match="m:mrow[count(*) = 2 and
    *[1][self::m:mo[string(.) = 'mod']]]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\bmod{</xsl:text>
  <xsl:apply-templates select="*[2]"/>
  <xsl:text>}</xsl:text>
</xsl:template>

<!-- mrow as \mod -->
<xsl:template match="m:mrow[count(*) = 3 and *[1][self::m:mspace and @width='1em'] and
    *[2][self::m:mo[string(.) = 'mod']]]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\mod{</xsl:text>
  <xsl:apply-templates select="*[3]"/>
  <xsl:text>}</xsl:text>
</xsl:template>

<!-- mrow as \pmod -->
<xsl:template match="m:mrow[count(*) = 5 and *[1][self::m:mspace and @width='1em'] and
    *[2][self::m:mo and string(.) = '('] and
    *[5][self::m:mo and string(.) = ')'] and *[3][self::m:mo[string(.) = 'mod']]]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\pmod{</xsl:text>
  <xsl:apply-templates select="*[4]"/>
  <xsl:text>}</xsl:text>
</xsl:template>

<!-- mrow as \pod -->
<xsl:template match="m:mrow[count(*) = 4 and *[1][self::m:mspace and @width='1em'] and
    *[2][self::m:mo and string(.) = '('] and *[4][self::m:mo and string(.) = ')']]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\pod{</xsl:text>
  <xsl:apply-templates select="*[3]"/>
  <xsl:text>}</xsl:text>
</xsl:template>


<!-- mrow as \binom -->
<xsl:template match="m:mrow[count(*) = 3 and *[1][self::m:mo and string(.) = '('] and
    *[3][self::m:mo and string(.) = ')'] and *[2][self::m:mfrac[@linethickness='0' and
    count(@*)=1]]]">
  <xsl:apply-templates select="@*"/>
  <xsl:for-each select="m:mo">
      <xsl:apply-templates select="@*"/>
  </xsl:for-each>

  <xsl:variable name="TDFRAC">
    <xsl:for-each select="parent::m:mstyle">
      <xsl:call-template name="is-tdfrac"/>
    </xsl:for-each>
  </xsl:variable>

  <xsl:for-each select="m:mfrac">
    <xsl:choose>
      <xsl:when test="../parent::m:mstyle[@displaystyle='true'] and $TDFRAC = 'y'">
        <xsl:text>\dbinom{</xsl:text>
      </xsl:when>
      <xsl:when test="../parent::m:mstyle[@displaystyle='false'] and $TDFRAC = 'y'">
        <xsl:text>\tbinom{</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\binom{</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*[1]"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="*[2]"/>
    <xsl:text>} </xsl:text>
  </xsl:for-each>
</xsl:template>

<!-- mrow as \choose -->
<xsl:template match="m:mrow[count(*) = 3 and *[1][self::m:mo and string(.) = '{'] and
    *[3][self::m:mo and string(.) = '}'] and *[2][self::m:mfrac[@linethickness='0' and
    count(@*)=1]]]">
  <xsl:apply-templates select="@*"/>
  <xsl:for-each select="m:mo">
      <xsl:apply-templates select="@*"/>
  </xsl:for-each>

  <xsl:for-each select="m:mfrac">
    <xsl:apply-templates select="@*[local-name() != 'linethickness']"/>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="*[1]"/>
    <xsl:text> \choose </xsl:text>
    <xsl:apply-templates select="*[2]"/>
    <xsl:text>} </xsl:text>
  </xsl:for-each>
</xsl:template>

<!-- mfrac -->
<xsl:template match="m:mfrac">
  <xsl:apply-templates select="@*"/>
  <xsl:variable name="TDFRAC">
    <xsl:for-each select="parent::m:mstyle">
      <xsl:call-template name="is-tdfrac"/>
    </xsl:for-each>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="parent::m:mstyle[@displaystyle='true'] and $TDFRAC = 'y'">
      <xsl:text>\dfrac{</xsl:text>
    </xsl:when>
    <xsl:when test="parent::m:mstyle[@displaystyle='false'] and $TDFRAC = 'y'">
      <xsl:text>\tfrac{</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>\frac{</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:apply-templates select="*[1]"/>
  <xsl:text>}{</xsl:text>
  <xsl:apply-templates select="*[2]"/>
  <xsl:text>} </xsl:text>
</xsl:template>

<!-- msub, under -->
<xsl:template match="m:msub|m:munder">
  <xsl:apply-templates select="@*"/>
  <xsl:choose>
    <xsl:when test="*[1][self::m:mrow and count(node()) = 0]">
        <xsl:text>\strut</xsl:text>
    </xsl:when>
    <!-- For certain things, we don't want to put braces around them. This
         basically corresponds to \underbrace and the rest of the list from
         below. -->
    <xsl:when test="self::m:munder and *[1][self::m:munder and *[2][self::m:mo
        and contains('&#xfe38;&#x0332;', string(.))]]">
      <xsl:apply-templates select="*[1]"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="brace"><xsl:with-param name="VAL">
        <xsl:apply-templates select="*[1]"/>
      </xsl:with-param></xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>_</xsl:text>
  <xsl:call-template name="brace"><xsl:with-param name="VAL">
    <xsl:apply-templates select="*[2]"/>
  </xsl:with-param></xsl:call-template>
  <xsl:text> </xsl:text>
</xsl:template>

<!-- msup, mover -->
<xsl:template match="m:msup|m:mover">
  <xsl:apply-templates select="@*"/>
  <xsl:choose>
    <xsl:when test="*[1][self::m:mrow and count(node()) = 0]">
        <xsl:text>\strut</xsl:text>
    </xsl:when>
    <!-- For certain things, we don't want to put braces around them. This
         basically corresponds to \underbrace and the rest of the list from
         below. -->
    <xsl:when test="self::m:mover and *[1][self::m:mover and *[2][self::m:mo
        and contains('&#xfe37;&#x00af;~&Hat;', string(.))]]">
      <xsl:apply-templates select="*[1]"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="brace"><xsl:with-param name="VAL">
        <xsl:apply-templates select="*[1]"/>
      </xsl:with-param></xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>^</xsl:text>
  <xsl:call-template name="brace"><xsl:with-param name="VAL">
    <xsl:apply-templates select="*[2]"/>
  </xsl:with-param></xsl:call-template>
  <xsl:text> </xsl:text>
</xsl:template>

<!-- msubsup, munderover -->
<xsl:template match="m:msubsup|m:munderover">
  <xsl:apply-templates select="@*"/>
  <xsl:choose>
    <xsl:when test="*[1][self::m:mrow and count(node()) = 0]">
        <xsl:text>\strut</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="brace"><xsl:with-param name="VAL">
        <xsl:apply-templates select="*[1]"/>
      </xsl:with-param></xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>_</xsl:text>
  <xsl:call-template name="brace"><xsl:with-param name="VAL">
    <xsl:apply-templates select="*[2]"/>
  </xsl:with-param></xsl:call-template>
  <xsl:text>^</xsl:text>
  <xsl:call-template name="brace"><xsl:with-param name="VAL">
    <xsl:apply-templates select="*[3]"/>
  </xsl:with-param></xsl:call-template>
  <xsl:text> </xsl:text>
</xsl:template>

<!-- Accents -->
<xsl:template match="m:mover[@accent='true' and count(*) = 2 and *[2][self::m:mo]]">
  <xsl:apply-templates select="@*[local-name() != 'accent']"/>
  <xsl:choose>
    <xsl:when test="string(*[2]) = '&DiacriticalAcute;'"><xsl:text>\acute{</xsl:text></xsl:when>
    <xsl:when test="string(*[2]) = '&DiacriticalGrave;'"><xsl:text>\grave{</xsl:text></xsl:when>
    <xsl:when test="*[2][@stretchy='false'] and string(*[2]) = '~'"><xsl:text>\tilde{</xsl:text></xsl:when>
    <xsl:when test="string(*[2]) = '&OverBar;'"><xsl:text>\bar{</xsl:text></xsl:when>
    <xsl:when test="string(*[2]) = '&Breve;'"><xsl:text>\breve{</xsl:text></xsl:when>
    <xsl:when test="string(*[2]) = '&Hacek;'"><xsl:text>\check{</xsl:text></xsl:when>
    <xsl:when test="string(*[2]) = '&Hat;'"><xsl:text>\hat{</xsl:text></xsl:when>
    <xsl:when test="string(*[2]) = '&RightArrow;'"><xsl:text>\vec{</xsl:text></xsl:when>
    <xsl:when test="string(*[2]) = '&DiacriticalDot;'"><xsl:text>\dot{</xsl:text></xsl:when>
    <xsl:when test="string(*[2]) = '&DoubleDot;'"><xsl:text>\ddot{</xsl:text></xsl:when>
    <xsl:when test="string(*[2]) = '&TripleDot;'"><xsl:text>\dddot{</xsl:text></xsl:when>
    <xsl:otherwise>
      <xsl:text>\UNSUPPORTED{Unknown accent: </xsl:text>
      <xsl:value-of select="string(*[2])"/>
      <xsl:text>}</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:apply-templates select="*[1]"/>
  <xsl:text>}</xsl:text>
</xsl:template>

<!-- Under/over thingies other than accents -->
<xsl:template match="m:munder[*[2][self::m:mo and string(.) = '&#xfe38;']]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\underbrace{</xsl:text>
  <xsl:apply-templates select="*[1]"/>
  <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="m:mover[*[2][self::m:mo and string(.) = '&#xfe37;']]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\overbrace{</xsl:text>
  <xsl:apply-templates select="*[1]"/>
  <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="m:munder[*[2][self::m:mo and string(.) = '&#x0332;']]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\underline{</xsl:text>
  <xsl:apply-templates select="*[1]"/>
  <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="m:mover[not(@accent) and *[2][self::m:mo and string(.) = '&#x00af;']]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\overline{</xsl:text>
  <xsl:apply-templates select="*[1]"/>
  <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="m:mover[*[2][self::m:mo and string(.) = '&#x27f6;']]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\overrightarrow{</xsl:text>
  <xsl:apply-templates select="*[1]"/>
  <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="m:mover[not(@accent) and *[2][self::m:mo and string(.) = '~']]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\widetilde{</xsl:text>
  <xsl:apply-templates select="*[1]"/>
  <xsl:text>}</xsl:text>
</xsl:template>
<xsl:template match="m:mover[not(@accent) and *[2][self::m:mo and string(.) = '&Hat;']]">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\widehat{</xsl:text>
  <xsl:apply-templates select="*[1]"/>
  <xsl:text>}</xsl:text>
</xsl:template>


<!-- mmultiscripts -->
<xsl:template match="m:mmultiscripts">
  <xsl:apply-templates select="@*"/>

  <!-- Loop round all pairs of prescripts (if any) -->
  <xsl:for-each select="*[not(self::m:mprescripts) and
      count(preceding-sibling::*) mod 2 = 0 and
      count(preceding-sibling::m:mprescripts) = 1]">
    <xsl:text>{}</xsl:text>
    <xsl:if test="not(self::m:none)">
      <xsl:text>_</xsl:text>
      <xsl:call-template name="brace"><xsl:with-param name="VAL">
        <xsl:apply-templates select="self::*"/>
      </xsl:with-param></xsl:call-template>
    </xsl:if>
    <xsl:if test="not(following-sibling::*[1][self::m:none])">
      <xsl:text>^</xsl:text>
      <xsl:call-template name="brace"><xsl:with-param name="VAL">
        <xsl:apply-templates select="following-sibling::*[1]"/>
      </xsl:with-param></xsl:call-template>
    </xsl:if>
  </xsl:for-each>

  <!-- Do base -->
  <xsl:call-template name="brace"><xsl:with-param name="VAL">
    <xsl:apply-templates select="*[1]"/>
  </xsl:with-param></xsl:call-template>

  <!-- Loop around all pairs of postscripts -->
  <xsl:for-each select="*[not(self::m:mprescripts) and
      count(preceding-sibling::*) mod 2 = 1 and
      count(preceding-sibling::m:mprescripts) = 0]">
    <xsl:if test="count(preceding-sibling::*) &gt; 1">
      <xsl:text>{}</xsl:text>
    </xsl:if>
    <xsl:if test="not(self::m:none)">
      <xsl:text>_</xsl:text>
      <xsl:call-template name="brace"><xsl:with-param name="VAL">
        <xsl:apply-templates select="self::*"/>
      </xsl:with-param></xsl:call-template>
    </xsl:if>
    <xsl:if test="not(following-sibling::*[1][self::m:none])">
      <xsl:text>^</xsl:text>
      <xsl:call-template name="brace"><xsl:with-param name="VAL">
        <xsl:apply-templates select="following-sibling::*[1]"/>
      </xsl:with-param></xsl:call-template>
    </xsl:if>
  </xsl:for-each>
</xsl:template>



<!-- msqrt -->
<xsl:template match="m:msqrt">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\sqrt{</xsl:text>
  <xsl:apply-templates select="*"/>
  <xsl:text>}</xsl:text>
</xsl:template>

<!-- mroot -->
<xsl:template match="m:mroot">
  <xsl:apply-templates select="@*"/>
  <xsl:text>\sqrt[</xsl:text>
  <xsl:apply-templates select="*[2]"/>
  <xsl:text>]{</xsl:text>
  <xsl:apply-templates select="*[1]"/>
  <xsl:text>}</xsl:text>
</xsl:template>

<!--
  Put spaces around some weird operators just to make it look nicer and match
  some of the input tests.
  -->
<xsl:template match="m:mtext[string(.) = '.' or string(.) = ';' or
    string(.) = '?' or string(.) = '&nbsp;']">
  <xsl:apply-templates select="@*"/>
  <xsl:text> </xsl:text>
  <xsl:apply-templates/>
  <xsl:text> </xsl:text>
</xsl:template>

<!-- For mspace, turn it into a space... -->
<xsl:template match="m:mspace">
  <xsl:apply-templates select="@*"/>
  <xsl:text> </xsl:text>
</xsl:template>
<!-- Or a real (escaped) space if it has some width -->
<xsl:template match="m:mspace[@width='mediummathspace']">
  <xsl:apply-templates select="@*[local-name() != 'width']"/>
  <!-- Special handling: if this immediately adjoins an mtext, we will output
       it as part of the mtext -->
  <xsl:variable name="GOTTEXT">
    <xsl:for-each select="
      preceding-sibling::*[not(self::m:mspace[@width='mediummathspace'])][1][self::m:mtext]
      |
      following-sibling::*[not(self::m:mspace[@width='mediummathspace'])][1][self::m:mtext]
      ">
      <xsl:call-template name="is-this-a-normal-mtext"/>
    </xsl:for-each>
  </xsl:variable>
  <xsl:if test="$GOTTEXT = ''">
    <xsl:text>\ </xsl:text>
  </xsl:if>
</xsl:template>
<!-- Or negative space (no special glom-onto-mtext handling for these) -->
<xsl:template match="m:mspace[@width='negativethinmathspace']">
  <xsl:apply-templates select="@*[local-name() != 'width']"/>
  <xsl:text>\!</xsl:text>
</xsl:template>

<xsl:template name="is-this-a-normal-mtext">
  <xsl:if test="not(string(.) = '.' or string(.) = ';' or string(.) = '?' or
      string(.) = '&nbsp;' or string(.) = '&emsp;' or string(.) = '&emsp;&emsp;' or
      string(.) = '&ensp;' or string(.) = '&emsp14;' or string(.) = '&ThinSpace;' or
      string(.) = '&ZeroWidthSpace;' or string(.) = '&#x220e;' or
      string(.) = '#' or string(.) =  '&#x00a3;')">
    <xsl:text>y</xsl:text>
  </xsl:if>
</xsl:template>

<!-- mstyle -->

<!-- Supported attributes -->
<xsl:template match="m:mstyle/@displaystyle"/>
<xsl:template match="m:mstyle/@scriptlevel"/>

<!-- Displaystyle true; exclude auto-added wrapper -->
<xsl:template match="m:mstyle">
  <xsl:apply-templates select="@*"/>

  <xsl:variable name="DISPLAYSTYLE">
    <xsl:call-template name="get-displaystyle"/>
  </xsl:variable>
  <xsl:variable name="PARENTDISPLAYSTYLE">
    <xsl:for-each select="parent::*">
      <xsl:call-template name="get-displaystyle"/>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="SCRIPTLEVEL">
    <xsl:call-template name="get-scriptlevel"/>
  </xsl:variable>
  <xsl:variable name="PARENTSCRIPTLEVEL">
    <xsl:for-each select="parent::*">
      <xsl:call-template name="get-scriptlevel"/>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="NOCHANGE">
    <xsl:if test="$SCRIPTLEVEL = $PARENTSCRIPTLEVEL and
        $DISPLAYSTYLE = $PARENTDISPLAYSTYLE">y</xsl:if>
  </xsl:variable>

  <xsl:variable name="SKIP">
    <xsl:call-template name="is-tdfrac"/>
  </xsl:variable>

  <!-- Change display style -->
  <xsl:choose>
    <!-- Skip if using dfrac/tfrac for this, or same as parent -->
    <xsl:when test="$SKIP = 'y' or $NOCHANGE = 'y'"/>
    <xsl:when test="$DISPLAYSTYLE = 'true'">
      <xsl:text>{ \displaystyle </xsl:text>
    </xsl:when>
    <xsl:when test="$DISPLAYSTYLE = 'false' and $SCRIPTLEVEL = '0'">
      <xsl:text>{ \textstyle </xsl:text>
    </xsl:when>
    <xsl:when test="$DISPLAYSTYLE = 'false' and $SCRIPTLEVEL = '1'">
      <xsl:text>{ \scriptstyle </xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>{ \scriptscriptstyle </xsl:text>
    </xsl:otherwise>
  </xsl:choose>

  <xsl:apply-templates/>

  <!-- Put it back to parent style -->
  <xsl:choose>
    <xsl:when test="$SKIP = 'y' or $NOCHANGE = 'y'"/>
    <xsl:otherwise>
      <xsl:text>} </xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
  Must be called on mstyle node. Returns true if we are going to use tfrac/dfrac
  to replace a parent mstyle.
 -->
<xsl:template name="is-tdfrac">
  <xsl:if test="count(child::*)=1 and (m:mfrac or
      m:mrow[
          count(*) = 3 and *[1][self::m:mo and string(.) = '('] and
          *[3][self::m:mo and string(.) = ')'] and *[2][self::m:mfrac[@linethickness='0' and
          count(@*)=1]]
        ]) and
      @displaystyle and not(@scriptlevel)">
    <!-- Need to check if the displaystyle actually did anything! -->
    <xsl:variable name="PREVIOUSDISPLAYSTYLE">
      <xsl:for-each select="parent::*">
        <xsl:call-template name="get-displaystyle"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:if test="$PREVIOUSDISPLAYSTYLE != @displaystyle">
      <xsl:text>y</xsl:text>
    </xsl:if>
  </xsl:if>
</xsl:template>



<!-- MathML utilities -->

<!--
 Gets details for an embellished operator. Embellished operator logic is
 defined in http://www.w3.org/TR/MathML2/chapter3.html#id.3.2.5.7
 If context node is not an embellished operator, returns empty string.
 TYPE - type value

 Type values:
 'accent': get value of accent setting or from dictionary (true/false)
 -->
<xsl:template name="get-embellished-operator-info">
  <xsl:param name="TYPE"/>
  <xsl:choose>

    <xsl:when test="self::m:mo">
      <xsl:call-template name="get-embellished-operator-info-inner">
        <xsl:with-param name="TYPE" select="$TYPE"/>
      </xsl:call-template>
    </xsl:when>

    <xsl:when test="self::m:msub or self::m:msup or self::m:msubsup or
        self::m:munder or self::m:mover or self::m:munderover or
        self::m:mmultiscripts or self::m:mfrac or self::m:semantics">
      <xsl:for-each select="child::*">
        <xsl:call-template name="get-embellished-operator-info">
          <xsl:with-param name="TYPE" select="$TYPE"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:when>

    <xsl:when test="self::m:mrow or self::m:mstyle or self::m:mphantom or
        self::m:mpadded">
      <!-- Get a count of non-spacelike things -->
      <xsl:variable name="NOTSPACELIKELIST">
        <xsl:for-each select="*">
          <xsl:variable name="SPACELIKE">
            <xsl:call-template name="is-space-like"/>
          </xsl:variable>
          <xsl:if test="$SPACELIKE = 'n'">
            <xsl:text>x</xsl:text>
          </xsl:if>
        </xsl:for-each>
      </xsl:variable>
      <!-- It must be 1 -->
      <xsl:if test="string-length($NOTSPACELIKELIST) = 1">
        <xsl:for-each select="*">
          <xsl:variable name="SPACELIKE">
            <xsl:call-template name="is-space-like"/>
          </xsl:variable>
          <xsl:if test="$SPACELIKE = 'n'">
            <xsl:call-template name="get-embellished-operator-info">
              <xsl:with-param name="TYPE" select="$TYPE"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:for-each>
      </xsl:if>
    </xsl:when>

    <xsl:when test="self::m:maction">
      <xsl:variable name="SELECTION">
        <xsl:choose>
          <xsl:when test="@selection">
            <xsl:value-of select="@selection"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>1</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:for-each select="child::*[$SELECTION]">
        <xsl:call-template name="get-embellished-operator-info">
          <xsl:with-param name="TYPE" select="$TYPE"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:when>

  </xsl:choose>
</xsl:template>

<!--
  Inner template used by get-embellished-operator-info.
  -->
<xsl:template name="get-embellished-operator-info-inner">
  <xsl:param name="TYPE"/>

  <xsl:choose>
    <xsl:when test="type='accent'">
      <xsl:choose>
        <xsl:when test="@accent">
          <xsl:value-of select="@accent"/>
        </xsl:when>
        <xsl:when test="contains($DICT_ACCENTS, normalize-space(.))">
          <xsl:text>true</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>false</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
  </xsl:choose>

</xsl:template>

<!--
  Returns 'y' if the current node is a space-like element or 'n' if it is not.
  From http://www.w3.org/TR/MathML2/chapter3.html#id.3.2.7.3
  -->
<xsl:template name="is-space-like">
  <xsl:choose>
    <xsl:when test="self::m:mtext or self::m:mspace or self::m:maligngroup or
        self::m:malignmark">
      <xsl:text>y</xsl:text>
    </xsl:when>
    <xsl:when test="self::m:mstyle or self::m:mphanton or self::m:mpadded or
        self::m:mrow">
      <xsl:variable name="CHILDREN">
        <xsl:for-each select="*">
          <xsl:call-template name="is-space-like"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="contains($CHILDREN, 'n')">
          <xsl:text>n</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>y</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="self::m:maction">
      <xsl:variable name="SELECTION">
        <xsl:choose>
          <xsl:when test="@selection">
            <xsl:value-of select="@selection"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>1</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:for-each select="child::*[$SELECTION]">
        <xsl:call-template name="is-space-like"/>
      </xsl:for-each>
      <!--
        I think usually there should be a selected element, but just in
        case, if there is none, let's call it space-like?
        -->
      <xsl:if test="not(child::*[$SELECTION])">
        <xsl:text>y</xsl:text>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>n</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
  Gets the current in-effect value of displaystyle attribute.
  -->
<xsl:template name="get-displaystyle">
  <xsl:choose>
    <!-- Explicitly specified -->
    <xsl:when test="self::m:mstyle/@displaystyle or self::m:mtable/@displaystyle">
      <xsl:value-of select="@displaystyle"/>
    </xsl:when>
    <!-- Tags defined to set value to false within second+ child -->
    <xsl:when test="(parent::m:msub or parent::m:msup or parent::m:subsup or
        parent::m:munder or parent::m:mover or parent::m:munderover or
        parent::m:mmultiscripts or parent::m:mroot) and preceding-sibling::*">
      <xsl:text>false</xsl:text>
    </xsl:when>
    <!-- Tags defined to set value to false within all children -->
    <xsl:when test="parent::m:mfrac">
      <xsl:text>false</xsl:text>
    </xsl:when>
    <!-- Root element (we default to true for this rendering) -->
    <xsl:when test="not(parent::*)">
      <xsl:text>true</xsl:text>
    </xsl:when>
    <!-- Default: as parent -->
    <xsl:otherwise>
      <xsl:for-each select="parent::*">
        <xsl:call-template name="get-displaystyle"></xsl:call-template>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
  Gets current in-effect value of scriptlevel attribute.
  -->
<xsl:template name="get-scriptlevel">
  <!-- Get parent value -->
  <xsl:variable name="PARENTVAL">
    <xsl:for-each select="parent::*">
      <xsl:call-template name="get-scriptlevel"></xsl:call-template>
    </xsl:for-each>
    <xsl:if test="not(parent::*)">
      <xsl:text>0</xsl:text>
    </xsl:if>
  </xsl:variable>

  <!-- Check specified option -->
  <xsl:choose>
    <!-- Increment -->
    <xsl:when test="self::m:mstyle and starts-with(string(@scriptlevel), '+')">
      <xsl:variable name="SHIFT" select="substring-after(@scriptlevel, '+')"/>
      <xsl:value-of select="number($PARENTVAL) + number($SHIFT)"/>
    </xsl:when>

    <!-- Decrement -->
    <xsl:when test="self::m:mstyle and starts-with(@scriptlevel, '-')">
      <xsl:variable name="SHIFT" select="substring-after(@scriptlevel, '-')"/>
      <xsl:value-of select="number($PARENTVAL) - number($SHIFT)"/>
    </xsl:when>

    <!-- Fixed value -->
    <xsl:when test="self::m:mstyle and @scriptlevel">
      <xsl:value-of select="@scriptlevel"/>
    </xsl:when>

    <!-- Tags defined to increment within second+ child -->
    <xsl:when test="(parent::m:msub or parent::m:msup or parent::m:subsup or
        parent::m:mmultiscripts) and preceding-sibling::*">
      <xsl:value-of select="number($PARENTVAL) + 1"/>
    </xsl:when>

    <!-- underscript on munder or munderover -->
    <xsl:when test="(parent::m:munder and preceding-sibling::*) or
        (parent::m:munderover and preceding-sibling::* and following-sibling::*)">
      <xsl:variable name="ACCENTUNDER">
        <xsl:choose>
          <xsl:when test="parent::*[@accentunder]">
            <xsl:value-of select="parent::*/@accentunder"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="ACCENT">
              <xsl:call-template name="get-embellished-operator-info">#
                <xsl:with-param name="TYPE">accent</xsl:with-param>
              </xsl:call-template>
            </xsl:variable>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="$ACCENTUNDER='true'">
          <xsl:value-of select="$PARENTVAL"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="number($PARENTVAL) + 1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>

    <!-- overscript on mover or munderover -->
    <xsl:when test="(parent::m:mover and preceding-sibling::*) or
        (parent::m:munderover and preceding-sibling::* and not(following-sibling::*))">
      <xsl:variable name="ACCENTOVER">
        <xsl:choose>
          <xsl:when test="parent::*[@accent]">
            <xsl:value-of select="parent::*/@accent"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="ACCENT">
              <xsl:call-template name="get-embellished-operator-info">
                <xsl:with-param name="TYPE">accent</xsl:with-param>
              </xsl:call-template>
            </xsl:variable>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="$ACCENTOVER='true'">
          <xsl:value-of select="$PARENTVAL"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="number($PARENTVAL) + 1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>

    <!--
      Fractions are complicated; increment scriptlevel if displaystyle was
      already false
      -->
    <xsl:when test="parent::m:mfrac">
      <xsl:variable name="DISPLAYSTYLE">
        <xsl:for-each select="parent::*">
          <xsl:call-template name="get-displaystyle"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="$DISPLAYSTYLE='true'">
          <xsl:value-of select="$PARENTVAL"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="number($PARENTVAL) + 1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>

    <!-- mroot index -->
    <xsl:when test="parent::m:mroot and preceding-sibling::*">
      <xsl:value-of select="number($PARENTVAL) + 2"/>
    </xsl:when>

    <!-- Anything else, inherit -->
    <xsl:otherwise>
      <xsl:value-of select="$PARENTVAL"/>
    </xsl:otherwise>

  </xsl:choose>
</xsl:template>

<!--
  Characters which are permitted after a backslash \
  -->
<xsl:variable name="SLASHCHARS">ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz</xsl:variable>
<!--
  Include something without braces if it's a single character, otherwise
  use braces.
  -->
<xsl:template name="brace">
  <xsl:param name="VAL"/>
  <xsl:param name="NS" select="normalize-space($VAL)"/>
  <xsl:choose>
    <!-- Single characters don't need braces -->
    <xsl:when test="string-length(string($NS)) = 1">
      <xsl:value-of select="$NS"/>
    </xsl:when>
    <!-- Backslash followed by any single char -->
    <xsl:when test="starts-with($NS, '\') and string-length(normalize-space($NS)) = 2">
      <xsl:value-of select="$NS"/>
    </xsl:when>
    <!-- Backslash followed by letters -->
    <xsl:when test="starts-with($NS, '\') and
      string-length(translate(substring($NS, 2), $SLASHCHARS, '')) = 0">
      <xsl:value-of select="$NS"/>
    </xsl:when>
    <!-- \mathop special case because it breaks if you put {} around it -->
    <xsl:when test="starts-with($NS, '\mathop{') and
        '}' = substring($NS, string-length($NS))">
      <xsl:value-of select="$NS"/>
    </xsl:when>
    <!-- Any other string - use braces -->
    <xsl:otherwise>
      <xsl:text>{</xsl:text>
      <xsl:value-of select="$NS"/>
      <xsl:text>}</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


</xsl:stylesheet>
