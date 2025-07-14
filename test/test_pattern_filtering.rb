# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'test__helpers'

# Test for include/exclude pattern filtering functionality.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestPatternFiltering < Minitest::Test
  include TestHelpers

  def test_exclude_pattern
    with_temp_dir do |dir|
      include_file = create_xml_in_dir(dir, 'include.xml', VALID_XML)
      create_xml_in_dir(dir, 'exclude.xml', VALID_XML)
      stdout, stderr, status = run_xcop_in_dir(dir, '--exclude', 'exclude.xml', '.')
      assert_equal("#{normalize_path(include_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_exclude_pattern_no_matches
    with_temp_dir do |dir|
      include_file = create_xml_in_dir(dir, 'include.xml', VALID_XML)
      stdout, stderr, status = run_xcop_in_dir(dir, '--exclude', 'nonexistent.xml', '.')
      assert_equal("#{normalize_path(include_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_include_pattern
    with_temp_dir do |dir|
      wanted_file = create_xml_in_dir(dir, 'wanted.xml', VALID_XML)
      create_xml_in_dir(dir, 'unwanted.xml', VALID_XML)
      stdout, stderr, status = run_xcop('--include', wanted_file)
      assert_equal("#{wanted_file} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_include_pattern_no_matches
    with_temp_dir do |dir|
      create_xml_in_dir(dir, 'unwanted.xml', VALID_XML)
      assert_quiet_run('--include', File.join(dir, 'nonexistent.xml'))
    end
  end

  def test_multiple_excludes
    with_temp_dir do |dir|
      keep_file = create_xml_in_dir(dir, 'keep.xml', VALID_XML)
      create_xml_in_dir(dir, 'skip1.xml', VALID_XML)
      create_xml_in_dir(dir, 'skip2.xml', VALID_XML)
      stdout, stderr, status = run_xcop_in_dir(dir, '--exclude', 'skip1.xml', '--exclude', 'skip2.xml', '.')
      assert_equal("#{normalize_path(keep_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_wildcard_exclude
    with_temp_dir do |dir|
      test_file = create_xml_in_dir(dir, 'test.xml', VALID_XML)
      create_file_in_dir(dir, 'backup.xml.bak', '<root/>')
      stdout, stderr, status = run_xcop_in_dir(dir, '--exclude', '*.bak', '.')
      assert_equal("#{normalize_path(test_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end
end
