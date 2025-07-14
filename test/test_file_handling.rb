# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'xcop_test_fixture'

# Test for file and directory handling functionality.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestFileHandling < Minitest::Test
  def test_directory
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      root_file = fixture.create_xml_in_dir(dir, 'root.xml', XcopTestFixture::VALID_XML)
      nested_file = fixture.create_xml_in_subdir(dir, 'subdir', 'nested.xml', XcopTestFixture::VALID_XML)
      fixture.create_non_xml_file(dir, 'ignored.txt')
      stdout, stderr, status = fixture.run_xcop(dir)
      assert_includes(stdout, "#{root_file} looks good")
      assert_includes(stdout, "#{nested_file} looks good")
      refute_includes(stdout, 'ignored.txt')
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
      assert_equal(2, stdout.lines.count)
    end
  end

  def test_empty_directory
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      empty_dir = fixture.create_empty_subdir(dir, 'empty')
      fixture.assert_quiet_run(empty_dir)
    end
  end

  def test_nonexistent_file
    fixture = XcopTestFixture.new(self)
    stdout, stderr, status = fixture.run_xcop('nonexistent.xml')
    assert_empty(stdout)
    assert_includes(stderr, 'Path does not exist')
    assert_equal(1, status.exitstatus)
  end

  def test_config_file
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_config_file(dir, "--quiet\n")
      xml_file = fixture.create_xml_in_dir(dir, 'test.xml', XcopTestFixture::VALID_XML)
      stdout, stderr, status = fixture.run_xcop_in_dir(dir, xml_file)
      assert_empty(stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_config_file_with_empty_lines
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_config_file(dir, "--quiet\n\n\n")
      xml_file = fixture.create_xml_in_dir(dir, 'test.xml', XcopTestFixture::VALID_XML)
      stdout, stderr, status = fixture.run_xcop_in_dir(dir, xml_file)
      assert_empty(stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end
end
