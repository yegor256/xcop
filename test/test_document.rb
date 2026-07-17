# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'nokogiri'
require 'slop'
require 'tmpdir'
require_relative '../lib/xcop/document'

# Test for Document class.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2026 Yegor Bugayenko
# License:: MIT
class TestXcop < Minitest::Test
  def test_basic
    Dir.mktmpdir('test1') do |dir|
      f = File.join(dir, 'a.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<hello>Dude!</hello>\n")
      assert_equal('', Xcop::Document.new(f).diff)
      File.delete(f)
    end
  end

  def test_file_without_tail_eol
    Dir.mktmpdir('test9') do |dir|
      f = File.join(dir, 'no-eol.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<x/>")
      refute_empty(Xcop::Document.new(f).diff)
      File.delete(f)
    end
  end

  def test_fixes_document
    Dir.mktmpdir('test3') do |dir|
      f = File.join(dir, 'bad.xml')
      File.write(f, '<hello>My friend!</hello>')
      Xcop::Document.new(f).fix
      assert_equal('', Xcop::Document.new(f).diff)
      File.delete(f)
    end
  end

  def test_fix_reports_fixed_when_file_rewritten
    Dir.mktmpdir('test_fix_changed') do |dir|
      f = File.join(dir, 'bad.xml')
      File.write(f, '<hello>My friend!</hello>')
      assert_equal(:fixed, Xcop::Document.new(f).fix, 'Expected fix to report :fixed on a file that needed rewriting')
    end
  end

  def test_fix_reports_untouched_when_file_canonical
    Dir.mktmpdir('test_fix_untouched') do |dir|
      f = File.join(dir, 'good.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<hello>Dude!</hello>\n")
      assert_equal(
        :untouched,
        Xcop::Document.new(f).fix,
        'Expected fix to report :untouched on an already-canonical file'
      )
    end
  end

  def test_fix_removes_unused_namespace
    Dir.mktmpdir('test_ns_unused') do |dir|
      f = File.join(dir, 'ns.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<a xmlns:x=\"#1\">\n</a>\n")
      Xcop::Document.new(f).fix
      refute_includes(File.read(f), 'xmlns:x', "Expected unused xmlns:x to be removed, got '#{File.read(f)}'")
    end
  end

  def test_fix_removes_unused_namespace_nested
    Dir.mktmpdir('test_ns_nested') do |dir|
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
    Dir.mktmpdir('test_ns_used_el') do |dir|
      f = File.join(dir, 'ns.xml')
      File.write(
        f,
        "<?xml version=\"1.0\"?>\n<a xmlns:x=\"#1\">\n  <x:child/>\n</a>\n"
      )
      Xcop::Document.new(f).fix
      assert_includes(File.read(f), 'xmlns:x="#1"', "Expected xmlns:x to be preserved, got '#{File.read(f)}'")
    end
  end

  def test_fix_preserves_used_namespace_on_attribute
    Dir.mktmpdir('test_ns_used_attr') do |dir|
      f = File.join(dir, 'ns.xml')
      File.write(
        f,
        "<?xml version=\"1.0\"?>\n<a xmlns:y=\"#2\">\n  <b y:attr=\"hi\">text</b>\n</a>\n"
      )
      Xcop::Document.new(f).fix
      assert_includes(File.read(f), 'xmlns:y="#2"', "Expected xmlns:y to be preserved, got '#{File.read(f)}'")
    end
  end

  def test_fix_keeps_xpath_attribute_namespace
    Dir.mktmpdir('test_ns_used_xpath') do |dir|
      f = File.join(dir, 'ns.xml')
      File.write(f, <<-XML)
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
  <xsl:variable name="n" as="xs:integer" select="1"/>
</xsl:stylesheet>
      XML
      Xcop::Document.new(f).fix
      assert_includes(
        File.read(f),
        'xmlns:xs=',
        "Expected xmlns:xs referenced only from an XPath attribute to be preserved, got '#{File.read(f)}'"
      )
    end
  end

  def test_fix_keeps_function_call_namespace
    Dir.mktmpdir('test_ns_used_fn') do |dir|
      f = File.join(dir, 'ns.xml')
      File.write(f, <<-XML)
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:eo="urn:eo" version="2.0">
  <xsl:value-of select="eo:foo(.)"/>
</xsl:stylesheet>
      XML
      Xcop::Document.new(f).fix
      assert_includes(
        File.read(f),
        'xmlns:eo=',
        "Expected xmlns:eo referenced only from a function call to be preserved, got '#{File.read(f)}'"
      )
    end
  end

  def test_diff_flags_unused_namespace
    Dir.mktmpdir('test_ns_diff') do |dir|
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
    Dir.mktmpdir('test_xsd_invalid') do |dir|
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
    Dir.mktmpdir('test_xsd_valid') do |dir|
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
    Dir.mktmpdir('test_xsd_absent') do |dir|
      f = File.join(dir, 'plain.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<root/>\n")
      assert_empty(Xcop::Document.new(f).validate, 'Expected no XSD errors when no schema declared')
    end
  end

  def test_xsd_validation_reports_missing_schema
    Dir.mktmpdir('test_xsd_missing') do |dir|
      xml = File.join(dir, 'orphan.xml')
      File.write(xml, <<-XML)
<?xml version="1.0"?>
<person xmlns:xsi="#{XSI}" xsi:noNamespaceSchemaLocation="absent.xsd">
</person>
      XML
      refute_empty(Xcop::Document.new(xml).validate, 'Missing XSD schema cannot be silently ignored')
    end
  end

  def test_fix_collapses_single_line_comment
    Dir.mktmpdir('test_comment_single') do |dir|
      f = File.join(dir, 'c.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<a>\n  <!--   text   -->\n</a>\n")
      Xcop::Document.new(f).fix
      got = File.read(f)
      assert_includes(got, '<!-- text -->', "Expected single-line comment to be collapsed, got '#{got}'")
    end
  end

  def test_fix_reshapes_multi_line_comment
    Dir.mktmpdir('test_comment_multi') do |dir|
      f = File.join(dir, 'c.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<a>\n  <!-- line1\n       line2 -->\n</a>\n")
      Xcop::Document.new(f).fix
      assert_equal(
        "<?xml version=\"1.0\"?>\n<a>\n  <!--\n  line1\n  line2\n  -->\n</a>\n",
        File.read(f),
        "Expected multi-line comment to be reshaped, got '#{File.read(f)}'"
      )
    end
  end

  def test_diff_flags_messy_comment
    Dir.mktmpdir('test_comment_diff') do |dir|
      f = File.join(dir, 'c.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<a>\n  <!--messy-->\n</a>\n")
      refute_empty(
        Xcop::Document.new(f).diff(nocolor: true),
        'Expected non-empty diff for a document with a badly formatted comment'
      )
    end
  end

  def test_fix_leaves_canonical_comments_untouched
    Dir.mktmpdir('test_comment_ok') do |dir|
      f = File.join(dir, 'c.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<a>\n  <!-- text -->\n  <!--\n  line1\n  line2\n  -->\n</a>\n")
      assert_equal(:untouched, Xcop::Document.new(f).fix, 'Expected already-canonical comments to be left untouched')
    end
  end

  def test_diff_leaves_no_open_handle
    Dir.mktmpdir('test_diff_leak') do |dir|
      f = File.join(dir, 'a.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<a/>\n")
      Xcop::Document.new(f).diff
      leaked = ObjectSpace.each_object(File).count { |io| !io.closed? && io.path == f }
      assert_equal(0, leaked, 'Diffing cannot leave the file handle open')
    end
  end

  def test_validate_leaves_no_open_handle
    Dir.mktmpdir('test_validate_leak') do |dir|
      f = File.join(dir, 'a.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<a/>\n")
      Xcop::Document.new(f).validate
      leaked = ObjectSpace.each_object(File).count { |io| !io.closed? && io.path == f }
      assert_equal(0, leaked, 'Validating cannot leave the file handle open')
    end
  end
end
