# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'test__helpers'

# Test for file and directory handling functionality.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestFileHandling < Minitest::Test
  include TestHelpers

  def test_directory
    with_temp_dir do |dir|
      root_file = create_xml_in_dir(dir, 'root.xml', VALID_XML)
      nested_file = create_xml_in_subdir(dir, 'subdir', 'nested.xml', VALID_XML)
      create_non_xml_file(dir, 'ignored.txt')
      stdout, stderr, status = run_xcop(dir)
      assert_includes(stdout, "#{root_file} looks good")
      assert_includes(stdout, "#{nested_file} looks good")
      refute_includes(stdout, 'ignored.txt')
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
      assert_equal(2, stdout.lines.count)
    end
  end

  def test_empty_directory
    with_temp_dir { |dir| assert_quiet_run(create_empty_subdir(dir, 'empty')) }
  end

  def test_nonexistent_file
    stdout, stderr, status = run_xcop('nonexistent.xml')
    assert_empty(stdout)
    assert_includes(stderr, 'Path does not exist')
    assert_equal(1, status.exitstatus)
  end

  def test_config_file
    with_temp_dir do |dir|
      create_config_file(dir, "--quiet\n")
      xml_file = create_xml_in_dir(dir, 'test.xml', VALID_XML)
      stdout, stderr, status = run_xcop_in_dir(dir, xml_file)
      assert_empty(stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_config_file_with_empty_lines
    with_temp_dir do |dir|
      create_config_file(dir, "--quiet\n\n\n")
      xml_file = create_xml_in_dir(dir, 'test.xml', VALID_XML)
      stdout, stderr, status = run_xcop_in_dir(dir, xml_file)
      assert_empty(stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end
end
