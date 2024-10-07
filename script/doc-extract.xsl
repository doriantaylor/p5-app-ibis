<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:html="http://www.w3.org/1999/xhtml"
		xmlns:x="urn:x-dummy:"
		xmlns="http://www.w3.org/1999/xhtml"
		exclude-result-prefixes="html x xsl">

  <xsl:output method="html" media-type="application/xhtml+xml" indent="yes"/>

  <xsl:template match="/">
    <html>
      <head>
	<title/>
      </head>
      <body>
	<xsl:apply-templates select="xsl:stylesheet/x:doc"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="x:doc">
    <xsl:apply-templates select="html:*"/>
  </xsl:template>

  <xsl:template match="html:section">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="html:aside[@role='note']">
    <blockquote>
      <xsl:apply-templates/>
    </blockquote>
  </xsl:template>

  <xsl:template match="html:*">
    <xsl:element name="{local-name()}">
      <xsl:for-each select="@*">
	<xsl:attribute name="{name()}">
	  <xsl:value-of select="."/>
	</xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
