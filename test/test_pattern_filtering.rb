# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'xcop_test_runner'

# Test for include/exclude pattern filtering functionality.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestPatternFiltering < Minitest::Test
  def test_exclude_pattern
    runner = XcopTestRunner.new(self)
    runner.with_temp_dir do |dir|
      include_file = runner.create_xml_in_dir(dir, 'include.xml', XcopTestRunner::VALID_XML)
      runner.create_xml_in_dir(dir, 'exclude.xml', XcopTestRunner::VALID_XML)
      stdout, stderr, status = runner.run_xcop_in_dir(dir, '--exclude', 'exclude.xml', '.')
      assert_equal("#{runner.normalize_path(include_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_exclude_pattern_no_matches
    runner = XcopTestRunner.new(self)
    runner.with_temp_dir do |dir|
      include_file = runner.create_xml_in_dir(dir, 'include.xml', XcopTestRunner::VALID_XML)
      stdout, stderr, status = runner.run_xcop_in_dir(dir, '--exclude', 'nonexistent.xml', '.')
      assert_equal("#{runner.normalize_path(include_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_include_pattern
    runner = XcopTestRunner.new(self)
    runner.with_temp_dir do |dir|
      wanted_file = runner.create_xml_in_dir(dir, 'wanted.xml', XcopTestRunner::VALID_XML)
      runner.create_xml_in_dir(dir, 'unwanted.xml', XcopTestRunner::VALID_XML)
      stdout, stderr, status = runner.run_xcop('--include', wanted_file)
      assert_equal("#{wanted_file} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_include_pattern_no_matches
    runner = XcopTestRunner.new(self)
    runner.with_temp_dir do |dir|
      runner.create_xml_in_dir(dir, 'unwanted.xml', XcopTestRunner::VALID_XML)
      runner.assert_quiet_run('--include', File.join(dir, 'nonexistent.xml'))
    end
  end

  def test_multiple_excludes
    runner = XcopTestRunner.new(self)
    runner.with_temp_dir do |dir|
      keep_file = runner.create_xml_in_dir(dir, 'keep.xml', XcopTestRunner::VALID_XML)
      runner.create_xml_in_dir(dir, 'skip1.xml', XcopTestRunner::VALID_XML)
      runner.create_xml_in_dir(dir, 'skip2.xml', XcopTestRunner::VALID_XML)
      stdout, stderr, status = runner.run_xcop_in_dir(dir, '--exclude', 'skip1.xml', '--exclude', 'skip2.xml', '.')
      assert_equal("#{runner.normalize_path(keep_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_wildcard_exclude
    runner = XcopTestRunner.new(self)
    runner.with_temp_dir do |dir|
      test_file = runner.create_xml_in_dir(dir, 'test.xml', XcopTestRunner::VALID_XML)
      runner.create_file_in_dir(dir, 'backup.xml.bak', '<root/>')
      stdout, stderr, status = runner.run_xcop_in_dir(dir, '--exclude', '*.bak', '.')
      assert_equal("#{runner.normalize_path(test_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end
end
