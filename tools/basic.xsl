<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:gen="dummy-namespace-for-the-generated-xslt">

  <xsl:namespace-alias stylesheet-prefix="gen" result-prefix="xsl"/>
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <gen:stylesheet version="1.0">
      <gen:output method="xml" indent="yes"/>
      <gen:template match="@*|node()">
        <gen:copy>
          <gen:apply-templates select="@*|node()"/>
        </gen:copy>
      </gen:template>

      <gen:template match="//override"/>

      <xsl:apply-templates/>
    </gen:stylesheet>
  </xsl:template>

  <xsl:template match="text()"/>

  <xsl:template match="//override">
    <gen:template>
      <xsl:attribute name="match"><xsl:value-of select="@xpath"/></xsl:attribute>
      <xsl:copy-of select="node()/."/>
    </gen:template>
  </xsl:template>

</xsl:stylesheet>