# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'xcop_test_runner'

# Test for basic XML validation functionality.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestXmlValidation < Minitest::Test
  def test_valid_file
    runner = XcopTestRunner.new(self)
    runner.with_xml_file('test.xml', XcopTestRunner::VALID_XML) do |file|
      runner.assert_looks_good(file)
    end
  end

  def test_invalid_file
    runner = XcopTestRunner.new(self)
    runner.with_xml_file('bad.xml', XcopTestRunner::INVALID_XML) do |file|
      runner.assert_invalid_xml(file, /Invalid XML formatting in.*bad\.xml/)
    end
  end

  def test_empty_xml_file
    runner = XcopTestRunner.new(self)
    runner.with_xml_file('empty.xml', '') do |file|
      runner.assert_invalid_xml(file, /Invalid XML formatting in.*empty\.xml/)
    end
  end

  def test_malformed_xml_file
    runner = XcopTestRunner.new(self)
    runner.with_xml_file('malformed.xml', XcopTestRunner::MALFORMED_XML) do |file|
      runner.assert_invalid_xml(file, /Invalid XML formatting in.*malformed\.xml/)
    end
  end

  def test_large_xml_file
    runner = XcopTestRunner.new(self)
    runner.with_xml_file('large.xml', runner.build_large_xml(1000)) do |file|
      runner.assert_looks_good(file)
    end
  end

  def test_unicode_content
    runner = XcopTestRunner.new(self)
    unicode_xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root>тест 测试 🚀</root>\n"
    runner.with_xml_file('unicode.xml', unicode_xml) do |file|
      runner.assert_looks_good(file)
    end
  end

  def test_multiple_files
    runner = XcopTestRunner.new(self)
    runner.with_temp_dir do |dir|
      file1 = runner.create_xml_in_dir(dir, 'first.xml', XcopTestRunner::VALID_XML)
      file2 = runner.create_xml_in_dir(dir, 'second.xml', XcopTestRunner::VALID_XML)
      stdout, stderr, status = runner.run_xcop(file1, file2)
      expected = ["#{file1} looks good", "#{file2} looks good"]
      actual = stdout.strip.split("\n")
      assert_equal(expected.sort, actual.sort)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_mixed_files
    runner = XcopTestRunner.new(self)
    runner.with_temp_dir do |dir|
      valid_file = runner.create_xml_in_dir(dir, 'good.xml', XcopTestRunner::VALID_XML)
      invalid_file = runner.create_xml_in_dir(dir, 'bad.xml', XcopTestRunner::INVALID_XML)
      stdout, stderr, status = runner.run_xcop(valid_file, invalid_file)
      assert_includes(stdout, "#{valid_file} looks good")
      assert_match(/Invalid XML formatting in.*bad\.xml/, stdout)
      assert_empty(stderr)
      assert_equal(1, status.exitstatus)
    end
  end
end
