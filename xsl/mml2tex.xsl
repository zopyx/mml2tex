<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
  xmlns:xs="http://www.w3.org/2001/XMLSchema"  
  xmlns:tr="http://transpect.io"
  xmlns:mml="http://www.w3.org/1998/Math/MathML" 
  xmlns:mml2tex="http://transpect.io/mml2tex"
  xmlns:xml2tex="http://transpect.io/xml2tex"
  xmlns:functx="http://www.functx.com"
  exclude-result-prefixes="tr mml xs mml2tex" 
  xpath-default-namespace="http://www.w3.org/1998/Math/MathML" 
  version="2.0">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:variable name="texmap" select="document('../texmap/texmap.xml')/xml2tex:set/xml2tex:charmap" as="element(xml2tex:charmap)"/>
  
  <xsl:variable name="texregex" select="concat('[', string-join(for $i in $texmap//xml2tex:char/@character return functx:escape-for-regex($i), ''), ']')" as="xs:string"/>

  <xsl:template match="*" mode="mathml2tex" priority="-10">
    <xsl:message terminate="yes" select="'ERROR: unknown element', name()"/>    
  </xsl:template>

  <xsl:template match="@*" mode="mathml2tex">
    <xsl:message terminate="yes" select="'ERROR: unknown attribute', name()"/>
  </xsl:template>

  <xsl:template match="math" mode="mathml2tex">
    <xsl:variable name="basic-transformation">
      <xsl:apply-templates mode="#current"/>
    </xsl:variable>
    <xsl:value-of select="$basic-transformation"/>
  </xsl:template>

  <xsl:template match="semantics" mode="mathml2tex">
    <xsl:apply-templates select="@*, node()" mode="#current"/>
  </xsl:template>

  <!-- drop attributes and elements -->
  <xsl:template match="@overflow[parent::math]|@movablelimits[parent::mo]|@athcolor|@color|@fontsize|@mathsize|@mathbackground|@background|@maxsize|@minsize|@scriptminsize|@fence|@stretchy|@separator|@accent|@accentunder|@form|@largeop|@lspace|@rspace|@columnalign[parent::mtable]|@align[parent::mtable]|@accent|@accentunder|@form|@largeop|@lspace|@rspace|@linebreak|@symmetric[parent::mo]|@columnspacing|@rowspacing|@columnalign|@groupalign|@columnwidth|@rowalign|@displaystyle|@scriptlevel[parent::mstyle]|@linethickness[parent::mstyle]|@columnlines|@rowlines|@equalcolumns|@equalrows|@frame|@framespacing|@rowspan|@class|@side" mode="mathml2tex">
    <xsl:message select="'WARNING: attribute', name(), 'in context', ../name(), 'ignored!'"></xsl:message>
  </xsl:template>
  
  <xsl:template match="maligngroup|mphantom" mode="mathml2tex">
    <xsl:message select="'WARNING: element', name(), 'ignored!'"/>
  </xsl:template>
  
  <!-- https://github.com/transpect/mml2tex/issues/3 -->
  
  <xsl:template match="malignmark" mode="mathml2tex">
    <!-- consider that the stylesheet which imports mm2ltex.xsl must 
         wrap the equation with an align environment -->
    <xsl:if test="matches(preceding-sibling::*[1], '^\s+$') or matches(following-sibling::*[1], '^\s+$')">
      <xsl:text>&amp;</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!-- only process text content -->
  <xsl:template match="mtext|mlabeledtr|maction|mrow|merror|mpadded" mode="mathml2tex">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="mspace" mode="mathml2tex">
    <xsl:choose>
      <xsl:when test="@width">
        <hspace space="{@width}">
          <xsl:apply-templates select="@* except (@width, @height, @depth)" mode="#current"/>
          <xsl:apply-templates mode="#current"/>
        </hspace>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="@* except (@width, @height, @depth)" mode="#current"/>
        <xsl:apply-templates mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="menclose" mode="mathml2tex">
    <xsl:message select="'WARNING:', name(), 'treated as box!'"/>
    <box>
      <xsl:attribute name="style" select="if (@notation = 'box') then 'single' else 'none'"/>
      <xsl:apply-templates select="@* except @notation, node()" mode="#current"/>
    </box>
  </xsl:template>

  <xsl:template match="mfrac" mode="mathml2tex">
    <xsl:text>\frac</xsl:text>
    <xsl:apply-templates select="@*[not(local-name() = ('linethickness', 'bevelled'))]" mode="#current"/>
    <xsl:choose>
      <xsl:when test="count(*) eq 2">
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="*[1]" mode="#current"/>
        <xsl:text>}{</xsl:text>
        <xsl:apply-templates select="*[2]" mode="#current"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="no" select="name(), 'must include two elements'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="mmultiscripts" mode="mathml2tex">
    <xsl:for-each-group select="node()" group-starting-with="*[local-name() = 'mprescripts']">
      <xsl:choose>
        <xsl:when test="current-group()[1][local-name() = 'mprescripts']">
          <xsl:if test="not((floor(count(current-group()) - 1) div 2) = ((count(current-group()) - 1) div 2))">
            <xsl:message terminate="no" select="'after ', name(), 'must follow 2n + 1 elements'"/>
          </xsl:if>
          <xsl:for-each-group select="current-group()[position() &gt; 1]" group-adjacent="floor(count(preceding-sibling::*[. &gt;&gt; current-group()[1]]) div 2)">
            <xsl:if test="not(current-group()[1][self::none])">
              <inf arrange="compact" location="pre">
                <xsl:apply-templates select="current-group()[1]" mode="#current"/>
              </inf>
            </xsl:if>
            <xsl:if test="not(current-group()[2][self::none])">
              <sup arrange="compact" location="pre">
                <xsl:apply-templates select="current-group()[2]" mode="#current"/>
              </sup>
            </xsl:if>
          </xsl:for-each-group>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="not((floor(count(current-group()) - 1) div 2) = ((count(current-group()) - 1) div 2))">
            <xsl:message terminate="no" select="name(), 'must include 2n +1 elements.'"/>
          </xsl:if>
          <xsl:apply-templates select="current-group()[1]" mode="#current"/>
          <xsl:for-each-group select="current-group()[position() &gt; 1]" group-adjacent="floor(count(preceding-sibling::*[. &gt;&gt; current-group()[1]]) div 2)">
            <xsl:if test="not(current-group()[1][self::none])">
              <inf arrange="compact" location="post">
                <xsl:apply-templates select="current-group()[1]" mode="#current"/>
              </inf>
            </xsl:if>
            <xsl:if test="not(current-group()[2][self::none])">
              <sup arrange="compact" location="post">
                <xsl:apply-templates select="current-group()[2]" mode="#current"/>
              </sup>
            </xsl:if>
          </xsl:for-each-group>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template match="msqrt" mode="mathml2tex">
    <xsl:text>\sqrt{</xsl:text>
    <xsl:apply-templates mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="mroot" mode="mathml2tex">
    <xsl:if test="count(*) ne 2">
      <xsl:message terminate="no" select="name(), 'must include two elements'"/>
    </xsl:if>
    <xsl:text>\sqrt[</xsl:text>
    <xsl:apply-templates select="*[2]" mode="#current"/>
    <xsl:text>]{</xsl:text>
    <xsl:apply-templates select="*[1]" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="msup|msub" mode="mathml2tex">
    <xsl:if test="count(*) ne 2">
      <xsl:message terminate="no" select="name(), 'must include two elements'"/>
    </xsl:if>
    <xsl:apply-templates select="*[1]" mode="#current"/>
    <xsl:value-of select="if (local-name(.) eq 'msup') then '^' else '_'"/>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="*[2]" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="msubsup" mode="mathml2tex">
    <xsl:if test="count(*) ne 3">
      <xsl:message terminate="no" select="name(), 'must include three elements'"/>
    </xsl:if>
    <xsl:apply-templates select="*[1]" mode="#current"/>
    <xsl:text>_{</xsl:text>
    <xsl:apply-templates select="*[2]" mode="#current"/>
    <xsl:text>}^{</xsl:text>
    <xsl:apply-templates select="*[3]" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="mtable" mode="mathml2tex">
    <xsl:text>\begin{array}{</xsl:text>
    <xsl:for-each select="1 to max(for $x in mtr return count($x/mtd))">
      <xsl:text>c</xsl:text>
    </xsl:for-each>
    <xsl:text>}
</xsl:text>
    <xsl:apply-templates select="@* except @width" mode="#current"/>
    <xsl:apply-templates mode="#current"/>
    <xsl:text>\end{array}</xsl:text>
  </xsl:template>

  <xsl:template match="mtr" mode="mathml2tex">
    <xsl:apply-templates select="@*, node()" mode="#current"/>
    <xsl:if test="following-sibling::mtr">
      <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="mtd" mode="mathml2tex">
    <xsl:apply-templates select="@*, node()" mode="#current"/>
    <xsl:if test="following-sibling::mtd">
      <xsl:text> &amp; </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:variable name="diacritics-regex" select="'^[&#x300;-&#x338;&#x20d0;-&#x20ef;]$'" as="xs:string"/>

  <xsl:template match="mover|munder" mode="mathml2tex">
    <xsl:if test="count(*) ne 2">
      <xsl:message terminate="no" select="name(), 'must include two elements'"/>
    </xsl:if>
    <!-- diacritical mark overline should be substituted with latex overline -->
    <xsl:variable name="expression" select="*[1]" as="element(*)"/>
    <xsl:variable name="accent" select="*[2]" as="element(*)"/>
    <xsl:variable name="is-diacritical-mark" select="matches($accent, $diacritics-regex)" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="$is-diacritical-mark">
        <xsl:apply-templates select="$accent" mode="#current"/>
      </xsl:when>
      <xsl:when test="self::mover or self::munder">
        <xsl:value-of select="if(self::mover ) then '\overset' else '\underset'"/>
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="$accent" mode="#current"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="$expression" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="munderover" mode="mathml2tex">
    <xsl:if test="count(*) ne 3">
      <xsl:message terminate="no" select="name(), 'must include three elements'"/>
    </xsl:if>
    <xsl:apply-templates select="*[1]" mode="#current"/>
    <xsl:text> \limits_{</xsl:text>
    <xsl:apply-templates select="*[2]" mode="#current"/>
    <xsl:text>}^{</xsl:text>
    <xsl:apply-templates select="*[3]" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="mfenced[count(mrow/mtable) = 1]
                              [count(*) = 1]
                              [@open = '{']
                              [@close = '']"
                mode="mathml2tex">
    <xsl:apply-templates select="mrow/*[following-sibling::mtable]" mode="#current"/>
    <xsl:text>\begin{cases}
    </xsl:text>
    <xsl:apply-templates select="mrow/mtable/mtr" mode="#current"/>
    <xsl:text>\end{cases}
    </xsl:text>
    <xsl:apply-templates select="mrow/*[preceding-sibling::mtable]" mode="#current"/>
  </xsl:template>
  
  <!-- https://github.com/transpect/mml2tex/issues/1, requires amsmath -->
  
  <xsl:template match="mfenced[count(*) eq 1][count(mrow) eq 1][mrow/mfrac[@linethickness = ('0', '0pt')]][count(mrow/mfrac/mrow) eq 2]" mode="mathml2tex">
    <xsl:text>\binom{</xsl:text>
    <xsl:apply-templates select="mrow/mfrac/mrow[1]" mode="#current"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="mrow/mfrac/mrow[2]" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>
  

  <xsl:template match="mfenced" mode="mathml2tex">
    <xsl:call-template name="fence">
      <xsl:with-param name="pos" select="'left'"/>
      <xsl:with-param name="val" select="(@open, '(')[1]"/>
    </xsl:call-template>
    <xsl:variable name="my-seps" select="replace(@separators, '\s+', '')"/>
    <xsl:variable name="seps" select="if (normalize-space(@separators)) then
                                      for $x in (1 to string-length($my-seps)) return substring($my-seps, $x, 1)
                                      else ','" as="xs:string*"/>
    <xsl:variable name="els" select="*"/>
    <xsl:for-each select="1 to count($els)">
      <xsl:if test="current() &gt; 1">
        <xsl:value-of select="if (empty($seps[current() - 1])) then $seps[last()] else $seps[current() - 1]"/>
      </xsl:if>
      <xsl:apply-templates select="$els[current()]" mode="#current"/>
    </xsl:for-each>
    <xsl:call-template name="fence">
      <xsl:with-param name="pos" select="'right'"/>
      <xsl:with-param name="val" select="(@close, ')')[1]"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="fence">
    <xsl:param name="pos" as="xs:string"><!-- left|right --></xsl:param>
    <xsl:param name="val" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="not(normalize-space($val))">
        <!-- case: open="" or close="" -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\</xsl:text>
        <xsl:value-of select="$pos"/>
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="$val = ('[', ']', '(', ')')">
            <xsl:value-of select="$val"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="string-join(mml2tex:utf2tex($val, ()), '')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*[local-name() = ('mstyle')]" mode="mathml2tex">
    <xsl:apply-templates select="@*[not(local-name() = ('mathvariant', 'fontweight', 'fontstyle', 'fontfamily', 'mathcolor'))]" mode="#current"/>
    <xsl:choose>
      <xsl:when test="@*[local-name() = ('mathvariant')] = 'bold'">
        <xsl:text>\mathbf{</xsl:text>
        <xsl:apply-templates mode="#current"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="text()" mode="mathml2tex">
    <!-- normalize space and remove line breaks -->
    <xsl:variable name="text" select="replace(normalize-space(.), '&#xa;', ' ')" as="xs:string"/>
    <!-- choose corresponding font suffix for \math -->
    <xsl:variable name="fonts" select="tr:text-atts(..)" as="xs:string?"/>
    <xsl:variable name="utf2tex" select="if(. = ' ') then '\ ' 
                                         else if(matches($text, $texregex)) then string-join(mml2tex:utf2tex($text, ()), '')
                                         else $text" as="xs:string"/>
    <xsl:choose>
      <!-- operator names such as cos, sin, log -->
      <xsl:when test="parent::mi[@mathvariant = 'normal'][$text = $mml2tex:operator-names]
                      |parent::mtext[not(@mathvariant) or @mathvariant = 'normal'][$text = $mml2tex:operator-names]">
        <xsl:value-of select="concat('\', $text, '&#x20;')"/>
      </xsl:when>
      <xsl:when test="parent::mtext[not(@mathvariant) or @mathvariant = 'normal']">
        <xsl:value-of select="concat('\text{', $utf2tex, '}')"/>
      </xsl:when>
      <!-- convert to mathrm, mathit and map unicode to latex -->
      <xsl:when test="parent::mn|parent::mi|parent::mo|parent::ms|parent::mtext">
        
        <xsl:value-of select="if($fonts) then concat('\math', $fonts, '{', $utf2tex, '}') else $utf2tex"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="no" select="'unexpected text node', parent::*/name()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="tr:text-atts" as="xs:string?">
    <xsl:param name="elt" as="element(*)"/><!-- e.g., mtext -->
    <xsl:choose>
      <xsl:when test="$elt/@fontweight = 'bold'">
        <xsl:choose>
          <xsl:when test="$elt/@fontstyle = 'italic'">
            <xsl:value-of select="'bi'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'bf'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$elt/@fontstyle = 'italic'">
            <xsl:value-of select="'it'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$elt/self::mtext or $elt/@mathvariant = 'normal'">
              <xsl:value-of select="'rm'"/>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="mglyph" mode="mathml2tex">
    <xsl:message>Warnung: mglyph (<xsl:copy-of select="."/>)</xsl:message>
    <xsl:if test="@alt">
      <xsl:value-of select="@alt"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="mn|mi|ms|mo" mode="mathml2tex">
    <xsl:variable name="mml-mathvariant-to-tex" as="element(mml2tex:styles)">
      <styles xmlns="http://transpect.io/mml2tex">
        <var mml="bold" tex="mathbf"/>
        <var mml="italic" tex="mathit"/>
        <var mml="bold-italic" tex="boldsymbol"/>
        <var mml="fraktur" tex="mathfrak"/>
        <var mml="bold-fraktur" tex="mathfrak"/>
        <var mml="script" tex="mathfrak"/>
        <var mml="bold-script" tex="mathfrak"/>
        <var mml="sans-serif" tex="mathsf"/>
        <var mml="bold-sans-serif" tex="mathfrak"/>
        <var mml="sans-serif-italic" tex="mathfrak"/>
        <var mml="sans-serif-bold-italic" tex="mathfrak"/>
        <var mml="monospace" tex="mathtt"/>
      </styles>
    </xsl:variable>
    <xsl:variable name="mathvariant" select="@mathvariant" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="some $i in $mml-mathvariant-to-tex/mml2tex:var satisfies $mathvariant eq $i/@mml">
        <xsl:value-of select="concat('\', $mml-mathvariant-to-tex/mml2tex:var[@mml eq $mathvariant]/@tex, '{')"/>
        <xsl:apply-templates select="node()" mode="#current"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="node()" mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="processing-instruction()[local-name() eq 'latex']" mode="mathml2tex">
    <xsl:value-of select="."/>
  </xsl:template>
  
  <!-- check operators -->
  <xsl:variable name="mml2tex:operator-names" as="xs:string+" 
    select="('arccos',
             'arcsin',
             'arctan',
             'arg',
             'cos',
             'cosh',
             'cot',
             'coth',
             'csc',
             'deg',
             'det',
             'dim',
             'exp',
             'gcd',
             'hom',
             'inf',
             'ker', 
             'lg',
             'lim', 
             'liminf', 
             'limsup', 
             'ln', 
             'log', 
             'max', 
             'min', 
             'Pr', 
             'sec', 
             'sin',
             'sinh', 
             'sup', 
             'tan', 
             'tanh')"/>
    
  <xsl:function name="mml2tex:utf2tex" as="xs:string+">
    <xsl:param name="string" as="xs:string"/>
    <!-- In order to avoid infinite recursion when mapping % → \% -->
    <xsl:param name="seen" as="xs:string*"/>
    
    <xsl:analyze-string select="$string" regex="{$texregex}">  
      <xsl:matching-substring>
        <xsl:variable name="insert-whitespace" select="if(not(matches(., string-join(($diacritics-regex, '[0-9]+', '[!\|\{\}#]'), '|'))))
          then '&#x20;' else ''" as="xs:string?"/>
        <xsl:variable name="pattern" select="functx:escape-for-regex(.)" as="xs:string"/>
        <xsl:variable name="replacement" select="replace($texmap/xml2tex:char[@character = $pattern][1]/@string, '(\$|\\)', '\\$1')" as="xs:string"/>
        <xsl:variable name="result" select="replace(., 
                                                    $pattern,
                                                    concat($replacement, $insert-whitespace)
                                                    )" as="xs:string"/>
        <xsl:choose>
          <xsl:when test="matches($result, $texregex)
                          and not(($pattern = $seen) or matches($result, '^[a-z0-9A-Z\$\\%_&amp;\{{\}}\[\]#\|\s]+$'))">
            
            <xsl:value-of select="string-join(mml2tex:utf2tex($result, ($seen, $pattern)), '')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$result"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>
  
  <xsl:function name="functx:escape-for-regex" as="xs:string">
    <xsl:param name="arg" as="xs:string?"/> 
    <xsl:sequence select="replace($arg,
                                  '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')"/>
  </xsl:function>

</xsl:stylesheet>