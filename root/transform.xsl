<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:rdfa="http://www.w3.org/ns/rdfa#"
                xmlns:xc="https://makethingsmakesense.com/asset/transclude#"
                xmlns:x="urn:x-dummy:"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:bibo="http://purl.org/ontology/bibo/"
                xmlns:cgto="https://vocab.methodandstructure.com/graph-tool#"
                xmlns:ci="https://vocab.methodandstructure.com/content-inventory#"
                xmlns:dct="http://purl.org/dc/terms/"
                xmlns:foaf="http://xmlns.com/foaf/0.1/"
                xmlns:ibis="https://vocab.methodandstructure.com/ibis#"
                xmlns:org="http://www.w3.org/ns/org#"
                xmlns:pav="http://purl.org/pav/"
                xmlns:pm="https://vocab.methodandstructure.com/process-model#"
                xmlns:prov="http://www.w3.org/ns/prov#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:sioc="http://rdfs.org/sioc/ns#"
                xmlns:sioct="http://rdfs.org/sioc/types#"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#"
                xmlns:xhv="http://www.w3.org/1999/xhtml/vocab#"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
                xmlns:str="http://xsltsl.org/string"
                xmlns:uri="http://xsltsl.org/uri"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="html str uri rdfa xc x">

<xsl:import href="/asset/rdfa"/>
<xsl:import href="/asset/transclude"/>

<xsl:output
    method="xml" media-type="application/xhtml+xml"
    indent="yes" omit-xml-declaration="no"
    encoding="utf-8" doctype-public=""/>

<!-- note the namespace:: axis does not work in firefox or we could just use that -->
<xsl:variable name="IBIS" select="'https://vocab.methodandstructure.com/ibis#'"/>
<xsl:variable name="CGTO" select="'https://vocab.methodandstructure.com/graph-tool#'"/>
<xsl:variable name="BIBO" select="'http://purl.org/ontology/bibo/'"/>
<xsl:variable name="DCT"  select="'http://purl.org/dc/terms/'"/>
<xsl:variable name="QB"   select="'http://purl.org/linked-data/cube#'"/>
<xsl:variable name="SIOC" select="'http://rdfs.org/sioc/ns#'"/>
<xsl:variable name="SKOS" select="'http://www.w3.org/2004/02/skos/core#'"/>
<xsl:variable name="XHV"  select="'http://www.w3.org/1999/xhtml/vocab#'"/>

<!--
    Here is instance data we wish one day would live in the actual rdf
    or markup or whatever.
 -->

<x:lprops>
  <x:prop uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#value"/>
  <x:prop uri="http://www.w3.org/2004/02/skos/core#prefLabel"/>
  <x:prop uri="http://www.w3.org/2000/01/rdf-schema#label"/>
  <x:prop uri="http://purl.org/dc/terms/title"/>
  <x:prop uri="http://purl.org/dc/terms/identifier"/>
  <x:prop uri="http://xmlns.com/foaf/0.1/name"/>
</x:lprops>

<x:inverses>
  <x:pair a="https://vocab.methodandstructure.com/ibis#concerns" b="https://vocab.methodandstructure.com/ibis#concern-of"/>
  <x:pair a="https://vocab.methodandstructure.com/ibis#endorses" b="https://vocab.methodandstructure.com/ibis#endorsed-by"/>
  <x:pair a="https://vocab.methodandstructure.com/ibis#generalizes" b="https://vocab.methodandstructure.com/ibis#specializes"/>
  <x:pair a="https://vocab.methodandstructure.com/ibis#replaces" b="https://vocab.methodandstructure.com/ibis#replaced-by"/>
  <x:pair a="https://vocab.methodandstructure.com/ibis#questions" b="https://vocab.methodandstructure.com/ibis#questioned-by"/>
  <x:pair a="https://vocab.methodandstructure.com/ibis#suggests" b="https://vocab.methodandstructure.com/ibis#suggested-by"/>
  <x:pair a="https://vocab.methodandstructure.com/ibis#response" b="https://vocab.methodandstructure.com/ibis#responds-to"/>
  <x:pair a="https://vocab.methodandstructure.com/ibis#supports" b="https://vocab.methodandstructure.com/ibis#supported-by"/>
  <x:pair a="https://vocab.methodandstructure.com/ibis#opposes" b="https://vocab.methodandstructure.com/ibis#opposed-by"/>
  <x:pair a="http://www.w3.org/2004/02/skos/core#related" b="http://www.w3.org/2004/02/skos/core#related"/>
  <x:pair a="http://www.w3.org/2004/02/skos/core#narrower" b="http://www.w3.org/2004/02/skos/core#broader"/>
  <x:pair a="http://www.w3.org/2004/02/skos/core#narrowerTransitive" b="http://www.w3.org/2004/02/skos/core#broaderTransitive"/>
  <x:pair a="http://www.w3.org/2004/02/skos/core#narrowMatch" b="http://www.w3.org/2004/02/skos/core#broadMatch"/>
  <x:pair a="http://www.w3.org/2004/02/skos/core#closeMatch" b="http://www.w3.org/2004/02/skos/core#closeMatch"/>
  <x:pair a="http://www.w3.org/2004/02/skos/core#exactMatch" b="http://www.w3.org/2004/02/skos/core#exactMatch"/>
</x:inverses>

<!-- XXX i feel like some of this could be SHACL and the rest of it could be the ontologies themselves -->
<!-- maybe make something better like an rdfa page iunno -->
<x:sequence>
  <x:class uri="https://vocab.methodandstructure.com/ibis#Issue" icon="&#xf071;">
    <x:lprop uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#value"/>
    <x:label>Issue</x:label>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#response">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Position"/>
      <x:label>Has Response</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#questioned-by">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Questioned By</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#questions">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Position"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Questions</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#suggests">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:label>Suggests</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#suggested-by">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Position"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Suggested By</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#generalizes">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Generalizes</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#specializes">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Specializes</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#concerns">
      <x:range uri="http://www.w3.org/2004/02/skos/core#Concept"/>
      <x:label>Concerns</x:label>
    </x:prop>
  </x:class>
  <x:class uri="https://vocab.methodandstructure.com/ibis#Position" icon="&#xf0e3;">
    <x:lprop uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#value"/>
    <x:label>Position</x:label>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#responds-to">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Responds To</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#supported-by">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Supported By</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#opposed-by">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Opposed By</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#questioned-by">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Questioned By</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#suggests">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Suggests</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#generalizes">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Position"/>
      <x:label>Generalizes</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#specializes">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Position"/>
      <x:label>Specializes</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#concerns">
      <x:range uri="http://www.w3.org/2004/02/skos/core#Concept"/>
      <x:label>Concerns</x:label>
    </x:prop>
  </x:class>
  <x:class uri="https://vocab.methodandstructure.com/ibis#Argument" icon="&#xf086;">
    <x:lprop uri="http://www.w3.org/1999/02/22-rdf-syntax-ns#value"/>
    <x:label>Argument</x:label>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#supports">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Position"/>
      <x:label>Supports</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#opposes">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Position"/>
      <x:label>Opposes</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#response">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Position"/>
      <x:label>Has Response</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#questioned-by">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Questioned By</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#suggests">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Suggests</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#suggested-by">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Position"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Suggested By</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#generalizes">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Generalizes</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#specializes">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Specializes</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#concerns">
      <x:range uri="http://www.w3.org/2004/02/skos/core#Concept"/>
      <x:label>Concerns</x:label>
    </x:prop>
  </x:class>
  <x:class uri="http://www.w3.org/2004/02/skos/core#Concept" icon="&#x1f5ed;">
    <x:lprop uri="http://www.w3.org/2004/02/skos/core#prefLabel"/>
    <x:label>Position</x:label>
    <x:prop uri="http://www.w3.org/2004/02/skos/core#broader">
      <x:range uri="http://www.w3.org/2004/02/skos/core#Concept"/>
      <x:label>Has Broader</x:label>
    </x:prop>
    <x:prop uri="http://www.w3.org/2004/02/skos/core#narrower">
      <x:range uri="http://www.w3.org/2004/02/skos/core#Concept"/>
      <x:label>Has Narrower</x:label>
    </x:prop>
    <x:prop uri="http://www.w3.org/2004/02/skos/core#related">
      <x:range uri="http://www.w3.org/2004/02/skos/core#Concept"/>
      <x:label>Has Related</x:label>
    </x:prop>
    <x:prop uri="https://vocab.methodandstructure.com/ibis#concern-of">
      <x:range uri="https://vocab.methodandstructure.com/ibis#Issue"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Position"/>
      <x:range uri="https://vocab.methodandstructure.com/ibis#Argument"/>
      <x:label>Concern Of</x:label>
    </x:prop>
  </x:class>
