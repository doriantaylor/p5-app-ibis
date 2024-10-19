<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:html="http://www.w3.org/1999/xhtml"
		xmlns:ibis="https://vocab.methodandstructure.com/ibis#"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#"
		xmlns:cgto="https://vocab.methodandstructure.com/graph-tool#"
		xmlns:x="urn:x-dummy:"
                xmlns:rdfa="http://www.w3.org/ns/rdfa#"
                xmlns:xc="https://makethingsmakesense.com/asset/transclude#"
                xmlns:str="http://xsltsl.org/string"
                xmlns:uri="http://xsltsl.org/uri"
		xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="html str uri rdfa xc x">

<xsl:import href="cgto"/>

<x:doc>
  <h1>SKOS/IBIS UI</h1>
  <p>This stylesheet transforms markup specific to SKOS and IBIS.</p>
</x:doc>

<xsl:variable name="RDFS" select="'http://www.w3.org/2000/01/rdf-schema#'"/>
<xsl:variable name="IBIS" select="'https://vocab.methodandstructure.com/ibis#'"/>
<xsl:variable name="CGTO" select="'https://vocab.methodandstructure.com/graph-tool#'"/>
<xsl:variable name="BIBO" select="'http://purl.org/ontology/bibo/'"/>
<xsl:variable name="DCT"  select="'http://purl.org/dc/terms/'"/>
<xsl:variable name="QB"   select="'http://purl.org/linked-data/cube#'"/>
<xsl:variable name="SIOC" select="'http://rdfs.org/sioc/ns#'"/>
<xsl:variable name="SKOS" select="'http://www.w3.org/2004/02/skos/core#'"/>
<xsl:variable name="XHV"  select="'http://www.w3.org/1999/xhtml/vocab#'"/>

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

<!-- -->

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
  <xsl:apply-templates select="." mode="skos:footer">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="heading"       select="$heading"/>
    <xsl:with-param name="subject"       select="$subject"/>
  </xsl:apply-templates>
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
    <xsl:apply-templates select="." mode="cgto:find-indices">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="origins" select="concat($subject, ' ', $top)"/>
      <xsl:with-param name="relations" select="concat($CGTO, 'by-class')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="inventories">
    <xsl:apply-templates select="." mode="cgto:find-inventories-by-class">
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
        <xsl:with-param name="predicate" select="concat($DCT, 'hasPart')"/>
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

  <xsl:apply-templates select="." mode="skos:referenced-by-inset">
    <xsl:with-param name="base" select="$base"/>
    <xsl:with-param name="subject" select="$subject"/>
  </xsl:apply-templates>

  <xsl:apply-templates select="." mode="skos:object-form">
    <xsl:with-param name="base" select="$base"/>
    <xsl:with-param name="subject" select="$subject"/>
  </xsl:apply-templates>

</xsl:template>

<xsl:template match="html:*" mode="skos:referenced-by-inset">
  <aside>
    <h5>Referenced By</h5>
  </aside>
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
      <xsl:apply-templates select="." mode="ibis:add-relation">
        <xsl:with-param name="base"    select="$base"/>
        <xsl:with-param name="current" select="$current"/>
        <xsl:with-param name="subject" select="$subject"/>
      </xsl:apply-templates>
      <xsl:if test="normalize-space($targets)">
      <ul about="" rel="{$curie}">
        <xsl:apply-templates select="$current" mode="ibis:link-stack">
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

<xsl:template match="x:prop" mode="ibis:add-relation">
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
    <xsl:variable name="top">
      <xsl:apply-templates select="$current" mode="rdfa:object-resources">
        <xsl:with-param name="subject" select="$subject"/>
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="predicate" select="'http://www.w3.org/1999/xhtml/vocab#top'"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="_">
      <xsl:apply-templates select="document($top)/*" mode="rdfa:object-resources">
	<!--<xsl:with-param name="subject" select="$top"/>-->
	<!--<xsl:with-param name="base" select="$base"/>-->
	<xsl:with-param name="predicate" select="concat($CGTO, 'focus')"/>
      </xsl:apply-templates>
    </xsl:variable>
    <!--
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
    </xsl:variable>-->
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$_"/>
    </xsl:call-template>
  </xsl:variable>

  <!--<xsl:message>SCHEME <xsl:value-of select="$scheme"/></xsl:message>-->

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
    <input tabindex="{count(x:range)}" type="text" name="$ label" list="big-friggin-list" autocomplete="off"/>
  </form>
