# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'xcop_test_fixture'

class TestEdgeCases < Minitest::Test
  def test_include_and_exclude_same_file_excludes_it
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      file = fixture.create_xml_in_dir(dir, 'test.xml', XcopTestFixture::VALID_XML)
      stdout, _, _ = fixture.run_xcop('--include', file, '--exclude', file)
      assert_empty(stdout)
    end
  end

  def test_nonexistent_file_causes_error
    fixture = XcopTestFixture.new(self)
    _, stderr, _ = fixture.run_xcop('nonexistent.xml')
    assert_includes(stderr, 'Path does not exist')
  end

  def test_nonexistent_directory_causes_error
    fixture = XcopTestFixture.new(self)
    _, stderr, _ = fixture.run_xcop('nonexistent_directory')
    assert_includes(stderr, 'Path does not exist')
  end

  def test_empty_directory_produces_no_output
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      empty_subdir = fixture.create_empty_subdir(dir, 'empty')
      fixture.assert_quiet_run(empty_subdir)
    end
  end

  def test_no_arguments_produces_no_output
    fixture = XcopTestFixture.new(self)
    fixture.assert_quiet_run
  end

  def test_exclude_nonexistent_wildcard_ignores_pattern
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('test.xml', XcopTestFixture::VALID_XML) do |file|
      stdout, _, _ = fixture.run_xcop('--exclude', 'nonexistent_*', file)
      assert_includes(stdout, "#{file} looks good")
    end
  end

  def test_include_nonexistent_pattern_produces_no_output
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'existing.xml', XcopTestFixture::VALID_XML)
      fixture.assert_quiet_run('--include', File.join(dir, 'nonexistent_*.xml'))
    end
  end

  def test_exclude_overrides_include
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      file1 = fixture.create_xml_in_dir(dir, 'keep.xml', XcopTestFixture::VALID_XML)
      file2 = fixture.create_xml_in_dir(dir, 'skip.xml', XcopTestFixture::VALID_XML)
      stdout, _, _ = fixture.run_xcop('--include', file1, '--include', file2, '--exclude', file2)
      assert_includes(stdout, "#{file1} looks good")
      refute_includes(stdout, "skip.xml")
    end
  end

  def test_exclude_directory_excludes_all_files_inside
    fixture = XcopTestFixture.new(self)
    fixture.with_temp_dir do |dir|
      fixture.create_xml_in_dir(dir, 'keep.xml', XcopTestFixture::VALID_XML)
      exclude_dir = File.join(dir, 'exclude_dir')
      FileUtils.mkdir_p(exclude_dir)
      fixture.create_xml_in_dir(exclude_dir, 'file1.xml', XcopTestFixture::VALID_XML)
      fixture.create_xml_in_dir(exclude_dir, 'file2.xml', XcopTestFixture::VALID_XML)
      stdout, _, _ = fixture.run_xcop_in_dir(dir, '--exclude', 'exclude_dir', '.')
      refute_includes(stdout, 'file1.xml')
      refute_includes(stdout, 'file2.xml')
    end
  end

  def test_nonexistent_file_error_exits_with_code_1
    fixture = XcopTestFixture.new(self)
    _, _, status = fixture.run_xcop('nonexistent.xml')
    assert_equal(1, status.exitstatus)
  end

  def test_nonexistent_directory_error_exits_with_code_1
    fixture = XcopTestFixture.new(self)
    _, _, status = fixture.run_xcop('nonexistent_directory')
    assert_equal(1, status.exitstatus)
  end
end