</x:sequence>

<!-- other classes not in the sequence -->
<x:classes>
  <x:class uri="http://www.w3.org/2004/02/skos/core#ConceptScheme">
    <x:lprop uri="http://www.w3.org/2004/02/skos/core#prefLabel"/>
    <x:label>Concept Scheme</x:label>
  </x:class>
  <x:class uri="https://vocab.methodandstructure.com/ibis#Network">
    <x:lprop uri="http://www.w3.org/2004/02/skos/core#prefLabel"/>
    <x:label>Network</x:label>
  </x:class>
  <x:class uri="https://vocab.methodandstructure.com/graph-tool#Space">
    <x:lprop uri="http://purl.org/dc/terms/title"/>
    <x:label>Space</x:label>
  </x:class>
  <x:class uri="https://vocab.methodandstructure.com/graph-tool#View">
    <x:lprop uri="http://purl.org/dc/terms/title"/>
    <x:label>View</x:label>
  </x:class>
  <x:class uri="https://vocab.methodandstructure.com/graph-tool#Error">
    <x:lprop uri="http://purl.org/dc/terms/title"/>
    <x:label>Error</x:label>
  </x:class>
</x:classes>

<!-- utils -->

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
    <xsl:apply-templates select="." mode="get-meta">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:if test="$metas">
    <xsl:apply-templates select="." mode="add-meta-meta">
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

<xsl:template match="html:*" mode="get-meta">
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

<xsl:template match="html:*" mode="add-meta-meta">
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
    <xsl:apply-templates select="." mode="add-meta-meta">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading"/>
      <xsl:with-param name="targets"       select="$rest"/>
    </xsl:apply-templates>
  </xsl:if>

</xsl:template>

<!--
    This body template is intended to dispatch to type-specific
    templates; unfortunately I think they have to be hard-coded.
-->
<xsl:template match="html:body">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

<body>
  <xsl:apply-templates select="@*" mode="xc:attribute">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
  </xsl:apply-templates>

  <xsl:variable name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="type">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="type-pad" select="concat(' ', normalize-space($type), ' ')"/>

  <xsl:variable name="sequence" select="document('')/xsl:stylesheet/x:sequence"/>
  <xsl:variable name="classes"  select="document('')/xsl:stylesheet/x:classes"/>

  <xsl:variable name="match" select="($sequence|$classes)/x:class[contains($type-pad, concat(' ', @uri, ' '))][1]"/>

  <xsl:choose>
    <xsl:when test="$match">
      <!-- use the internal dispatcher -->
      <xsl:apply-templates select="$match">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
        <xsl:with-param name="current"       select="."/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <!-- otherwise just pass through -->
      <xsl:apply-templates>
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>
</body>
</xsl:template>


<!--
    These are shims that use the data embedded in the stylesheet to
    forward matches on to the type-specific templates. The current
    node (which should be the <body>) is passed in as a parameter.
-->

<xsl:template match="x:class">
  <xsl:param name="base">
    <xsl:message terminate="yes">`base` parameter required.</xsl:message>
  </xsl:param>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="current">
    <xsl:message terminate="yes">`current` parameter required.</xsl:message>
  </xsl:param>

  <xsl:apply-templates select="$current/node()">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:class[@uri='https://vocab.methodandstructure.com/ibis#Issue']">
  <xsl:param name="base">
    <xsl:message terminate="yes">`base` parameter required.</xsl:message>
  </xsl:param>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="current">
    <xsl:message terminate="yes">`current` parameter required.</xsl:message>
  </xsl:param>

  <xsl:apply-templates select="$current" mode="ibis:Entity">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:class[@uri='https://vocab.methodandstructure.com/ibis#Position']">
  <xsl:param name="base">
    <xsl:message terminate="yes">`base` parameter required.</xsl:message>
  </xsl:param>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="current">
    <xsl:message terminate="yes">`current` parameter required.</xsl:message>
  </xsl:param>

  <xsl:apply-templates select="$current" mode="ibis:Entity">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:class[@uri='https://vocab.methodandstructure.com/ibis#Argument']">
  <xsl:param name="base">
    <xsl:message terminate="yes">`base` parameter required.</xsl:message>
  </xsl:param>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="current">
    <xsl:message terminate="yes">`current` parameter required.</xsl:message>
  </xsl:param>

  <xsl:apply-templates select="$current" mode="ibis:Entity">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:class[@uri='http://www.w3.org/2004/02/skos/core#Concept']">
  <xsl:param name="base">
    <xsl:message terminate="yes">`base` parameter required.</xsl:message>
  </xsl:param>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="current">
    <xsl:message terminate="yes">`current` parameter required.</xsl:message>
  </xsl:param>

  <xsl:apply-templates select="$current" mode="skos:Concept">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:class[@uri='http://www.w3.org/2004/02/skos/core#ConceptScheme']">
  <xsl:param name="base">
    <xsl:message terminate="yes">`base` parameter required.</xsl:message>
  </xsl:param>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="current">
    <xsl:message terminate="yes">`current` parameter required.</xsl:message>
  </xsl:param>

  <xsl:apply-templates select="$current" mode="skos:ConceptScheme">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:class[@uri='https://vocab.methodandstructure.com/ibis#Network']">
  <xsl:param name="base">
    <xsl:message terminate="yes">`base` parameter required.</xsl:message>
  </xsl:param>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="current">
    <xsl:message terminate="yes">`current` parameter required.</xsl:message>
  </xsl:param>

  <xsl:apply-templates select="$current" mode="ibis:Network">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:class[@uri='https://vocab.methodandstructure.com/graph-tool#Space']">
  <xsl:param name="base">
    <xsl:message terminate="yes">`base` parameter required.</xsl:message>
  </xsl:param>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="current">
    <xsl:message terminate="yes">`current` parameter required.</xsl:message>
  </xsl:param>

  <xsl:apply-templates select="$current" mode="cgto:Space">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:class[@uri='https://vocab.methodandstructure.com/graph-tool#View']">
  <xsl:param name="base">
    <xsl:message terminate="yes">`base` parameter required.</xsl:message>
  </xsl:param>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="current">
    <xsl:message terminate="yes">`current` parameter required.</xsl:message>
  </xsl:param>

  <xsl:apply-templates select="$current" mode="cgto:View">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="x:class[@uri='https://vocab.methodandstructure.com/graph-tool#Error']">
  <xsl:param name="base">
    <xsl:message terminate="yes">`base` parameter required.</xsl:message>
  </xsl:param>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="current">
    <xsl:message terminate="yes">`current` parameter required.</xsl:message>
  </xsl:param>

  <xsl:apply-templates select="$current" mode="cgto:Error">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<!--
    These are the actual type-specific templates.