</xsl:template>

<xsl:template match="*" mode="ibis:link-stack">
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
      <xsl:apply-templates select="." mode="ibis:link-stack">
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

  <xsl:apply-templates select="." mode="skos:footer">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="heading"       select="$heading"/>
    <xsl:with-param name="subject"       select="$subject"/>
  </xsl:apply-templates>
</xsl:template>

<x:doc>
  <h2>skos:footer</h2>
  <p>This is a UI component for <code>skos:Concept</code> (i.e. <code>ibis:Entity</code>)-derived subjects, as well as <code>skos:ConceptScheme</code>/<code>ibis:Network</code> aggregates.</p>
  <p>If it's a concept or derivative thereof (I should really change <code>ibis:Entity</code> to <code>ibis:Statement</code>), it has to first find the <em>scheme</em> it belongs to (via <code>skos:inScheme</code>, <code>skos:topConceptOf</code>, or its inverse, <code>skos:hasTopConcept</code>), otherwise we are currently looking at the scheme.</p>
  <p>We then have to determine if the scheme is in <em>focus</em>. For this we first find the <code>xhv:top</code> (at least for now; I may come up with a better one later) relative to the scheme.</p>
  <aside role="note">
    <p>Note that there is nothing preventing a conceptual entity from belonging to zero schemes, or belonging to more than one scheme. There is furthermore nothing preventing none of the associated schemes from being in focus, although having more than one scheme in focus is an error. (This is partly why I have to change the focus mechanism from being relative to the <em>space</em>, to being relative to the <em>user</em>, not only because it can potentially get into this state in a multiuser system, but also because people will be continually clobbering each other's focus.)</p>
    <p>If a concept belongs to zero schemes, we should throw up a modal to force the user to pick a scheme. We should default to the scheme in focus. If there are other schemes present, we should provide an option to set the focus as well as attach the concept. We should provide a mechanism to create a new scheme (which we assume will attach the concept). There should be an option (default?) to focus a new scheme.</p>
  </aside>
  <p>A concept attached to multiple schemes needs UI to be able to detach from one scheme, but only if there are multiples.</p>
  <p>A concept should also be able to import all of its neighbours into the scheme</p>
  <section>
    <h3>Concept UI</h3>
    <ul>
      <li>
	<p>flyout list of all schemes</p>
	<ul>
	  <li>participating scheme(s) gathered at the top</li>
	  <li>focused scheme at the tippy-top/closed position (if participating)</li>
	  <li>then non-participating schemes, whether focused or not</li>
	  <li>each has a link to the scheme itself</li>
	  <li>unfocused schemes have a set focus button</li>
	  <li>non-participating schemes have attach+set focus, attach+no-focus buttons as well</li>
	</ul>
      </li>
      <li>
	<p>create new scheme UI</p>
	<ul>
	  <li>text box for name</li>
	  <li>attach concept?</li>
	  <li>if current subject is <em>not</em> an <code>ibis:Entity</code>, provide toggle between <code>skos:ConceptScheme</code> and <code>ibis:Network</code></li>
	  <li>go to</li>
	  <li>set focus</li>
	</ul>
      </li>
    </ul>
  </section>
  <section>
    <h3>Scheme UI</h3>
    <ul>
      <li>schemes do not have to worry about attaching concepts, so when the subject location is a scheme, there is only the matter of navigating to another one of the listed schemes, or otherwise focusing it (and presumably navigating to it as well).</li>
      <li>in other words the scheme UI is the same as the concept UI minus all the <em>attach</em> business.</li>
    </ul>
  </section>
</x:doc>

<xsl:template match="html:*" mode="skos:footer">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:param name="type">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="predicate" select="$rdfa:RDF-TYPE"/>
    </xsl:apply-templates>
  </xsl:param>

  <xsl:variable name="space">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$subject"/>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="predicate" select="concat($XHV, 'top')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <xsl:variable name="scheme-xx">
    <xsl:variable name="_">
      <xsl:call-template name="str:token-intersection">
	<xsl:with-param name="left" select="$type"/>
	<xsl:with-param name="right" select="concat($IBIS, 'Network ', $SKOS, 'ConceptScheme')"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="normalize-space($_)"/>
  </xsl:variable>
  <xsl:variable name="is-scheme" select="string-length($scheme-xx) != 0"/>

  <xsl:variable name="attached">
    <xsl:if test="not($is-scheme)">
	<!--
	    make it possible to list/switch current ibis:Network/skos:ConceptScheme:

            * find the intersection of skos:inScheme skos:topConceptOf ^skos:hasTopConcept
	    * perform some sort of tiebreaking if there are more than one
	    * eg the one that is in focus (of which there should be only one) should take precedence
	    * otherwise an ibis network should take precedence over a skos concept scheme
	    * otherwise ???
	-->
      <xsl:variable name="_">
	<xsl:apply-templates select="." mode="rdfa:object-resources">
          <xsl:with-param name="subject" select="$subject"/>
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="predicate" select="concat($SKOS, 'inScheme')"/>
	</xsl:apply-templates>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="." mode="rdfa:object-resources">
          <xsl:with-param name="subject" select="$subject"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="predicate" select="concat($SKOS, 'topConceptOf')"/>
	</xsl:apply-templates>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="." mode="rdfa:subject-resources">
          <xsl:with-param name="object" select="$subject"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="predicate" select="concat($SKOS, 'hasTopConcept')"/>
	</xsl:apply-templates>
      </xsl:variable>
      <xsl:call-template name="str:unique-tokens">
	<xsl:with-param name="string" select="normalize-space($_)"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="focus">
    <xsl:apply-templates select="document($space)/*" mode="rdfa:object-resources">
      <xsl:with-param name="subject" select="$space"/>
      <xsl:with-param name="predicate" select="concat($CGTO, 'focus')"/>
    </xsl:apply-templates>
  </xsl:variable>

  <!--
      * provide some kind of ui for creating a new ibis:Network/skos:ConceptScheme
      * make setting the cgto:focus optional (default??)
  -->
  <xsl:variable name="schemes">
    <xsl:variable name="_">
     <xsl:apply-templates select="document($space)/*" mode="cgto:find-inventories-by-class">
       <xsl:with-param name="classes">
         <xsl:value-of select="concat($IBIS, 'Network ', $SKOS, 'ConceptScheme')"/>
       </xsl:with-param>
     </xsl:apply-templates>
    </xsl:variable>
    <xsl:apply-templates select="." mode="rdfa:find-relations">
      <xsl:with-param name="resources" select="$_"/>
      <xsl:with-param name="predicate" select="concat($DCT, 'hasPart')"/>
    </xsl:apply-templates>
  </xsl:variable>


  <footer>
    <form>
      <button type="button" id="scheme-collapsed">
      <xsl:call-template name="skos:scheme-collapsed-item">
	<xsl:with-param name="schemes"    select="$attached"/>
	<xsl:with-param name="focus"      select="$focus"/>
      </xsl:call-template>
      </button>
    </form>
    <ul id="scheme-list" class="schemes">
      <xsl:call-template name="skos:scheme-item">
	<xsl:with-param name="schemes"    select="$schemes"/>
	<xsl:with-param name="attached"   select="$attached"/>
	<xsl:with-param name="focus"      select="$focus"/>
	<xsl:with-param name="space"      select="$space"/>
	<xsl:with-param name="is-concept" select="not($is-scheme)"/>
      </xsl:call-template>
      <li>
    <form class="new-scheme" method="POST" action="">
      <input type="hidden" name="$ SUBJECT $" value="$NEW_UUID_URN"/>
      <xsl:choose>
	<xsl:when test="false()">
	  <label><input name="= rdf:type :" type="radio" value="ibis:Network" checked="checked"/> IBIS Network</label>
	  <xsl:text>&#xa0;</xsl:text>
	  <label><input name="= rdf:type :" value="skos:ConceptScheme" type="radio"/> SKOS Concepts</label>
	</xsl:when>
	<xsl:otherwise>
	  <input type="hidden" name="= rdf:type :" value="ibis:Network"/>
	</xsl:otherwise>
      </xsl:choose>
      <input type="text" name="= skos:prefLabel" placeholder="Name&#x2026;"/>
      <xsl:if test="false()">
	<label><input type="checkbox" name="! skos:inScheme :" value="{$subject}"/> Import this entity</label>
      </xsl:if>
      <button>Create</button>
      <button name="= {$space} cgto:focus :" value="$SUBJECT">+ Focus</button>
    </form>
      </li>
    </ul>
  </footer>
</xsl:template>

<x:doc>
  <h2>skos:scheme-item-label</h2>
  <p>this is just a plain list</p>
</x:doc>

<xsl:template name="skos:scheme-item-label">
  <xsl:param name="subject" select="''"/>
  <xsl:param name="is-focused" select="false()"/>

  <xsl:variable name="doc" select="document($subject)/*"/>
  <!-- get label shenanigans -->
  <xsl:variable name="label-raw">
    <xsl:apply-templates select="$doc" mode="skos:object-form-label">
      <xsl:with-param name="subject" select="$subject"/>
    </xsl:apply-templates>
  </xsl:variable>
  <xsl:variable name="label-prop" select="substring-before($label-raw, ' ')"/>
  <xsl:variable name="label-val" select="substring-after($label-raw, ' ')"/>
  <xsl:variable name="label" select="substring-before($label-val, $rdfa:UNIT-SEP)"/>
  <xsl:variable name="label-type">
    <xsl:if test="not(starts-with(substring-after($label-val, $rdfa:UNIT-SEP), '@'))">
      <xsl:value-of select="substring-after($label-val, $rdfa:UNIT-SEP)"/>
    </xsl:if>
  </xsl:variable>
  <xsl:variable name="label-lang">
    <xsl:if test="starts-with(substring-after($label-val, $rdfa:UNIT-SEP), '@')">
      <xsl:value-of select="substring-after($label-val, concat($rdfa:UNIT-SEP, ' '))"/>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="span">
    <xsl:choose>
      <xsl:when test="$is-focused">strong</xsl:when>
      <xsl:otherwise>span</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:element name="{$span}">
    <xsl:if test="$label-prop">
      <xsl:attribute name="property">
	<xsl:value-of select="$label-prop"/>
      </xsl:attribute>
      <xsl:if test="$label-type">
	<xsl:attribute name="datatype"><xsl:value-of select="$label-type"/></xsl:attribute>
      </xsl:if>
      <xsl:if test="$label-lang">
	<xsl:attribute name="xml:lang"><xsl:value-of select="$label-lang"/></xsl:attribute>
      </xsl:if>
    </xsl:if>
    <xsl:value-of select="$label"/>
  </xsl:element>
</xsl:template>

<x:doc>
  <h2>skos:scheme-collapsed-item</h2>
  <p>this is just a plain list</p>
</x:doc>

<xsl:template name="skos:scheme-collapsed-item">
  <xsl:param name="schemes" select="''"/>
  <xsl:param name="focus"   select="''"/>

  <xsl:variable name="first">
    <xsl:choose>
      <xsl:when test="string-length(normalize-space($focus)) and contains(concat(' ', $focus, ' '), concat(' ', $schemes, ' '))">
	<xsl:value-of select="normalize-space($focus)"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="str:safe-first-token">
	  <xsl:with-param name="tokens" select="$schemes"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="is-focused" select="normalize-space($focus) = $first"/>

  <xsl:variable name="rest">
    <xsl:choose>
      <xsl:when test="$is-focused">
	<xsl:call-template name="str:token-minus">
	  <xsl:with-param name="tokens" select="$schemes"/>
	  <xsl:with-param name="minus" select="$first"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="substring-after(normalize-space($schemes), ' ')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:if test="string-length($first)">
    <xsl:call-template name="skos:scheme-item-label">
      <xsl:with-param name="subject" select="$first"/>
      <xsl:with-param name="is-focused" select="$is-focused"/>
    </xsl:call-template>

    <xsl:if test="string-length($rest)">
      <xsl:text>, </xsl:text>
      <xsl:call-template name="skos:scheme-collapsed-item">
	<xsl:with-param name="schemes" select="$rest"/>
	<xsl:with-param name="focus" select="$focus"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:if>
</xsl:template>

<x:doc>
  <h2>skos:scheme-item</h2>
  <p>okay so this is supposed consume a space-delimited queue of addresses recursively and produce a list of things.</p>
  <p>it needs to know</p>
</x:doc>

<xsl:template name="skos:scheme-item">
  <xsl:param name="schemes"  select="''"/>
  <xsl:param name="attached" select="''"/>
  <xsl:param name="focus"    select="''"/>
  <xsl:param name="space">
    <xsl:message terminate="yes">`space` parameter required</xsl:message>
  </xsl:param>
  <xsl:param name="is-concept" select="false()"/>

  <xsl:variable name="snorm" select="normalize-space($schemes)"/>

  <xsl:variable name="first">
    <xsl:call-template name="str:safe-first-token">
      <xsl:with-param name="tokens" select="$snorm"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="string-length($first)">
    <xsl:variable name="scheme-doc" select="document($first)/*"/>

    <!-- test if attached -->
    <xsl:variable name="attach-intersection">
      <xsl:call-template name="str:token-intersection">
	<xsl:with-param name="left" select="$first"/>
	<xsl:with-param name="right" select="$attached"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="is-attached" select="string-length($attach-intersection)"/>

    <li>
      <a href="{$first}">
	<xsl:if test="$is-attached">
	  <xsl:attribute name="rel">skos:inScheme</xsl:attribute>
	</xsl:if>
	<xsl:call-template name="skos:scheme-item-label">
	  <xsl:with-param name="subject" select="$first"/>
	  <xsl:with-param name="is-focused" select="$first = $focus"/>
	</xsl:call-template>
      </a>
      <!-- 'set focus' button (if not focused, unconditional) -->
      <form method="POST" action="">
	<xsl:if test="$is-concept">
	  <!-- 'detach' button if attached -->
	  <xsl:choose>
	    <xsl:when test="$is-attached">
	      <button name="- skos:inScheme :" value="{$first}">Detach</button>
	    </xsl:when>
	    <xsl:otherwise>
	      <button name="skos:inScheme :" value="{$first}">Attach</button>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:if>
	<xsl:if test="$first != $focus">
	  <button name="= {$space} cgto:focus :" value="{$first}">Set Focus</button>
	</xsl:if>
      </form>
    </li>

    <xsl:variable name="rest" select="normalize-space(substring-after($snorm, ' '))"/>
    <xsl:if test="string-length($rest)">
      <xsl:call-template name="skos:scheme-item">
	<xsl:with-param name="schemes"    select="$rest"/>
	<xsl:with-param name="attached"   select="$attached"/>
	<xsl:with-param name="focus"      select="$focus"/>
	<xsl:with-param name="space"      select="$space"/>
	<xsl:with-param name="is-concept" select="$is-concept"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:if>

</xsl:template>

<xsl:template match="html:*" mode="skos:footer-option">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="candidates">
    <xsl:message terminate="yes">`candidates` parameter required</xsl:message>
  </xsl:param>
  <xsl:param name="selected">
    <xsl:message terminate="yes">`selected` parameter required</xsl:message>
  </xsl:param>

  <xsl:variable name="cnorm" select="normalize-space($candidates)"/>

  <xsl:if test="string-length($cnorm)">
    <xsl:variable name="first">
      <xsl:choose>
	<xsl:when test="contains($cnorm, ' ')">
	  <xsl:value-of select="substring-before($cnorm, ' ')"/>
	</xsl:when>
	<xsl:otherwise><xsl:value-of select="$cnorm"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="label-raw">
      <xsl:apply-templates select="." mode="skos:object-form-label">
	<xsl:with-param name="subject" select="$first"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="label-prop" select="substring-before($label-raw, ' ')"/>
    <xsl:variable name="label-val" select="substring-after($label-raw, ' ')"/>
    <xsl:variable name="label" select="substring-before($label-val, $rdfa:UNIT-SEP)"/>
    <xsl:variable name="label-type">
      <xsl:if test="not(starts-with(substring-after($label-val, $rdfa:UNIT-SEP), '@'))">
	<xsl:value-of select="substring-after($label-val, $rdfa:UNIT-SEP)"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="label-lang">
      <xsl:if test="starts-with(substring-after($label-val, $rdfa:UNIT-SEP), '@')">
	<xsl:value-of select="substring-after($label-val, concat($rdfa:UNIT-SEP, ' '))"/>
      </xsl:if>
    </xsl:variable>

    <option about="{$first}" value="{$first}">
      <xsl:if test="$selected and $first = $selected">
	<xsl:attribute name="selected"></xsl:attribute>
      </xsl:if>
      <xsl:if test="$label-prop">
	<xsl:attribute name="property">
	  <xsl:value-of select="$label-prop"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:value-of select="$label"/>
    </option>

    <xsl:variable name="rest" select="substring-after($cnorm, ' ')"/>
    <xsl:if test="$rest">
      <xsl:apply-templates select="." mode="skos:footer-option">
	<xsl:with-param name="base" select="$base"/>
	<xsl:with-param name="candidates" select="$rest"/>
	<xsl:with-param name="selected" select="$selected"/>
      </xsl:apply-templates>
      </xsl:if>
    </xsl:if>
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
<xsl:apply-templates select="." mode="skos:literal-form">
  <xsl:with-param name="base" select="$base"/>
  <xsl:with-param name="subject" select="$subject"/>
</xsl:apply-templates>
<xsl:apply-templates select="." mode="skos:literal-form">
  <xsl:with-param name="base" select="$base"/>
  <xsl:with-param name="subject" select="$subject"/>
  <xsl:with-param name="predicate" select="concat($SKOS, 'hiddenLabel')"/>
  <xsl:with-param name="heading" select="'Hidden Labels'"/>
</xsl:apply-templates>
<xsl:apply-templates select="." mode="skos:object-form">
  <xsl:with-param name="base" select="$base"/>
  <xsl:with-param name="subject" select="$subject"/>
</xsl:apply-templates>

</xsl:template>

<xsl:template match="html:*" mode="skos:literal-form">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="predicate" select="concat($SKOS, 'altLabel')"/>
  <xsl:param name="heading" select="'Alternate Labels'"/>

  <xsl:variable name="literals">
    <xsl:apply-templates select="." mode="rdfa:object-literals">
      <xsl:with-param name="subject"   select="$subject"/>
      <xsl:with-param name="base"      select="$base"/>
      <xsl:with-param name="predicate" select="$predicate"/>
    </xsl:apply-templates>
  </xsl:variable>

  <!--<xsl:message><xsl:value-of select="$literals"/></xsl:message>-->

  <aside>
    <h5><xsl:value-of select="$heading"/></h5>
    <ul>
      <xsl:apply-templates select="." mode="skos:literal-form-entry">
        <xsl:with-param name="predicate" select="$predicate"/>
        <xsl:with-param name="literals"    select="$literals"/>
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

<xsl:template match="html:*" mode="skos:literal-form-entry">
  <xsl:param name="predicate"/>
  <xsl:param name="literals"/>

  <xsl:variable name="first">
    <xsl:choose>
      <xsl:when test="contains($literals, $rdfa:RECORD-SEP)">
        <xsl:value-of select="substring-before($literals, $rdfa:RECORD-SEP)"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$literals"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:if test="string-length($first)">
    <xsl:variable name="value" select="substring-before($first, $rdfa:UNIT-SEP)"/>
    <xsl:variable name="lang-or-dt" select="substring-after($first, $rdfa:UNIT-SEP)"/>
    <xsl:variable name="language">
      <xsl:if test="starts-with($lang-or-dt, '@')">
        <xsl:value-of select="substring-after(normalize-space($lang-or-dt), '@')"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="datatype">
      <xsl:if test="not(string-length($language))">
	<xsl:value-of select="$lang-or-dt"/>
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

    <xsl:variable name="rest" select="substring-after($literals, $rdfa:RECORD-SEP)"/>
    <xsl:if test="string-length($rest)">
      <xsl:apply-templates select="." mode="skos:literal-form-entry">
        <xsl:with-param name="predicate" select="$predicate"/>
        <xsl:with-param name="literals" select="$rest"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:if>
</xsl:template>

<xsl:template match="html:*" mode="skos:object-form">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="subject">
    <xsl:apply-templates select="." mode="rdfa:get-subject">
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="debug" select="false()"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="predicate" select="concat($RDFS, 'seeAlso')"/>
  <xsl:param name="heading" select="'See Also'"/>

  <xsl:variable name="objects">
    <xsl:apply-templates select="." mode="rdfa:object-resources">
      <xsl:with-param name="subject"   select="$subject"/>
      <xsl:with-param name="base"      select="$base"/>
      <xsl:with-param name="predicate" select="$predicate"/>
    </xsl:apply-templates>
  </xsl:variable>

  <!--<xsl:message><xsl:value-of select="$labels"/></xsl:message>-->

  <aside>
    <h5><xsl:value-of select="$heading"/></h5>
    <ul>
      <xsl:apply-templates select="." mode="skos:object-form-entry">
        <xsl:with-param name="predicate" select="$predicate"/>
        <xsl:with-param name="objects"    select="$objects"/>
      </xsl:apply-templates>
      <li>
        <form method="POST" action="" accept-charset="utf-8">
          <input type="text" name="{$predicate} :"/>
          <button class="fa fa-plus"/>
        </form>
      </li>
    </ul>
  </aside>
</xsl:template>

<xsl:template match="html:*" mode="skos:object-form-entry">
  <xsl:param name="predicate"/>
  <xsl:param name="objects"/>

  <xsl:variable name="o" select="normalize-space($objects)"/>

  <xsl:variable name="first">
    <xsl:choose>
      <xsl:when test="contains($o, ' ')">
        <xsl:value-of select="substring-before($o, ' ')"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$o"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:if test="string-length($first)">
    <xsl:variable name="label">
      <xsl:variable name="_">
	<xsl:apply-templates select="." mode="skos:object-form-label">
	  <xsl:with-param name="subject" select="$first"/>
	</xsl:apply-templates>
      </xsl:variable>
      <xsl:value-of select="normalize-space($_)"/>
    </xsl:variable>
    <li>
      <form method="POST" action="" accept-charset="utf-8">
	<a rel="{$predicate}" href="{$first}">
	  <xsl:choose>
	    <xsl:when test="string-length($label)">
	      <xsl:variable name="raw" select="substring-after($label, ' ')"/>
	      <xsl:variable name="literal" select="substring-before($raw, $rdfa:UNIT-SEP)"/>
	      <xsl:variable name="dt" select="substring-after($raw, $rdfa:UNIT-SEP)"/>
	      <span property="{substring-before($label, ' ')}">
		<xsl:choose>
		  <xsl:when test="starts-with($dt, '@')">
		    <xsl:attribute name="xml:lang"><xsl:value-of select="$dt"/></xsl:attribute>
		  </xsl:when>
		  <xsl:otherwise>
		    <xsl:attribute name="datatype"><xsl:value-of select="$dt"/></xsl:attribute>
		  </xsl:otherwise>
		</xsl:choose>
	      <xsl:value-of select="$literal"/></span>
	    </xsl:when>
	    <xsl:otherwise><xsl:value-of select="$first"/></xsl:otherwise>
	  </xsl:choose>
	</a>
	<button class="disconnect fa fa-times" name="- {$predicate} :" value="{$first}"></button>
      </form>
    </li>
    <xsl:variable name="rest" select="substring-after($o, ' ')"/>
    <xsl:if test="string-length($rest)">
      <xsl:apply-templates select="." mode="skos:object-form-entry">
        <xsl:with-param name="predicate" select="$predicate"/>
        <xsl:with-param name="objects" select="$rest"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:if>
</xsl:template>

<xsl:template match="html:*" mode="skos:object-form-label">
  <xsl:param name="subject"/>
  <xsl:param name="predicates" select="document('')/xsl:stylesheet/x:lprops/x:prop/@uri"/>

  <xsl:if test="count($predicates)">
    <!--<xsl:message>PREDICATE LOL <xsl:value-of select="concat($subject, ' ', $predicates[1])"/></xsl:message>-->
    <xsl:variable name="out">
      <xsl:apply-templates select="." mode="rdfa:object-literal-quick">
	<xsl:with-param name="subject" select="$subject"/>
	<xsl:with-param name="predicate" select="normalize-space($predicates[1])"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length(normalize-space($out))">
	<!--<xsl:message>FOUND <xsl:value-of select="$out"/></xsl:message>-->
	<xsl:value-of select="concat($predicates[1], ' ', $out)"/>
      </xsl:when>
      <xsl:when test="count($predicates[position() &gt; 1])">
	<xsl:apply-templates select="." mode="skos:object-form-label">
	  <xsl:with-param name="subject" select="$subject"/>
	  <xsl:with-param name="predicates" select="$predicates[position() &gt; 1]"/>
	</xsl:apply-templates>
      </xsl:when>
    </xsl:choose>
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
  <xsl:apply-templates select="." mode="skos:footer">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="heading"       select="$heading"/>
    <xsl:with-param name="subject"       select="$subject"/>
  </xsl:apply-templates>
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

  <xsl:variable name="concepts">
    <xsl:apply-templates select="." mode="rdfa:filter-by-type">
      <xsl:with-param name="subjects" select="$adjacents"/>
      <xsl:with-param name="class" select="concat($SKOS, 'Concept')"/>
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
          <h3>Issues</h3>
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
          <h3>Positions</h3>
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
          <h3>Arguments</h3>
          <ul>
            <xsl:apply-templates select="." mode="skos:scheme-item">
              <xsl:with-param name="resources" select="$arguments"/>
              <xsl:with-param name="lprop" select="concat($rdfa:RDF-NS, 'value')"/>
            </xsl:apply-templates>
          </ul>
        </section>
      </xsl:if>
      <section>
        <h3>Concepts</h3>
        <form method="POST" action="" accept-charset="utf-8">
          <input type="hidden" name="$ SUBJECT $" value="$NEW_UUID_URN"/>
          <input type="hidden" name="skos:inScheme :" value="{$subject}"/>
          <input type="hidden" name="rdf:type :" value="skos:Concept"/>
          <input type="text" name="= skos:prefLabel"/>
          <button class="fa fa-plus"/>
        </form>
        <xsl:if test="string-length(normalize-space($concepts))">
          <ul>
            <xsl:apply-templates select="." mode="skos:scheme-item">
              <xsl:with-param name="resources" select="$concepts"/>
              <xsl:with-param name="lprop" select="concat($SKOS, 'prefLabel')"/>
            </xsl:apply-templates>
          </ul>
        </xsl:if>
      </section>
    </article>
    <figure id="force" class="aside"/>
  </main>
  <xsl:apply-templates select="." mode="skos:footer">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="heading"       select="$heading"/>
    <xsl:with-param name="subject"       select="$subject"/>
  </xsl:apply-templates>
</xsl:template>

</xsl:stylesheet>
