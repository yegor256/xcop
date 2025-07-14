# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'fileutils'
require_relative 'xcop_test_fixture'

# Test for directory structure handling (hidden and nested directories).
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestDirectoryStructureHandling < Minitest::Test
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

  def test_deeply_nested_subdirectories
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'regular.xml', XcopTestFixture::VALID_XML)
      deep_dir = File.join(dir, 'level1', 'level2', 'level3', 'level4', 'level5')
      FileUtils.mkdir_p(deep_dir)
      fixture.create_xml_in_dir(deep_dir, 'nested.xml', XcopTestFixture::INVALID_XML)
      stdout, _stderr, status = fixture.run_xcop_in_dir(dir, '.')
      assert_match(/Invalid XML formatting/, stdout)
      assert_match(/level1.*level2.*level3.*level4.*level5.*nested\.xml/, stdout)
      assert_equal(1, status.exitstatus)
    end
  end

  def test_exclude_deeply_nested_subdirectories
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      regular_file = fixture.create_xml_in_dir(dir, 'regular.xml', XcopTestFixture::VALID_XML)
      deep_dir = File.join(dir, 'build', 'generated', 'src', 'main', 'resources')
      FileUtils.mkdir_p(deep_dir)
      fixture.create_xml_in_dir(deep_dir, 'generated.xml', XcopTestFixture::INVALID_XML)
      stdout, stderr, status = fixture.run_xcop_in_dir(dir, '--exclude', 'build/**/*', '.')
      assert_equal("#{fixture.normalize_path(regular_file)} looks good\n", stdout)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_mixed_hidden_and_nested_structures
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'regular.xml', XcopTestFixture::VALID_XML)
      hidden_deep_dir = File.join(dir, '.cache', 'level1', 'level2')
      FileUtils.mkdir_p(hidden_deep_dir)
      fixture.create_xml_in_dir(hidden_deep_dir, 'deep_hidden.xml', XcopTestFixture::INVALID_XML)
      public_deep_dir = File.join(dir, 'src', 'main', 'resources')
      FileUtils.mkdir_p(public_deep_dir)
      fixture.create_xml_in_dir(public_deep_dir, 'config.xml', XcopTestFixture::INVALID_XML)
      stdout, _stderr, status = fixture.run_xcop_in_dir(dir, '--exclude', '.*/**/*', '.')
      assert_match(/Invalid XML formatting/, stdout)
      assert_match(/src.*main.*resources.*config\.xml/, stdout)
      refute_match(/\.cache/, stdout)
      assert_equal(1, status.exitstatus)
    end
  end
end