-->

<xsl:template match="html:body" mode="ibis:Entity">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="type">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
    </xsl:apply-templates>
  </xsl:param>

  <main>
    <article>
      <hgroup class="self">
        <xsl:apply-templates select="." mode="ibis:process-self">
          <xsl:with-param name="base"    select="$base"/>
          <xsl:with-param name="subject" select="$subject"/>
          <xsl:with-param name="type"    select="$type"/>
        </xsl:apply-templates>
      </hgroup>

      <section class="relations">
        <xsl:apply-templates select="." mode="ibis:process-neighbours">
          <xsl:with-param name="base"          select="$base"/>
          <xsl:with-param name="resource-path" select="$resource-path"/>
          <xsl:with-param name="rewrite"       select="$rewrite"/>
          <xsl:with-param name="main"          select="true()"/>
          <xsl:with-param name="heading"       select="$heading"/>
          <xsl:with-param name="subject"       select="$subject"/>
          <xsl:with-param name="type"          select="$type"/>
        </xsl:apply-templates>
      </section>
    </article>
    <figure id="force" class="aside"/>
    <xsl:apply-templates select="." mode="ibis:make-datalist">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="true()"/>
      <xsl:with-param name="heading"       select="$heading"/>
      <xsl:with-param name="subject"       select="$subject"/>
    </xsl:apply-templates>
  </main>
  <footer>
    <xsl:variable name="top">
      <xsl:apply-templates select="." mode="rdfa:object-resources">
        <xsl:with-param name="subject" select="$subject"/>
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="predicate" select="concat($XHV, 'top')"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="$top and $top != $base">
      <a href="{$top}">Overview</a>
    </xsl:if>
  </footer>
</xsl:template>

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

<xsl:template match="html:*" mode="rdfa:find-indices">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="origins">
    <xsl:variable name="subject">
      <xsl:apply-templates select="." mode="rdfa:get-subject">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="debug" select="false()"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="top">
      <xsl:apply-templates select="." mode="rdfa:object-resources">
        <xsl:with-param name="subject" select="$subject"/>
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="predicate" select="concat($XHV, 'top')"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:call-template name="str:unique-tokens">
      <xsl:with-param name="string" select="concat($subject, ' ', $top)"/>
    </xsl:call-template>
  </xsl:param>
  <xsl:param name="relations">
    <xsl:message terminate="yes">`relations` parameter required</xsl:message>
  </xsl:param>
  <xsl:param name="debug" select="$rdfa:DEBUG"/>

  <xsl:variable name="metas">
    <xsl:apply-templates select="." mode="rdfa:find-relations">
      <xsl:with-param name="resources" select="$origins"/>
      <xsl:with-param name="predicate" select="concat($XHV, 'meta')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:if test="$debug">
    <xsl:message>rdfa:find-indices: metas: <xsl:value-of select="$metas"/></xsl:message>
  </xsl:if>

  <xsl:variable name="candidates">
    <xsl:apply-templates select="." mode="rdfa:filter-by-type">
      <xsl:with-param name="subjects">
        <xsl:apply-templates select="." mode="rdfa:find-relations">
          <xsl:with-param name="resources">
            <xsl:call-template name="str:unique-tokens">
              <xsl:with-param name="string" select="concat($origins, ' ', $metas)"/>
            </xsl:call-template>
          </xsl:with-param>
          <xsl:with-param name="predicate" select="concat($XHV, 'index')"/>
        </xsl:apply-templates>
      </xsl:with-param>
      <xsl:with-param name="class" select="concat($CGTO, 'Index')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:if test="$debug">
    <xsl:message>rdfa:find-indices: <xsl:value-of select="$candidates"/></xsl:message>
  </xsl:if>

  <xsl:choose>
    <xsl:when test="string-length(normalize-space($relations))">
      <xsl:apply-templates select="." mode="rdfa:find-relations">
        <xsl:with-param name="resources" select="$candidates"/>
        <xsl:with-param name="predicate" select="$relations"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$candidates"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- extremely specific i know but we use this more than once -->

<xsl:template match="html:*" mode="rdfa:find-inventories-by-class">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="origins">
    <xsl:variable name="top">
      <xsl:apply-templates select="." mode="rdfa:object-resources">
        <xsl:with-param name="subject" select="$subject"/>
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="predicate" select="concat($XHV, 'top')"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:call-template name="str:unique-tokens">
      <xsl:with-param name="string" select="concat($subject, ' ', $top)"/>
    </xsl:call-template>
  </xsl:param>
  <xsl:param name="summaries">
    <xsl:apply-templates select="." mode="rdfa:find-indices">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="origins" select="$origins"/>
      <xsl:with-param name="relations" select="concat($CGTO, 'by-class')"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="classes">
    <xsl:message terminate="yes">`classes` parameter required</xsl:message>
  </xsl:param>

  <xsl:if test="string-length(normalize-space($summaries))">
    <xsl:variable name="observations">
      <xsl:variable name="_">
        <xsl:apply-templates select="." mode="rdfa:find-relations">
          <xsl:with-param name="resources" select="$summaries"/>
          <xsl:with-param name="predicate" select="concat($QB, 'dataSet')"/>
            <xsl:with-param name="reverse" select="true()"/>
        </xsl:apply-templates>
      </xsl:variable>

      <xsl:choose>
        <xsl:when test="string-length(normalize-space($classes))">
          <xsl:apply-templates select="." mode="rdfa:filter-by-predicate-object">
            <xsl:with-param name="subjects" select="$_"/>
            <xsl:with-param name="predicate" select="concat($CGTO, 'class')"/>
            <xsl:with-param name="object" select="$classes"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$_"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:apply-templates select="." mode="rdfa:find-relations">
      <xsl:with-param name="resources" select="$observations"/>
      <xsl:with-param name="predicate" select="concat($CGTO, 'subjects')"/>
    </xsl:apply-templates>

  </xsl:if>

</xsl:template>

<xsl:template match="html:*" mode="ibis:make-datalist">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:param name="type">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:variable name="top">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="concat($XHV, 'top')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="class-lists">
    <xsl:apply-templates select="." mode="rdfa:find-indices">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="origins" select="concat($subject, ' ', $top)"/>
      <xsl:with-param name="relations" select="concat($CGTO, 'by-class')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="inventories">
    <xsl:apply-templates select="." mode="rdfa:find-inventories-by-class">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="origins" select="concat($subject, ' ', $top)"/>
      <xsl:with-param name="classes">
        <xsl:value-of select="concat($IBIS, 'Issue')"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="concat($IBIS, 'Position')"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="concat($IBIS, 'Argument')"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="concat($SKOS, 'Concept')"/>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:variable>

  <datalist id="big-friggin-list">
    <xsl:if test="string-length(normalize-space($inventories))">
      <xsl:apply-templates select="." mode="ibis:datalist-options">
        <xsl:with-param name="inventories" select="$inventories"/>
      </xsl:apply-templates>
    </xsl:if>
  </datalist>
</xsl:template>

