# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'xcop_test_fixture'

# Test for basic XML validation functionality.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestXmlValidation < Minitest::Test
  def test_valid_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('test.xml', XcopTestFixture::VALID_XML) do |file|
      fixture.assert_looks_good(file)
    end
  end

  def test_invalid_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('bad.xml', XcopTestFixture::INVALID_XML) do |file|
      fixture.assert_invalid_xml(file, /Invalid XML formatting in.*bad\.xml/)
    end
  end

  def test_empty_xml_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('empty.xml', '') do |file|
      fixture.assert_invalid_xml(file, /Invalid XML formatting in.*empty\.xml/)
    end
  end

  def test_malformed_xml_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('malformed.xml', XcopTestFixture::MALFORMED_XML) do |file|
      fixture.assert_invalid_xml(file, /Invalid XML formatting in.*malformed\.xml/)
    end
  end

  def test_large_xml_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('large.xml', fixture.build_large_xml(1000)) do |file|
      fixture.assert_looks_good(file)
    end
  end

  def test_unicode_content
    fixture = XcopTestFixture.new(self)
    unicode_xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root>тест 测试 🚀</root>\n"
    fixture.with_xml_file('unicode.xml', unicode_xml) do |file|
      fixture.assert_looks_good(file)
    end
  end

  def test_multiple_files
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      file1 = fixture.create_xml_in_dir(dir, 'first.xml', XcopTestFixture::VALID_XML)
      file2 = fixture.create_xml_in_dir(dir, 'second.xml', XcopTestFixture::VALID_XML)
      stdout, stderr, status = fixture.run_xcop(file1, file2)
      expected = ["#{file1} looks good", "#{file2} looks good"]
      actual = stdout.strip.split("\n")
      assert_equal(expected.sort, actual.sort)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_mixed_files
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      valid_file = fixture.create_xml_in_dir(dir, 'good.xml', XcopTestFixture::VALID_XML)
      invalid_file = fixture.create_xml_in_dir(dir, 'bad.xml', XcopTestFixture::INVALID_XML)
      stdout, stderr, status = fixture.run_xcop(valid_file, invalid_file)
      assert_includes(stdout, "#{valid_file} looks good")
      assert_match(/Invalid XML formatting in.*bad\.xml/, stdout)
      assert_empty(stderr)
      assert_equal(1, status.exitstatus)
    end
  end
end
