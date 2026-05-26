# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'differ'
require 'rainbow'
require 'set'
require_relative 'version'

# One document.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2026 Yegor Bugayenko
# License:: MIT
class Xcop::Document
  # Ctor.
  # +path+:: Path of it
  def initialize(path)
    @path = path
  end

  # Return the difference, if any (empty string if everything is clean).
  def diff(nocolor: false)
    now = File.read(@path, encoding: Encoding::UTF_8)
    differ(ideal, now, nocolor: nocolor)
  end

  # Fixes the document.
  def fix
    File.write(@path, ideal)
  end

  # Validates the document against its declared XSD schema, if any.
  # Returns an array of error message strings (empty when valid or no schema declared).
  def validate
    xml = Nokogiri::XML(File.open(@path))
    schema_path = xsd_schema_path(xml)
    return [] unless schema_path
    return [] unless File.exist?(schema_path)
    Nokogiri::XML::Schema(File.read(schema_path)).validate(xml).map(&:message)
  end

  XSI_NS = 'http://www.w3.org/2001/XMLSchema-instance'.freeze

  private

  # The canonical, well-formatted version of the document.
  def ideal
    xml = Nokogiri::XML(File.open(@path), &:noblanks)
    missing_encoding = xml.encoding.nil?
    text = xml_to_text(xml, missing_encoding)
    unused_namespace_prefixes(xml).each do |prefix|
      text =
        if prefix.nil?
          text.gsub(/\s+xmlns="[^"]*"/, '')
        else
          text.gsub(/\s+xmlns:#{Regexp.escape(prefix)}="[^"]*"/, '')
        end
    end
    xml_to_text(Nokogiri::XML(text, &:noblanks), missing_encoding)
  end

  def xml_to_text(xml, missing_encoding)
    return xml.to_xml(indent: 2) unless missing_encoding
    xml.to_xml(indent: 2, encoding: 'UTF-8').sub(
      /^<\?xml version="1\.0" encoding="UTF-8"\?>/,
      '<?xml version="1.0"?>'
    )
  end

  # Returns the set of namespace prefixes that are declared in +xml+
  # but never referenced by any element or attribute. A +nil+ entry in
  # the set represents the default namespace.
  def unused_namespace_prefixes(xml)
    used = Set.new
    declared = Set.new
    xml.traverse do |node|
      next unless node.is_a?(Nokogiri::XML::Element)
      used << node.namespace.prefix if node.namespace
      node.attribute_nodes.each do |attr|
        used << attr.namespace.prefix if attr.namespace
      end
      node.namespace_definitions.each { |ns| declared << ns.prefix }
    end
    declared - used
  end

  def xsd_schema_path(xml)
    root = xml.root
    return nil unless root
    no_ns = root.at_xpath('@xsi:noNamespaceSchemaLocation', 'xsi' => XSI_NS)
    with_ns = root.at_xpath('@xsi:schemaLocation', 'xsi' => XSI_NS)
    location =
      if no_ns
        no_ns.value
      elsif with_ns
        with_ns.value.split.last
      end
    return nil unless location
    File.expand_path(location, File.dirname(@path))
  end

  def differ(ideal, fact, nocolor: false)
    return '' if ideal == fact
    if nocolor
      Differ.diff_by_line(ideal, fact).to_s
    else
      Differ.format = :color
      Differ.diff_by_line(schars(ideal), schars(fact)).to_s
    end
  end

  def schars(text)
    text.gsub("\n", "\\n\n")
  end
end