<xsl:template match="html:*" mode="ibis:datalist-options">
  <xsl:param name="inventories">
    <xsl:message terminate="yes">`inventories` parameter required</xsl:message>
  </xsl:param>

  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$inventories"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="string-length($first)">
    <xsl:variable name="doc">
      <xsl:call-template name="uri:document-for-uri">
        <xsl:with-param name="uri" select="$first"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="root" select="document($doc)/*"/>

    <xsl:variable name="resources">
      <xsl:apply-templates select="$root/html:body" mode="rdfa:object-resources">
        <xsl:with-param name="subject" select="$first"/>
        <xsl:with-param name="base"    select="$doc"/>
        <xsl:with-param name="predicate" select="'http://purl.org/dc/terms/hasPart'"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:message><xsl:value-of select="$first"/></xsl:message>

    <xsl:apply-templates select="$root" mode="ibis:actual-option">
      <xsl:with-param name="inventory" select="$first"/>
      <xsl:with-param name="resources" select="$resources"/>
    </xsl:apply-templates>

    <xsl:variable name="rest" select="normalize-space(substring-after(normalize-space($inventories), ' '))"/>
    <xsl:if test="string-length($rest)">
      <xsl:apply-templates select="." mode="ibis:datalist-options">
        <xsl:with-param name="inventories" select="$rest"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:if>
</xsl:template>

<xsl:template match="html:*" mode="ibis:actual-option">
  <xsl:param name="inventory">
    <xsl:message terminate="yes">`inventory` parameter required</xsl:message>
  </xsl:param>
  <xsl:param name="resources">
    <xsl:message terminate="yes">`resources` parameter required</xsl:message>
  </xsl:param>

  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$resources"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="string-length($first)">

    <xsl:variable name="types">
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="." mode="rdfa:object-resources">
        <xsl:with-param name="subject" select="$first"/>
        <!--<xsl:with-param name="base" select="$first"/>-->
        <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
      </xsl:apply-templates>
      <xsl:text> </xsl:text>
    </xsl:variable>

    <xsl:variable name="sequence" select="document('')/xsl:stylesheet/x:sequence[1]"/>
    <xsl:variable name="lprop" select="$sequence/x:class[contains($types, @uri)]/x:lprop/@uri"/>

    <xsl:variable name="type-curie">
      <xsl:call-template name="rdfa:make-curie-list">
        <xsl:with-param name="list" select="$types"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="lprop-curie">
      <xsl:call-template name="rdfa:make-curie-list">
        <xsl:with-param name="list" select="$lprop"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="label">
      <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
        <xsl:with-param name="subject" select="$first"/>
        <xsl:with-param name="predicate" select="$lprop"/>
      </xsl:apply-templates>
    </xsl:variable>

    <option about="{$first}" typeof="{$type-curie}" value="{$first}" property="{$lprop-curie}">
      <xsl:value-of select="substring-before($label, $rdfa:UNIT-SEP)"/>
    </option>

    <xsl:variable name="rest" select="normalize-space(substring-after(normalize-space($resources), ' '))"/>
    <xsl:if test="string-length($rest)">
      <xsl:apply-templates select="." mode="ibis:actual-option">
        <xsl:with-param name="inventory" select="$inventory"/>
        <xsl:with-param name="resources" select="$rest"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:if>
</xsl:template>

<xsl:template match="html:*" mode="ibis:process-self">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:param name="type">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:variable name="value">
    <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="concat($rdfa:RDF-NS, 'value')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="created">
    <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="'http://purl.org/dc/terms/created'"/>
    </xsl:apply-templates>
  </xsl:variable>

  <h1 class="heading">
    <xsl:call-template name="ibis:toggle-list">
      <xsl:with-param name="type" select="$type"/>
    </xsl:call-template>
    <form accept-charset="utf-8" action="" class="description" method="POST">
      <textarea class="heading" name="= rdf:value"><xsl:value-of select="substring-before($value, $rdfa:UNIT-SEP)"/></textarea>
      <button class="fa fa-sync" title="Save Text"></button>
    </form>
  </h1>
  <span class="date" property="dct:created" content="{substring-before($created, $rdfa:UNIT-SEP)}" datatype="{substring-after($created, $rdfa:UNIT-SEP)}">Created <xsl:value-of select="substring-before($created, 'T')"/></span>
</xsl:template>

<xsl:template match="html:*" mode="ibis:process-neighbours">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="type">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:variable name="sequence" select="document('')/xsl:stylesheet/x:sequence[1]"/>
  <xsl:variable name="current" select="."/>

  <xsl:for-each select="$sequence/x:class[@uri = $type]/x:prop">
    <xsl:variable name="targets">
      <xsl:apply-templates select="$current" mode="rdfa:object-resources">
        <xsl:with-param name="subject" select="$subject"/>
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="predicate" select="@uri"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="curie">
      <xsl:call-template name="rdfa:make-curie">
        <xsl:with-param name="uri" select="@uri"/>
        <xsl:with-param name="node" select="$current"/>
      </xsl:call-template>
    </xsl:variable>

    <section about="{@uri}">
      <h3 property="rdfs:label"><xsl:value-of select="x:label"/></h3>
      <xsl:apply-templates select="." mode="add-relation">
        <xsl:with-param name="base"    select="$base"/>
        <xsl:with-param name="current" select="$current"/>
        <xsl:with-param name="subject" select="$subject"/>
      </xsl:apply-templates>
      <xsl:if test="normalize-space($targets)">
      <ul about="" rel="{$curie}">
        <xsl:apply-templates select="$current" mode="link-stack">
          <xsl:with-param name="base"          select="$base"/>
          <xsl:with-param name="resource-path" select="$resource-path"/>
          <xsl:with-param name="rewrite"       select="$rewrite"/>
          <xsl:with-param name="main"          select="$main"/>
          <xsl:with-param name="heading"       select="$heading"/>
          <xsl:with-param name="predicate"     select="@uri"/>
          <xsl:with-param name="stack"         select="$targets"/>
        </xsl:apply-templates>
      </ul>
      </xsl:if>
    </section>
  </xsl:for-each>

</xsl:template>

