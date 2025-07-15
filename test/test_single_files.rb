# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'xcop_test_fixture'

class TestSingleFiles < Minitest::Test
  def test_processes_xml_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('test.xml', XcopTestFixture::VALID_XML) do |file|
      fixture.assert_looks_good(file)
    end
  end

  def test_processes_xsd_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('schema.xsd', XcopTestFixture::VALID_XML) do |file|
      fixture.assert_looks_good(file)
    end
  end

  def test_processes_xsl_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('transform.xsl', XcopTestFixture::VALID_XML) do |file|
      fixture.assert_looks_good(file)
    end
  end

  def test_processes_xhtml_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('page.xhtml', XcopTestFixture::VALID_XML) do |file|
      fixture.assert_looks_good(file)
    end
  end

  def test_processes_html_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('page.html', XcopTestFixture::VALID_XML) do |file|
      fixture.assert_looks_good(file)
    end
  end

  def test_ignores_txt_file
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_file_in_dir(dir, 'test.txt', 'plain text')
      stdout, stderr, status = fixture.run_xcop(File.join(dir, 'test.txt'))
      assert_empty(stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_ignores_rb_file
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_file_in_dir(dir, 'script.rb', 'puts "hello"')
      stdout, stderr, status = fixture.run_xcop(File.join(dir, 'script.rb'))
      assert_empty(stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_ignores_json_file
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_file_in_dir(dir, 'data.json', '{}')
      stdout, stderr, status = fixture.run_xcop(File.join(dir, 'data.json'))
      assert_empty(stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_include_processes_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('included.xml', XcopTestFixture::VALID_XML) do |file|
      stdout, = fixture.run_xcop('--include', file)
      assert_includes(stdout, "#{file} looks good")
    end
  end

  def test_exclude_skips_file
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'keep.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, 'exclude.xml', XcopTestFixture::VALID_XML)
      stdout, = fixture.run_xcop_in_dir(dir, '--exclude', 'exclude.xml', '.')
      refute_includes(stdout, 'exclude.xml')
    end
  end

  def test_fix_transforms_invalid_file
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('fixable.xml', XcopTestFixture::INVALID_XML) do |file|
      original = File.read(file)
      fixture.assert_fixed(file)
      refute_equal(original, File.read(file))
    end
  end
end
