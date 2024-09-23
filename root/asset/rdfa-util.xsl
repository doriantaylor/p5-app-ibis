<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:rdfa="http://www.w3.org/ns/rdfa#"
                xmlns:xc="https://makethingsmakesense.com/asset/transclude#"
		xmlns:x="urn:x-dummy:"
                xmlns:str="http://xsltsl.org/string"
                xmlns:uri="http://xsltsl.org/uri"
		xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="html str uri rdfa xc x">

<xsl:import href="rdfa"/>
<xsl:import href="transclude"/>

<x:doc>
  <h1>RDFa Utilities</h1>
  <p>This stylesheet handles the type-agnostic templates for XHTML+RDFa.</p>
</x:doc>

<xsl:output
    method="xml" media-type="application/xhtml+xml"
    indent="yes" omit-xml-declaration="no"
    encoding="utf-8" doctype-public=""/>

<x:doc>
  <h2>Utilities</h2>
</x:doc>

<xsl:template name="str:safe-first-token">
  <xsl:param name="tokens">
    <xsl:message terminate="yes">`tokens` parameter required</xsl:message>
  </xsl:param>

  <xsl:variable name="_" select="normalize-space($tokens)"/>

  <xsl:choose>
    <xsl:when test="contains($_, ' ')">
      <xsl:value-of select="substring-before($_, ' ')"/>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$_"/></xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template name="str:token-union">
  <xsl:param name="left"/>
  <xsl:param name="right"/>

  <xsl:variable name="lpad" select="concat(' ', normalize-space($left), ' ')"/>
  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$right"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="out">
    <xsl:choose>
      <xsl:when test="string-length($first) and contains($lpad, concat(' ', $first, ' '))">
        <xsl:value-of select="$left"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($left, ' ', $first)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="rest" select="substring-after(normalize-space($right), ' ')"/>
  <xsl:choose>
    <xsl:when test="string-length($rest)">
      <xsl:call-template name="str:token-union">
        <xsl:with-param name="left" select="$out"/>
        <xsl:with-param name="right" select="$rest"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$out"/></xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template name="str:token-minus">
  <xsl:param name="tokens"/>
  <xsl:param name="minus"/>

  <xsl:if test="string-length(normalize-space($tokens))">

    <xsl:variable name="padded" select="concat(' ', normalize-space($tokens), ' ')"/>

    <xsl:choose>
      <xsl:when test="string-length(normalize-space($minus))">

        <xsl:variable name="minus-first">
          <xsl:text> </xsl:text>
          <xsl:call-template name="str:safe-first-token">
            <xsl:with-param name="tokens" select="$minus"/>
          </xsl:call-template>
          <xsl:text> </xsl:text>
        </xsl:variable>

        <xsl:variable name="out">
          <xsl:choose>
            <xsl:when test="contains($padded, $minus-first)">
              <xsl:value-of select="substring-before($padded, $minus-first)"/>
              <xsl:text> </xsl:text>
              <xsl:call-template name="str:token-minus">
                <xsl:with-param name="tokens" select="substring-after($padded, $minus-first)"/>
                <xsl:with-param name="minus" select="$minus-first"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$padded"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name="minus-rest" select="substring-after(normalize-space($minus), ' ')"/>

        <xsl:choose>
          <xsl:when test="string-length($minus-rest)">
            <xsl:call-template name="str:token-minus">
              <xsl:with-param name="tokens" select="normalize-space($out)"/>
              <xsl:with-param name="minus" select="$minus-rest"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="normalize-space($out)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space($tokens)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:template>