<xsl:template match="x:prop" mode="add-relation">
  <xsl:param name="base" select="/.."/>
  <xsl:param name="current" select="/.."/>
  <xsl:param name="subject">
    <xsl:apply-templates select="$current" mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:variable name="predicate" select="string(@uri)"/>

  <xsl:variable name="p-curie">
    <xsl:call-template name="rdfa:make-curie">
      <xsl:with-param name="uri" select="@uri"/>
      <xsl:with-param name="node" select="$current"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="inverse">
    <xsl:variable name="_" select="document('')/xsl:stylesheet/x:inverses"/>
    <xsl:value-of select="($_/x:pair[@a=$predicate]/@b|$_/x:pair[@b=$predicate]/@a)[1]"/>
  </xsl:variable>

  <xsl:variable name="i-curie">
    <xsl:call-template name="rdfa:make-curie">
      <xsl:with-param name="uri" select="$inverse"/>
      <xsl:with-param name="node" select="$current"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="scheme">
    <xsl:variable name="_">
      <xsl:call-template name="str:token-union">
        <xsl:with-param name="left">
          <xsl:apply-templates select="$current" mode="rdfa:object-resources">
            <xsl:with-param name="subject" select="$subject"/>
            <xsl:with-param name="predicate" select="concat($SKOS, 'topConceptOf')"/>
          </xsl:apply-templates>
        </xsl:with-param>
        <xsl:with-param name="right">
          <xsl:apply-templates select="$current" mode="rdfa:object-resources">
            <xsl:with-param name="subject" select="$subject"/>
            <xsl:with-param name="predicate" select="concat($SKOS, 'inScheme')"/>
          </xsl:apply-templates>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$_"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="sequence" select="document('')/xsl:stylesheet/x:sequence[1]"/>

  <form method="POST" action="" accept-charset="utf-8">
    <input class="new" type="hidden" name="$ SUBJECT $" value="$NEW_UUID_URN"/>
    <input class="new" type="hidden" name="{$i-curie} :" value="{$base}"/>
    <xsl:for-each select="x:range">
      <xsl:variable name="class" select="$sequence/x:class[@uri = current()/@uri]"/>
      <xsl:variable name="c-curie">
        <xsl:call-template name="rdfa:make-curie">
          <xsl:with-param name="uri" select="$class/@uri"/>
          <xsl:with-param name="node" select="$current"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="lprop" select="$class/x:lprop[1]/@uri"/>
      <xsl:variable name="lprop-curie">
        <xsl:call-template name="rdfa:make-curie-list">
          <xsl:with-param name="list" select="$lprop"/>
          <xsl:with-param name="node" select="$current"/>
        </xsl:call-template>
      </xsl:variable>
      <!-- safari requires tabindex for :focus-within to work -->
      <input tabindex="{count(preceding-sibling::x:range)}" type="radio" class="fa" name="$ type" value="{$c-curie}"/>
      <input about="{$c-curie}" class="new label" disabled="disabled" type="hidden" name="= {$lprop-curie} $" value="$label"/>
    </xsl:for-each>
    <xsl:if test="normalize-space($scheme)">
      <input type="hidden" name="skos:inScheme :" value="{$scheme}"/>
    </xsl:if>
    <input class="new" type="hidden" name="= rdf:type : $" value="$type"/>
    <input class="existing" disabled="disabled" type="hidden" name="{$p-curie} :"/>
    <!-- fucking safari and its tabindex -->
    <input tabindex="{count(x:range)}" type="text" name="$ label" list="big-friggin-list"/>
  </form>
</xsl:template>

<xsl:template match="*" mode="link-stack">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:param name="predicate" select="''"/>
  <xsl:param name="stack" select="''"/>

  <xsl:variable name="s" select="normalize-space($stack)"/>

  <xsl:if test="$s">
    <xsl:variable name="first">
      <xsl:call-template name="str:safe-first-token">
        <xsl:with-param name="tokens" select="$s"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="rest" select="substring-after($s, ' ')"/>

    <xsl:variable name="type">
      <xsl:apply-templates select="." mode="rdfa:object-resources">
        <xsl:with-param name="subject" select="$first"/>
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="type-curie">
      <xsl:call-template name="rdfa:make-curie-list">
        <xsl:with-param name="list" select="$type"/>
        <xsl:with-param name="node" select="."/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="sequence" select="document('')/xsl:stylesheet/x:sequence[1]"/>
    <xsl:variable name="lprop" select="$sequence/x:class[@uri = $type]/x:lprop/@uri"/>

    <xsl:variable name="label-curie">
      <xsl:call-template name="rdfa:make-curie">
        <xsl:with-param name="uri" select="$lprop"/>
        <xsl:with-param name="node" select="."/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="label">
      <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
        <xsl:with-param name="subject" select="$first"/>
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="predicate" select="$lprop"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="p-curie">
      <xsl:call-template name="rdfa:make-curie">
        <xsl:with-param name="uri" select="$predicate"/>
        <xsl:with-param name="node" select="."/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="inverse">
      <xsl:variable name="_" select="document('')/xsl:stylesheet/x:inverses"/>
      <xsl:value-of select="($_/x:pair[@a=$predicate]/@b|$_/x:pair[@b=$predicate]/@a)[1]"/>
    </xsl:variable>

    <xsl:variable name="i-curie">
      <xsl:call-template name="rdfa:make-curie">
        <xsl:with-param name="uri" select="$inverse"/>
        <xsl:with-param name="node" select="."/>
      </xsl:call-template>
    </xsl:variable>

    <li about="{$first}" typeof="{$type-curie}">
      <form accept-charset="utf-8" action="" method="POST">
        <input name="-! {$i-curie} :" type="hidden" value="{$first}"/>
        <button class="disconnect fa fa-unlink" name="- {$p-curie} :" value="{$first}"></button>
        <a href="{$first}" property="{$label-curie}">
          <xsl:value-of select="substring-before($label, $rdfa:UNIT-SEP)"/>
        </a>
      </form>
      <!--<xsl:comment><xsl:value-of select="$rest"/></xsl:comment>-->
    </li>

    <xsl:if test="normalize-space($rest)">
      <xsl:apply-templates select="." mode="link-stack">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
        <xsl:with-param name="predicate"     select="$predicate"/>
        <xsl:with-param name="stack" select="$rest"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:if>
</xsl:template>

<xsl:template name="ibis:toggle-list">
  <xsl:param name="type" select="'https://vocab.methodandstructure.com/ibis#Issue'"/>

  <form accept-charset="utf-8" action="" class="types" method="POST">
    <button class="set-type fa fa-exclamation-triangle" name="= rdf:type :" title="Convert to Issue" value="ibis:Issue">
      <xsl:if test="$type = 'https://vocab.methodandstructure.com/ibis#Issue'">
        <xsl:attribute name="disabled">disabled</xsl:attribute>
      </xsl:if>
    </button>
    <button class="set-type fa fa-gavel" name="= rdf:type :" title="Convert to Position" value="ibis:Position">
      <xsl:if test="$type = 'https://vocab.methodandstructure.com/ibis#Position'">
        <xsl:attribute name="disabled">disabled</xsl:attribute>
      </xsl:if>
    </button>
    <button class="set-type fa fa-comments" name="= rdf:type :" title="Convert to Argument" value="ibis:Argument">
      <xsl:if test="$type = 'https://vocab.methodandstructure.com/ibis#Argument'">
        <xsl:attribute name="disabled">disabled</xsl:attribute>
      </xsl:if>
    </button>
  </form>
</xsl:template>

<!-- SKOS concept -->

<xsl:template match="html:body" mode="skos:Concept">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:param name="type">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
    </xsl:apply-templates>
  </xsl:param>

  <main>
    <article>
      <hgroup class="self">
        <xsl:apply-templates select="." mode="skos:process-self">
          <xsl:with-param name="base"    select="$base"/>
          <xsl:with-param name="subject" select="$subject"/>
          <xsl:with-param name="type"    select="$type"/>
        </xsl:apply-templates>
      </hgroup>

      <section class="relations">
        <xsl:apply-templates select="." mode="ibis:process-neighbours">
          <xsl:with-param name="base"          select="$base"/>
          <xsl:with-param name="resource-path" select="$resource-path"/>
          <xsl:with-param name="rewrite"       select="$rewrite"/>
          <xsl:with-param name="main"          select="true()"/>
          <xsl:with-param name="heading"       select="$heading"/>
          <xsl:with-param name="subject"       select="$subject"/>
          <xsl:with-param name="type"          select="$type"/>
        </xsl:apply-templates>
      </section>
    </article>
    <figure id="force" class="aside"/>
    <xsl:apply-templates select="." mode="ibis:make-datalist">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="true()"/>
      <xsl:with-param name="heading"       select="$heading"/>
      <xsl:with-param name="subject"       select="$subject"/>
    </xsl:apply-templates>
  </main>
  <footer>
    <xsl:variable name="top">
      <xsl:apply-templates select="." mode="rdfa:object-resources">
        <xsl:with-param name="subject" select="$subject"/>
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="predicate" select="'http://www.w3.org/1999/xhtml/vocab#top'"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="$top and $top != $base">
      <a href="{$top}">Overview</a>
    </xsl:if>
  </footer>
