# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'xcop_test_fixture'

# Test for include/exclude pattern filtering functionality.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestPatternFiltering < Minitest::Test
  def test_exclude_pattern
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      include_file = fixture.create_xml_in_dir(dir, 'include.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, 'exclude.xml', XcopTestFixture::VALID_XML)
      stdout, stderr, status = fixture.run_xcop_in_dir(dir, '--exclude', 'exclude.xml', '.')
      assert_equal("#{fixture.normalize_path(include_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_exclude_pattern_no_matches
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      include_file = fixture.create_xml_in_dir(dir, 'include.xml', XcopTestFixture::VALID_XML)
      stdout, stderr, status = fixture.run_xcop_in_dir(dir, '--exclude', 'nonexistent.xml', '.')
      assert_equal("#{fixture.normalize_path(include_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_include_pattern
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      wanted_file = fixture.create_xml_in_dir(dir, 'wanted.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, 'unwanted.xml', XcopTestFixture::VALID_XML)
      stdout, stderr, status = fixture.run_xcop('--include', wanted_file)
      assert_equal("#{wanted_file} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_include_pattern_no_matches
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'unwanted.xml', XcopTestFixture::VALID_XML)
      fixture.assert_quiet_run('--include', File.join(dir, 'nonexistent.xml'))
    end
  end

  def test_multiple_excludes
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      keep_file = fixture.create_xml_in_dir(dir, 'keep.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, 'skip1.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, 'skip2.xml', XcopTestFixture::VALID_XML)
      stdout, stderr, status = fixture.run_xcop_in_dir(dir, '--exclude', 'skip1.xml', '--exclude', 'skip2.xml', '.')
      assert_equal("#{fixture.normalize_path(keep_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_wildcard_exclude
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      test_file = fixture.create_xml_in_dir(dir, 'test.xml', XcopTestFixture::VALID_XML)
      fixture.create_file_in_dir(dir, 'backup.xml.bak', '<root/>')
      stdout, stderr, status = fixture.run_xcop_in_dir(dir, '--exclude', '*.bak', '.')
      assert_equal("#{fixture.normalize_path(test_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_hidden_directory_processing
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'regular.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_subdir(dir, '.venv', 'hidden.xml', XcopTestFixture::INVALID_XML)
      stdout, _stderr, status = fixture.run_xcop_in_dir(dir, '.')
      assert_match(/Invalid XML formatting/, stdout)
      assert_equal(1, status.exitstatus)
    end
  end

  def test_exclude_hidden_directory
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      regular_file = fixture.create_xml_in_dir(dir, 'regular.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_subdir(dir, '.venv', 'hidden.xml', XcopTestFixture::INVALID_XML)
      stdout, stderr, status = fixture.run_xcop_in_dir(dir, '--exclude', '.venv/**/*', '.')
      assert_equal("#{fixture.normalize_path(regular_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_exclude_hidden_directory_with_config_file
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'regular.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_subdir(dir, '.venv', 'hidden.xml', XcopTestFixture::INVALID_XML)
      fixture.create_config_file(dir, "--exclude=.venv/**/*\n--quiet")
      stdout, stderr, status = fixture.run_xcop_in_dir(dir, '.')
      assert_empty(stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end
end
