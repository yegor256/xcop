# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'fileutils'
require_relative 'xcop_test_fixture'

class TestHiddenFiles < Minitest::Test
  def test_hidden_directory_is_processed
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      hidden_dir = File.join(dir, '.hidden')
      FileUtils.mkdir_p(hidden_dir)
      fixture.create_xml_in_dir(hidden_dir, 'hidden.xml', XcopTestFixture::INVALID_XML)
      stdout, = fixture.run_xcop(dir)
      assert_match(/Invalid XML formatting/, stdout)
    end
  end

  def test_hidden_file_is_processed
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, '.hidden.xml', XcopTestFixture::INVALID_XML)
      stdout, = fixture.run_xcop(dir)
      assert_match(/Invalid XML formatting/, stdout)
    end
  end

  def test_deeply_nested_hidden_directory_is_processed
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      deep_hidden_dir = File.join(dir, '.hidden1', '.hidden2')
      FileUtils.mkdir_p(deep_hidden_dir)
      fixture.create_xml_in_dir(deep_hidden_dir, 'nested.xml', XcopTestFixture::INVALID_XML)
      stdout, = fixture.run_xcop(dir)
      assert_match(/Invalid XML formatting/, stdout)
    end
  end

  def test_hidden_and_regular_files_both_processed
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'regular.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(dir, '.hidden.xml', XcopTestFixture::VALID_XML)
      stdout, = fixture.run_xcop(dir)
      assert_match(/regular\.xml looks good/, stdout)
      assert_match(/\.hidden\.xml looks good/, stdout)
    end
  end

  def test_hidden_directory_with_valid_file_processed
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      hidden_dir = File.join(dir, '.hidden_dir')
      FileUtils.mkdir_p(hidden_dir)
      fixture.create_xml_in_dir(hidden_dir, 'inside_hidden.xml', XcopTestFixture::VALID_XML)
      stdout, = fixture.run_xcop(dir)
      assert_match(/\.hidden_dir.*inside_hidden\.xml looks good/, stdout)
    end
  end
end