</xsl:template>

<xsl:template match="html:*" mode="skos:process-self">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:param name="type">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:variable name="label">
    <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="concat($SKOS, 'prefLabel')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="definition">
    <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="concat($SKOS, 'definition')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="created">
    <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="'http://purl.org/dc/terms/created'"/>
    </xsl:apply-templates>
  </xsl:variable>

<h1>
  <form accept-charset="utf-8" action="" method="POST">
    <input type="text" name="= skos:prefLabel" value="{substring-before($label, $rdfa:UNIT-SEP)}"/>
    <button class="fa fa-sync"/>
  </form>
</h1>
<form accept-charset="utf-8" action="" method="POST">
  <textarea class="description" name="= skos:definition">
    <xsl:value-of select="substring-before($definition, $rdfa:UNIT-SEP)"/>
  </textarea>
  <button class="update fa fa-sync"></button>
</form>
<xsl:apply-templates select="." mode="skos:label-form">
  <xsl:with-param name="base" select="$base"/>
  <xsl:with-param name="subject" select="$subject"/>
</xsl:apply-templates>
<xsl:apply-templates select="." mode="skos:label-form">
  <xsl:with-param name="base" select="$base"/>
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="predicate" select="concat($SKOS, 'hiddenLabel')"/>
  <xsl:with-param name="label" select="'Hidden Labels'"/>
</xsl:apply-templates>
</xsl:template>

<xsl:template match="html:*" mode="skos:label-form">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="predicate" select="concat($SKOS, 'altLabel')"/>
  <xsl:param name="label" select="'Alternate Labels'"/>

  <xsl:variable name="labels">
    <xsl:apply-templates select="." mode="rdfa:object-literals">
      <xsl:with-param name="subject"   select="$subject"/>
      <xsl:with-param name="base"      select="$base"/>
      <xsl:with-param name="predicate" select="$predicate"/>
    </xsl:apply-templates>
  </xsl:variable>

  <!--<xsl:message><xsl:value-of select="$labels"/></xsl:message>-->

  <aside>
    <h5><xsl:value-of select="$label"/></h5>
    <ul>
      <xsl:apply-templates select="." mode="skos:label-form-entry">
        <xsl:with-param name="predicate" select="$predicate"/>
        <xsl:with-param name="labels"    select="$labels"/>
      </xsl:apply-templates>
      <li>
        <form method="POST" action="" accept-charset="utf-8">
          <input type="text" name="{$predicate}"/>
          <button class="fa fa-plus"/>
        </form>
      </li>
    </ul>
  </aside>
</xsl:template>

<xsl:template match="html:*" mode="skos:label-form-entry">
  <xsl:param name="predicate"/>
  <xsl:param name="labels"/>

  <xsl:variable name="first">
    <xsl:choose>
      <xsl:when test="contains($labels, $rdfa:RECORD-SEP)">
        <xsl:value-of select="substring-before($labels, $rdfa:RECORD-SEP)"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$labels"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:if test="string-length($first)">
    <xsl:variable name="value" select="substring-before($first, $rdfa:UNIT-SEP)"/>
    <xsl:variable name="lang-or-dt" select="substring-after($first, $rdfa:UNIT-SEP)"/>
    <xsl:variable name="datatype">
      <xsl:if test="contains($lang-or-dt, ':')"><xsl:value-of select="$lang-or-dt"/></xsl:if>
    </xsl:variable>

    <xsl:variable name="language">
      <xsl:if test="not(string-length($datatype))">
        <xsl:value-of select="normalize-space($lang-or-dt)"/>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="designator">
      <xsl:choose>
        <xsl:when test="string-length($datatype)">
          <xsl:text> ^</xsl:text>
          <xsl:value-of select="$datatype"/>
        </xsl:when>
        <xsl:when test="string-length($language)">
          <xsl:text> @</xsl:text>
          <xsl:value-of select="$language"/>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </xsl:variable>

    <li>
      <form method="POST" action="" accept-charset="utf-8">
      <span property="{$predicate}">
        <xsl:if test="string-length($language)">
          <xsl:attribute name="xml:lang"><xsl:value-of select="$language"/></xsl:attribute>
        </xsl:if>
        <xsl:if test="string-length($datatype)">
          <xsl:attribute name="datatype"><xsl:value-of select="$datatype"/></xsl:attribute>
        </xsl:if>
        <xsl:value-of select="$value"/>
      </span>
        <button class="disconnect fa fa-times" name="- {$predicate}{$designator}" value="{$value}"></button>
      </form>
    </li>

    <xsl:variable name="rest" select="substring-after($labels, $rdfa:RECORD-SEP)"/>
    <xsl:if test="string-length($rest)">
      <xsl:apply-templates select="." mode="skos:label-form-entry">
        <xsl:with-param name="predicate" select="$predicate"/>
        <xsl:with-param name="labels" select="$rest"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:if>
</xsl:template>

<!-- concept schemes -->

<xsl:template match="html:body" mode="skos:ConceptScheme">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:variable name="top-concepts">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="concat($SKOS, 'hasTopConcept')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="in-scheme">
    <xsl:call-template name="str:token-minus">
      <xsl:with-param name="tokens">
        <xsl:apply-templates select="." mode="rdfa:subject-resources">
          <xsl:with-param name="object" select="$subject"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="predicate" select="concat($SKOS, 'inScheme')"/>
        </xsl:apply-templates>
      </xsl:with-param>
      <xsl:with-param name="minus" select="$top-concepts"/>
    </xsl:call-template>
  </xsl:variable>

  <main>
    <article>
      <form method="POST" action="" accept-charset="utf-8">
        <input type="hidden" name="$ SUBJECT $" value="$NEW_UUID_URN"/>
        <input type="hidden" name="rdf:type :" value="skos:Concept"/>
        <input type="hidden" name="skos:inScheme :" value="{$subject}"/>
        <input type="text" name="= skos:prefLabel"/>
        <button class="fa fa-plus"/>
      </form>
      <ul>
        <xsl:if test="string-length(normalize-space($top-concepts))">
          <xsl:apply-templates select="." mode="skos:scheme-item">
            <xsl:with-param name="resources" select="normalize-space($top-concepts)"/>
          </xsl:apply-templates>
        </xsl:if>
        <xsl:if test="string-length(normalize-space($in-scheme))">
          <xsl:apply-templates select="." mode="skos:scheme-item">
            <xsl:with-param name="resources" select="normalize-space($in-scheme)"/>
          </xsl:apply-templates>
        </xsl:if>
      </ul>
    </article>
    <figure id="force" class="aside"/>
  </main>
</xsl:template>