<xsl:template name="uri:document-for-uri">
  <xsl:param name="uri">
    <xsl:message terminate="yes">`uri` parameter required</xsl:message>
  </xsl:param>
  <xsl:choose>
    <xsl:when test="contains($uri, '#')">
      <xsl:value-of select="normalize-space(substring-before($uri, '#'))"/>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="normalize-space($uri)"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="html:*" mode="rdfa:multi-object-resources">
  <xsl:param name="current"    select="."/>
  <xsl:param name="base" select="normalize-space(($current/ancestor-or-self::html:html/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="subjects" select="$base"/>
  <xsl:param name="predicates" select="''"/>
  <xsl:param name="single"     select="false()"/>
  <xsl:param name="debug"      select="$rdfa:DEBUG"/>
  <xsl:param name="raw"        select="false()"/>
  <xsl:param name="prefixes">
    <xsl:apply-templates select="$current" mode="rdfa:prefix-stack"/>
  </xsl:param>

  <xsl:variable name="p" select="normalize-space($predicates)"/>
  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$p"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="$first">
    <xsl:variable name="_">
      <xsl:choose>
	<xsl:when test="starts-with($first, '^')">
	  <xsl:apply-templates select="$current" mode="rdfa:subject-resources">
	    <xsl:with-param name="base" select="$base"/>
	    <xsl:with-param name="object" select="$subjects"/>
	    <xsl:with-param name="predicate" select="substring-after($first, '^')"/>
	    <xsl:with-param name="single" select="$single"/>
	    <xsl:with-param name="debug" select="$debug"/>
	    <xsl:with-param name="raw" select="true()"/>
	    <xsl:with-param name="prefixes" select="$prefixes"/>
	  </xsl:apply-templates>
	</xsl:when>
	<xsl:otherwise>
	<xsl:apply-templates select="$current" mode="rdfa:object-resources">
	  <xsl:with-param name="base" select="$base"/>
	  <xsl:with-param name="subject" select="$subjects"/>
	  <xsl:with-param name="predicate" select="$first"/>
	  <xsl:with-param name="single" select="$single"/>
	  <xsl:with-param name="debug" select="$debug"/>
	  <xsl:with-param name="raw" select="true()"/>
	  <xsl:with-param name="prefixes" select="$prefixes"/>
	</xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:variable name="rest" select="substring-after($p, ' ')"/>
    <xsl:if test="$rest">
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="$current" mode="rdfa:multi-object-resources">
	<xsl:with-param name="current" select="$current"/>
	<xsl:with-param name="base" select="$base"/>
	<xsl:with-param name="subjects" select="$subjects"/>
	<xsl:with-param name="predicates" select="$rest"/>
	<xsl:with-param name="single" select="$single"/>
	<xsl:with-param name="debug" select="$debug"/>
	<xsl:with-param name="raw" select="$raw"/>
	<xsl:with-param name="continue" select="$continue"/>
	<xsl:with-param name="prefixes" select="$prefixes"/>
      </xsl:apply-templates>
    </xsl:if>
    </xsl:variable>

    <xsl:call-template name="str:unique-tokens">
      <xsl:with-param name="string" select="$_"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<!-- okay actual templates now -->

<xsl:template match="html:head">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <head>
  <xsl:apply-templates select="@*" mode="xc:attribute">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
  </xsl:apply-templates>

  <xsl:apply-templates select="html:title|html:base">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>

  <xsl:variable name="metas">
    <xsl:apply-templates select="." mode="rdfa:get-meta">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:if test="$metas">
    <xsl:apply-templates select="." mode="rdfa:add-meta-meta">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading"/>
      <xsl:with-param name="targets"       select="$metas"/>
    </xsl:apply-templates>
  </xsl:if>

  <xsl:apply-templates select="html:*[not(self::html:title|self::html:base)]">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>

  </head>
</xsl:template>

