# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'xcop_test_fixture'

class TestDirectories < Minitest::Test
  def test_directory_with_supported_types
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'doc.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, 'schema.xsd', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, 'transform.xsl', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, 'page.xhtml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, 'page.html', XcopTestFixture::VALID_XML)
      stdout, _, _ = fixture.run_xcop(dir)
      assert_match(/doc\.xml looks good/, stdout)
      assert_match(/schema\.xsd looks good/, stdout)
      assert_match(/transform\.xsl looks good/, stdout)
      assert_match(/page\.xhtml looks good/, stdout)
      assert_match(/page\.html looks good/, stdout)
    end
  end

  def test_directory_ignores_unsupported_files
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'supported.xml', XcopTestFixture::VALID_XML)
      fixture.create_file_in_dir(dir, 'text.txt', 'plain text')
      fixture.create_file_in_dir(dir, 'code.rb', 'puts "hello"')
      fixture.create_file_in_dir(dir, 'data.json', '{}')
      stdout, _, _ = fixture.run_xcop(dir)
      refute_match(/text\.txt/, stdout)
      refute_match(/code\.rb/, stdout)
      refute_match(/data\.json/, stdout)
    end
  end

  def test_include_processes_file_in_directory
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      file_path = fixture.create_xml_in_dir(dir, 'included.xml', XcopTestFixture::VALID_XML)
      stdout, _, _ = fixture.run_xcop('--include', file_path)
      assert_match(/included\.xml looks good/, stdout)
    end
  end

  def test_exclude_skips_file_in_directory
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'keep.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, 'exclude.xml', XcopTestFixture::VALID_XML)
      stdout, _, _ = fixture.run_xcop_in_dir(dir, '--exclude', 'exclude.xml', '.')
      refute_match(/exclude\.xml/, stdout)
    end
  end

  def test_fix_works_on_directory_file
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      file_path = fixture.create_xml_in_dir(dir, 'fixable.xml', XcopTestFixture::INVALID_XML)
      original = File.read(file_path)
      _, _, _ = fixture.run_xcop('--fix', dir)
      refute_equal(original, File.read(file_path))
    end
  end
end