<xsl:template match="html:*" mode="skos:scheme-item">
  <xsl:param name="resources">
    <xsl:message terminate="yes">`resources` required</xsl:message>
  </xsl:param>
  <xsl:param name="lprop" select="concat($SKOS, 'prefLabel')"/>

  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$resources"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="types">
    <xsl:call-template name="rdfa:make-curie-list">
      <xsl:with-param name="list">
        <xsl:apply-templates select="." mode="rdfa:object-resources">
          <xsl:with-param name="subject" select="$first"/>
          <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
        </xsl:apply-templates>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="lpc">
    <xsl:call-template name="rdfa:make-curie">
      <xsl:with-param name="uri" select="$lprop"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="label">
    <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
      <xsl:with-param name="subject" select="$first"/>
      <xsl:with-param name="predicate" select="$lprop"/>
    </xsl:apply-templates>
  </xsl:variable>

  <li>
    <a href="{$first}">
      <xsl:if test="string-length($types)">
        <xsl:attribute name="typeof"><xsl:value-of select="$types"/></xsl:attribute>
      </xsl:if>
      <span property="{$lpc}">
        <xsl:choose>
          <xsl:when test="contains(substring-after($label, $rdfa:UNIT-SEP), ':')">
            <xsl:attribute name="datatype">
              <xsl:value-of select="substring-after($label, $rdfa:UNIT-SEP)"/>
            </xsl:attribute>
          </xsl:when>
          <xsl:when test="string-length(substring-after($label, $rdfa:UNIT-SEP))">
            <xsl:attribute name="xml:lang">
              <xsl:value-of select="substring-after($label, $rdfa:UNIT-SEP)"/>
            </xsl:attribute>
          </xsl:when>
        </xsl:choose>
        <xsl:value-of select="substring-before($label, $rdfa:UNIT-SEP)"/>
      </span>
    </a>
  </li>

  <xsl:variable name="rest" select="substring-after(normalize-space($resources), ' ')"/>
  <xsl:if test="string-length($rest)">
    <xsl:apply-templates select="." mode="skos:scheme-item">
      <xsl:with-param name="resources" select="$rest"/>
      <xsl:with-param name="lprop" select="$lprop"/>
    </xsl:apply-templates>
  </xsl:if>
</xsl:template>

<!-- ibis network -->

<xsl:template match="html:body" mode="ibis:Network">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:variable name="adjacents">
    <xsl:call-template name="str:token-union">
      <xsl:with-param name="left">
        <xsl:apply-templates select="." mode="rdfa:object-resources">
          <xsl:with-param name="subject" select="$subject"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="predicate" select="concat($SKOS, 'hasTopConcept')"/>
        </xsl:apply-templates>
      </xsl:with-param>
      <xsl:with-param name="right">
        <xsl:apply-templates select="." mode="rdfa:subject-resources">
          <xsl:with-param name="object" select="$subject"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="predicate" select="concat($SKOS, 'inScheme')"/>
        </xsl:apply-templates>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="issues">
    <xsl:apply-templates select="." mode="rdfa:filter-by-type">
      <xsl:with-param name="subjects" select="$adjacents"/>
      <xsl:with-param name="class" select="concat($IBIS, 'Issue')"/>
      <xsl:with-param name="traverse" select="false()"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="positions">
    <xsl:apply-templates select="." mode="rdfa:filter-by-type">
      <xsl:with-param name="subjects" select="$adjacents"/>
      <xsl:with-param name="class" select="concat($IBIS, 'Position')"/>
      <xsl:with-param name="traverse" select="false()"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="arguments">
    <xsl:apply-templates select="." mode="rdfa:filter-by-type">
      <xsl:with-param name="subjects" select="$adjacents"/>
      <xsl:with-param name="class" select="concat($IBIS, 'Argument')"/>
      <xsl:with-param name="traverse" select="false()"/>
    </xsl:apply-templates>
  </xsl:variable>

  <main>
    <article>
      <form method="POST" action="" accept-charset="utf-8">
        <input type="hidden" name="$ SUBJECT $" value="$NEW_UUID_URN"/>
        <input type="hidden" name="skos:inScheme :" value="{$subject}"/>
        <select name="= rdf:type :">
          <option value="ibis:Issue">Issue</option>
          <option value="ibis:Position">Position</option>
          <option value="ibis:Argument">Argument</option>
        </select>
        <input type="text" name="= rdf:value"/>
        <button class="fa fa-plus"/>
      </form>
      <xsl:if test="string-length(normalize-space($issues))">
        <section>
          <h2>Issues</h2>
          <ul>
            <xsl:apply-templates select="." mode="skos:scheme-item">
              <xsl:with-param name="resources" select="$issues"/>
              <xsl:with-param name="lprop" select="concat($rdfa:RDF-NS, 'value')"/>
            </xsl:apply-templates>
          </ul>
        </section>
      </xsl:if>
      <xsl:if test="string-length(normalize-space($positions))">
        <section>
          <h2>Positions</h2>
          <ul>
            <xsl:apply-templates select="." mode="skos:scheme-item">
              <xsl:with-param name="resources" select="$positions"/>
              <xsl:with-param name="lprop" select="concat($rdfa:RDF-NS, 'value')"/>
            </xsl:apply-templates>
          </ul>
        </section>
      </xsl:if>
      <xsl:if test="string-length(normalize-space($arguments))">
        <section>
          <h2>Arguments</h2>
          <ul>
            <xsl:apply-templates select="." mode="skos:scheme-item">
              <xsl:with-param name="resources" select="$arguments"/>
              <xsl:with-param name="lprop" select="concat($rdfa:RDF-NS, 'value')"/>
            </xsl:apply-templates>
          </ul>
        </section>
      </xsl:if>
    </article>
  </main>

</xsl:template>

<!-- graph tool space -->

<xsl:template match="html:body" mode="cgto:Space">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:variable name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="focus">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="concat($CGTO, 'focus')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="string-length(normalize-space($focus)) and not(contains(normalize-space($focus), ' '))">
      <!-- congratulations there is exactly one focus -->
      <xsl:apply-templates select="." mode="cgto:show-focus">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite" select="$rewrite"/>
        <xsl:with-param name="main" select="$main"/>
        <xsl:with-param name="heading" select="$heading"/>
        <xsl:with-param name="subject" select="$subject"/>
        <xsl:with-param name="focus" select="$focus"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <!-- there are either zero foci or there are too many -->
      <xsl:apply-templates select="." mode="cgto:select-focus">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite" select="$rewrite"/>
        <xsl:with-param name="main" select="$main"/>
        <xsl:with-param name="heading" select="$heading"/>
        <xsl:with-param name="subject" select="$subject"/>
        <xsl:with-param name="focus" select="$focus"/>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="html:*" mode="cgto:select-focus">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="focus">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="predicate" select="concat($CGTO, 'focus')"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:if test="string-length($focus)">
    <section>
      <p>Resolve the conflict of multiple foci by specifying <em>exactly</em> one focus from those that have been erroneously selected:</p>
      <ul>
        <xsl:apply-templates select="." mode="cgto:focus-item">
          <xsl:with-param name="items" select="$inventory"/>
        </xsl:apply-templates>
      </ul>
    </section>
    <hr/>
 </xsl:if>

  <!-- if it doesn't have a focus, we try to give it one (or make one) -->

  <xsl:variable name="inventory">
    <xsl:variable name="_">
      <xsl:apply-templates select="." mode="rdfa:find-inventories-by-class">
        <xsl:with-param name="subject" select="$subject"/>
        <xsl:with-param name="classes">
          <xsl:value-of select="concat($IBIS, 'Network')"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="concat($SKOS, 'ConceptScheme')"/>
        </xsl:with-param>
      </xsl:apply-templates>
    </xsl:variable>

    <!-- subtract existing foci from the inventory -->
    <xsl:call-template name="str:token-minus">
      <xsl:with-param name="tokens">
        <!-- just grab the raw inventory here; we don't use it elsewhere -->
        <xsl:apply-templates select="." mode="rdfa:find-relations">
          <xsl:with-param name="resources" select="$_"/>
          <xsl:with-param name="predicate" select="concat($DCT, 'hasPart')"/>
        </xsl:apply-templates>
      </xsl:with-param>
      <xsl:with-param name="minus" select="$focus"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:message><xsl:value-of select="$inventory"/></xsl:message>

  <xsl:if test="string-length($inventory)">
    <!-- if there *are* candidates for a focus, offer them for selection -->
    <section>
      <p>Pick a focus from other candidates found in the graph:</p>
      <ul>
        <xsl:apply-templates select="." mode="cgto:focus-item">
          <xsl:with-param name="items" select="$inventory"/>
        </xsl:apply-templates>
      </ul>
    </section>

    <!-- or -->
    <hr/>
  </xsl:if>

  <!-- if there are no candidates for a focus, try to make one -->
  <section>
    <p>Create a new focus:</p>
    <form method="POST" action="" accept-charset="utf-8">
      <input type="hidden" name="$ new $" value="$NEW_UUID_URN"/>
      <input type="hidden" name="cgto:focus : $" value="$new"/>
      <select name="= $new rdf:type :">
        <option value="ibis:Network">Issue Network</option>
        <option value="skos:ConceptScheme">Concept Scheme</option>
      </select>
      <input type="text" name="= $new skos:prefLabel" placeholder="Name of new focus"/>
      <button class="fa fa-plus"></button>
    </form>
  </section>