<xsl:template match="html:*" mode="rdfa:get-meta">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:variable name="top">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="concat($XHV, 'top')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="_">
    <xsl:call-template name="str:unique-tokens">
      <xsl:with-param name="string" select="concat($subject, ' ', $top)"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:message>get-meta: <xsl:value-of select="$_"/></xsl:message>

  <xsl:apply-templates select="." mode="rdfa:find-relations">
    <xsl:with-param name="resources" select="$_"/>
    <xsl:with-param name="predicate" select="concat($XHV, 'meta')"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="html:*" mode="rdfa:add-meta-meta">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="targets">
    <xsl:message terminate="yes">Required parameter `targets`</xsl:message>
  </xsl:param>

  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$targets"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:message>add-meta-meta: <xsl:value-of select="$targets"/></xsl:message>

  <xsl:variable name="meta" select="document($first)"/>

  <xsl:apply-templates select="$meta/html:html/html:head/html:*[not(self::html:title|self::html:base)]">
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
  </xsl:apply-templates>

  <xsl:variable name="rest" select="substring-after(normalize-space($targets), ' ')"/>
  <xsl:if test="$rest">
    <xsl:apply-templates select="." mode="rdfa:add-meta-meta">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading"/>
      <xsl:with-param name="targets"       select="$rest"/>
    </xsl:apply-templates>
  </xsl:if>

</xsl:template>

<x:doc>
  <h2>rdfa:find-relations</h2>
  <p>Retrieve the objects of a number of subjects and a given predicate.</p>
</x:doc>

