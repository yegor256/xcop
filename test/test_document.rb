# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'nokogiri'
require 'tmpdir'
require 'slop'
require_relative '../lib/xcop/document'

# Test for Document class.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2026 Yegor Bugayenko
# License:: MIT
class TestXcop < Minitest::Test
  def test_basic
    Dir.mktmpdir 'test1' do |dir|
      f = File.join(dir, 'a.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<hello>Dude!</hello>\n")
      assert_equal('', Xcop::Document.new(f).diff)
      File.delete(f)
    end
  end

  def test_file_without_tail_eol
    Dir.mktmpdir 'test9' do |dir|
      f = File.join(dir, 'no-eol.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<x/>")
      refute_empty(Xcop::Document.new(f).diff)
      File.delete(f)
    end
  end

  def test_fixes_document
    Dir.mktmpdir 'test3' do |dir|
      f = File.join(dir, 'bad.xml')
      File.write(f, '<hello>My friend!</hello>')
      Xcop::Document.new(f).fix
      assert_equal('', Xcop::Document.new(f).diff)
      File.delete(f)
    end
  end

  def test_fix_removes_unused_namespace
    Dir.mktmpdir 'test_ns_unused' do |dir|
      f = File.join(dir, 'ns.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<a xmlns:x=\"#1\">\n</a>\n")
      Xcop::Document.new(f).fix
      refute_includes(
        File.read(f),
        'xmlns:x',
        "Expected unused xmlns:x to be removed, got '#{File.read(f)}'"
      )
    end
  end

  def test_fix_removes_unused_namespace_on_nested_element
    Dir.mktmpdir 'test_ns_nested' do |dir|
      f = File.join(dir, 'ns.xml')
      File.write(
        f,
        "<?xml version=\"1.0\"?>\n<a>\n  <b xmlns:x=\"#1\"/>\n</a>\n"
      )
      Xcop::Document.new(f).fix
      refute_includes(
        File.read(f),
        'xmlns:x',
        "Expected unused xmlns:x on nested element to be removed, got '#{File.read(f)}'"
      )
    end
  end

  def test_fix_preserves_used_namespace_on_element
    Dir.mktmpdir 'test_ns_used_el' do |dir|
      f = File.join(dir, 'ns.xml')
      File.write(
        f,
        "<?xml version=\"1.0\"?>\n<a xmlns:x=\"#1\">\n  <x:child/>\n</a>\n"
      )
      Xcop::Document.new(f).fix
      assert_includes(
        File.read(f),
        'xmlns:x="#1"',
        "Expected xmlns:x to be preserved, got '#{File.read(f)}'"
      )
    end
  end

  def test_fix_preserves_used_namespace_on_attribute
    Dir.mktmpdir 'test_ns_used_attr' do |dir|
      f = File.join(dir, 'ns.xml')
      File.write(
        f,
        "<?xml version=\"1.0\"?>\n<a xmlns:y=\"#2\">\n  <b y:attr=\"hi\">text</b>\n</a>\n"
      )
      Xcop::Document.new(f).fix
      assert_includes(
        File.read(f),
        'xmlns:y="#2"',
        "Expected xmlns:y to be preserved, got '#{File.read(f)}'"
      )
    end
  end

  def test_diff_flags_unused_namespace
    Dir.mktmpdir 'test_ns_diff' do |dir|
      f = File.join(dir, 'ns.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<a xmlns:x=\"#1\">\n</a>\n")
      refute_empty(
        Xcop::Document.new(f).diff(nocolor: true),
        'Expected non-empty diff for a document with an unused namespace'
      )
    end
  end

  XSI = 'http://www.w3.org/2001/XMLSchema-instance'.freeze
  PERSON_XSD = <<-XSD.freeze
<?xml version="1.0"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="person">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="name" type="xs:string"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
  XSD

  def test_xsd_validation_detects_invalid_xml
    Dir.mktmpdir 'test_xsd_invalid' do |dir|
      File.write(File.join(dir, 'schema.xsd'), PERSON_XSD)
      xml = File.join(dir, 'bad.xml')
      File.write(xml, <<-XML)
<?xml version="1.0"?>
<person xmlns:xsi="#{XSI}" xsi:noNamespaceSchemaLocation="schema.xsd">
</person>
      XML
      refute_empty(Xcop::Document.new(xml).validate, 'Expected XSD errors for invalid XML')
    end
  end

  def test_xsd_validation_passes_for_valid_xml
    Dir.mktmpdir 'test_xsd_valid' do |dir|
      File.write(File.join(dir, 'schema.xsd'), PERSON_XSD)
      xml = File.join(dir, 'good.xml')
      File.write(xml, <<-XML)
<?xml version="1.0"?>
<person xmlns:xsi="#{XSI}" xsi:noNamespaceSchemaLocation="schema.xsd">
  <name>John</name>
</person>
      XML
      assert_empty(Xcop::Document.new(xml).validate, 'Expected no XSD errors for valid XML')
    end
  end

  def test_xsd_validation_skipped_when_no_schema
    Dir.mktmpdir 'test_xsd_absent' do |dir|
      f = File.join(dir, 'plain.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<root/>\n")
      assert_empty(Xcop::Document.new(f).validate, 'Expected no XSD errors when no schema declared')
    end
  end
end