</xsl:template>

<xsl:template match="html:*" mode="cgto:focus-item">
  <xsl:param name="items">
    <xsl:message terminate="yes">`items` parameter required</xsl:message>
  </xsl:param>

  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$items"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="doc">
    <xsl:call-template name="uri:document-for-uri">
      <xsl:with-param name="uri" select="$first"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="root" select="document($doc)/*"/>

  <xsl:variable name="types">
    <xsl:call-template name="rdfa:make-curie-list">
      <xsl:with-param name="node" select="$root"/>
      <xsl:with-param name="list">
        <xsl:apply-templates select="$root/html:body" mode="rdfa:object-resources">
          <xsl:with-param name="subject" select="$first"/>
          <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
        </xsl:apply-templates>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="label">
    <xsl:apply-templates select="$root/html:body" mode="rdfa:object-literal-quick">
      <xsl:with-param name="subject" select="$first"/>
      <xsl:with-param name="predicate" select="concat($SKOS, 'prefLabel')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="suffix" select="substring-after($label, $rdfa:UNIT-SEP)"/>

  <li about="{$first}" typeof="{$types}">
    <a property="skos:prefLabel" href="{$first}">
      <xsl:choose>
        <xsl:when test="contains($suffix, ':')">
          <xsl:attribute name="datatype"><xsl:value-of select="$suffix"/></xsl:attribute>
        </xsl:when>
        <xsl:when test="string-length($suffix)">
          <xsl:attribute name="xml:lang"><xsl:value-of select="$suffix"/></xsl:attribute>
        </xsl:when>
      </xsl:choose>
    <xsl:value-of select="substring-before($label, $rdfa:UNIT-SEP)"/></a>
    <form method="POST" action="" accept-charset="utf-8">
      <button class="fa fa-equals" name="= cgto:focus :" value="{$first}"/>
    </form>
  </li>

  <xsl:variable name="rest" select="substring-after(normalize-space($items), ' ')"/>

  <xsl:if test="string-length($rest)">
    <xsl:apply-templates select="." mode="cgto:focus-item">
      <xsl:with-param name="items" select="$rest"/>
    </xsl:apply-templates>
  </xsl:if>

</xsl:template>

<xsl:template match="html:*" mode="cgto:show-focus">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="focus">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="concat($CGTO, 'focus')"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:variable name="others">
    <xsl:call-template name="str:token-minus">
      <xsl:with-param name="tokens">
        <xsl:apply-templates select="." mode="rdfa:object-resources">
          <xsl:with-param name="subject" select="$subject"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="predicate" select="concat($SIOC, 'space_of')"/>
        </xsl:apply-templates>
      </xsl:with-param>
      <xsl:with-param name="minus" select="$focus"/>
    </xsl:call-template>
  </xsl:variable>

  <main>
    <nav>
      <xsl:apply-templates select="." mode="cgto:space-cartouche">
        <xsl:with-param name="resources" select="$focus"/>
        <xsl:with-param name="relation" select="'cgto:focus'"/>
      </xsl:apply-templates>
      <xsl:if test="string-length(normalize-space($others))">
        <xsl:apply-templates select="." mode="cgto:space-cartouche">
          <xsl:with-param name="resources" select="$others"/>
          <xsl:with-param name="relation" select="'sioc:space_of'"/>
        </xsl:apply-templates>
      </xsl:if>
    </nav>
  </main>

</xsl:template>

<xsl:template match="html:*" mode="cgto:space-cartouche">
  <xsl:param name="resources">
    <xsl:message terminate="yes">`resources` parameter required</xsl:message>
  </xsl:param>
  <xsl:param name="relation">
    <xsl:message terminate="yes">`relation` parameter required</xsl:message>
  </xsl:param>

  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$resources"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="doc">
    <xsl:call-template name="uri:document-for-uri">
      <xsl:with-param name="uri" select="$first"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="root" select="document($doc)/*"/>

  <xsl:variable name="types">
    <xsl:call-template name="rdfa:make-curie-list">
      <xsl:with-param name="list">
        <xsl:apply-templates select="$root" mode="rdfa:object-resources">
          <xsl:with-param name="subject" select="$first"/>
          <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
        </xsl:apply-templates>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="title" select="$root/html:head/html:title"/>

  <xsl:variable name="entities">
    <xsl:apply-templates select="$root" mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$first"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
    </xsl:apply-templates>
  </xsl:variable>

  <a rel="{$relation}" href="{$first}" typeof="{$types}">
    <h1 property="{$title/@property}"><xsl:value-of select="normalize-space($title)"/></h1>
  </a>

  <xsl:variable name="rest" select="substring-after(normalize-space($resources), ' ')"/>
  <xsl:if test="string-length($rest)">
    <xsl:apply-templates select="." mode="cgto:space-cartouche">
      <xsl:with-param name="resources" select="$rest"/>
      <xsl:with-param name="relation" select="$relation"/>
    </xsl:apply-templates>
  </xsl:if>

</xsl:template>

<!-- -->

<xsl:template match="html:body" mode="cgto:Error">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
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
      <xsl:with-param name="predicate" select="'http://www.w3.org/1999/xhtml/vocab#top'"/>
    </xsl:apply-templates>
  </xsl:variable>

<main>
  <!-- get the title -->
  <h1><xsl:value-of select="../html:head/html:title"/></h1>

  <!-- get all the cgto:Space entities -->

    <!--
        remember we're seeing this "error" because there's either no
        cgto:Space at all in the graph or at least none that are
        attached to the root (and if there are more than one, then *only*
        one is to be designated as the root)

        anyway probably a table?
    -->
    <form method="POST" action="" accept-charset="utf-8">
    <table>
      <thead>
        <tr>
          <th>Space</th>
          <th>Make Active</th>
        </tr>
      </thead>
      <tbody>
        <!-- put the existing ones here -->
        <tr>
          <td>
            <input type="hidden" name="$ new $" value="$NEW_UUID_URN"/>
            <input type="text" name="$new dct:title" placeholder="Give a name for the new space"/>
          </td>
          <td>
            <input type="hidden" name="$new rdf:type :" value="cgto:Space"/>
            <button class="fa fa-plus" name="= $new ci:canonical :" value="{$top}"/>
          </td>
        </tr>
      </tbody>
    </table>
    </form>
  </main>

</xsl:template>

</xsl:stylesheet>