<xsl:template match="html:*" mode="rdfa:find-relations">
  <xsl:param name="resources"  select="''"/>
  <xsl:param name="predicate" select="$rdfa:RDF-TYPE"/>
  <xsl:param name="reverse"   select="false()"/>
  <xsl:param name="state"     select="''"/>

  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$resources"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="string-length($first)">
      <xsl:variable name="doc">
        <xsl:call-template name="uri:document-for-uri">
          <xsl:with-param name="uri" select="$first"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="root" select="document($doc)/*"/>

      <xsl:variable name="out">
        <xsl:value-of select="concat($state, ' ')"/>
        <xsl:choose>
          <xsl:when test="$reverse">
            <xsl:message><xsl:value-of select="$first"/></xsl:message>
            <xsl:apply-templates select="$root/html:body" mode="rdfa:subject-resources">
              <xsl:with-param name="object" select="$first"/>
              <xsl:with-param name="base" select="$doc"/>
              <xsl:with-param name="predicate" select="$predicate"/>
              <!--<xsl:with-param name="debug" select="true()"/>-->
            </xsl:apply-templates>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="$root" mode="rdfa:object-resources">
              <xsl:with-param name="subject" select="$first"/>
              <xsl:with-param name="base" select="$doc"/>
              <xsl:with-param name="predicate" select="$predicate"/>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="rest" select="normalize-space(substring-after(normalize-space($resources), ' '))"/>

      <!--<xsl:message>first: <xsl:value-of select="$first"/> rest: <xsl:value-of select="$rest"/></xsl:message>-->

      <xsl:apply-templates select="." mode="rdfa:find-relations">
        <xsl:with-param name="resources" select="normalize-space($rest)"/>
        <xsl:with-param name="predicate" select="$predicate"/>
        <xsl:with-param name="reverse" select="$reverse"/>
        <xsl:with-param name="state" select="$out"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <!--<xsl:message><xsl:value-of select="normalize-space($state)"/></xsl:message>-->

      <xsl:call-template name="str:unique-tokens">
        <xsl:with-param name="string" select="normalize-space($state)"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="html:*" mode="rdfa:filter-by-predicate-object">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="subjects" select="''"/>
  <xsl:param name="predicate">
    <xsl:message terminate="yes">required parameter `predicate`</xsl:message>
  </xsl:param>
  <xsl:param name="object">
    <xsl:message terminate="yes">required parameter `object`</xsl:message>
  </xsl:param>
  <xsl:param name="literal" select="false()"/>
  <xsl:param name="traverse" select="true()"/>
  <xsl:param name="state" select="''"/>
  <xsl:param name="debug" select="false()"/>

  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$subjects"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="string-length($first)">
      <xsl:variable name="doc">
        <xsl:choose>
          <xsl:when test="$traverse">
            <xsl:call-template name="uri:document-for-uri">
              <xsl:with-param name="uri" select="$first"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="$base"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!--<xsl:variable name="root" select="(not($traverse) and .) or document($doc)/*"/>-->
      <xsl:variable name="root" select="document($doc)/*"/>

      <xsl:variable name="objects">
        <xsl:apply-templates select="$root" mode="rdfa:object-resources">
          <xsl:with-param name="subject" select="$first"/>
          <xsl:with-param name="base" select="$doc"/>
          <xsl:with-param name="predicate" select="$predicate"/>
        </xsl:apply-templates>
      </xsl:variable>

      <xsl:if test="$debug">
        <xsl:message>found objects for <xsl:value-of select="$first"/>: <xsl:value-of select="$objects"/></xsl:message>
      </xsl:if>

      <xsl:variable name="test">
        <xsl:variable name="_">
          <xsl:call-template name="str:token-intersection">
            <xsl:with-param name="left" select="$object"/>
            <xsl:with-param name="right" select="$objects"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:value-of select="normalize-space($_)"/>
      </xsl:variable>

      <xsl:variable name="out">
        <xsl:value-of select="$state"/>
        <xsl:if test="string-length($test)">
          <xsl:if test="string-length($state)">
            <xsl:text> </xsl:text>
          </xsl:if>
          <xsl:value-of select="normalize-space($first)"/>
        </xsl:if>
      </xsl:variable>

      <xsl:variable name="rest" select="normalize-space(substring-after(normalize-space($subjects), ' '))"/>
      <xsl:apply-templates select="." mode="rdfa:filter-by-predicate-object">
        <xsl:with-param name="subjects"  select="$rest"/>
        <xsl:with-param name="predicate" select="$predicate"/>
        <xsl:with-param name="object"    select="$object"/>
        <xsl:with-param name="literal"   select="$literal"/>
        <xsl:with-param name="state"     select="normalize-space($out)"/>
        <xsl:with-param name="traverse"  select="$traverse"/>
        <xsl:with-param name="debug"     select="$debug"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="str:unique-tokens">
        <xsl:with-param name="string" select="normalize-space($state)"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="html:*" mode="rdfa:filter-by-type">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="subjects" select="''"/>
  <xsl:param name="class">
    <xsl:message terminate="yes">required parameter `class`</xsl:message>
  </xsl:param>
  <xsl:param name="state" select="''"/>
  <xsl:param name="traverse" select="true()"/>

  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$subjects"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="string-length($first)">
      <xsl:variable name="padded" select="concat(' ', normalize-space($class), ' ')"/>
      <xsl:variable name="doc">
        <xsl:choose>
          <xsl:when test="$traverse">
            <xsl:call-template name="uri:document-for-uri">
              <xsl:with-param name="uri" select="$first"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="$base"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="root" select="document($doc)/*"/>

      <xsl:variable name="types">
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="$root" mode="rdfa:object-resources">
          <xsl:with-param name="subject" select="$first"/>
          <xsl:with-param name="base" select="$first"/>
          <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
        </xsl:apply-templates>
        <xsl:text> </xsl:text>
      </xsl:variable>

      <xsl:variable name="out">
        <xsl:value-of select="concat($state, ' ')"/>
        <xsl:if test="contains($types, $padded)">
          <xsl:value-of select="$first"/>
        </xsl:if>
      </xsl:variable>

      <xsl:variable name="rest" select="normalize-space(substring-after(normalize-space($subjects), ' '))"/>
      <xsl:apply-templates select="." mode="rdfa:filter-by-type">
        <xsl:with-param name="subjects" select="$rest"/>
        <xsl:with-param name="class" select="$class"/>
        <xsl:with-param name="state" select="normalize-space($out)"/>
        <xsl:with-param name="traverse" select="$traverse"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="str:unique-tokens">
        <xsl:with-param name="string" select="normalize-space($state)"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>


</xsl:stylesheet>
