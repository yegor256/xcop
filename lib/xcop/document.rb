# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'differ'
require 'nokogiri'
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
    differ(ideal, File.read(@path), nocolor: nocolor)
  end

  # Fixes the document, returning +:fixed+ when the file content
  # changed on disk and +:untouched+ when the file was already
  # canonical.
  def fix
    canonical = ideal
    return :untouched if canonical == File.read(@path)
    File.write(@path, canonical)
    :fixed
  end

  # Validates the document against its declared XSD schema, if any.
  # Returns an array of error message strings (empty when valid or no
  # schema declared); a declared but missing schema is itself an error.
  def validate
    xml = Nokogiri::XML(File.open(@path))
    xsd = schema(xml)
    return [] unless xsd
    return ["schema file is absent at #{xsd}"] unless File.exist?(xsd)
    Nokogiri::XML::Schema(File.read(xsd)).validate(xml).map(&:message)
  end

  XSI_NS = 'http://www.w3.org/2001/XMLSchema-instance'.freeze

  private

  # The canonical, well-formatted version of the document.
  def ideal
    xml = Nokogiri::XML(File.open(@path), &:noblanks)
    text = xml.to_xml(indent: 2)
    unused(xml).each do |prefix|
      text =
        if prefix.nil?
          text.gsub(/\s+xmlns="[^"]*"/, '')
        else
          text.gsub(/\s+xmlns:#{Regexp.escape(prefix)}="[^"]*"/, '')
        end
    end
    Nokogiri::XML(text, &:noblanks).to_xml(indent: 2)
  end

  # Returns the set of namespace prefixes that are declared in +xml+
  # but never referenced by any element or attribute. A +nil+ entry in
  # the set represents the default namespace.
  def unused(xml)
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

  def schema(xml)
    root = xml.root
    return unless root
    plain = root.at_xpath('@xsi:noNamespaceSchemaLocation', 'xsi' => XSI_NS)
    mapped = root.at_xpath('@xsi:schemaLocation', 'xsi' => XSI_NS)
    location =
      if plain
        plain.value
      elsif mapped
        mapped.value.split.last
      end
    return unless location
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
