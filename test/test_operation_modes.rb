# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative 'xcop_test_fixture'

# Test for xcop operation modes (quiet, fix, etc.).
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestOperationModes < Minitest::Test
  def test_quiet_mode
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('test.xml', XcopTestFixture::VALID_XML) do |file|
      fixture.assert_quiet_run('--quiet', file)
    end
  end

  def test_quiet_with_errors
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('bad.xml', XcopTestFixture::INVALID_XML) do |file|
      stdout, stderr, status = fixture.run_xcop('--quiet', file)
      assert_match(/Invalid XML formatting/, stdout)
      assert_empty(stderr)
      assert_equal(1, status.exitstatus)
    end
  end

  def test_fix_mode
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('bad.xml', XcopTestFixture::INVALID_XML) do |file|
      original = File.read(file)
      fixture.assert_fixed(file)
      refute_equal(original, File.read(file))
      assert_includes(File.read(file), '<?xml version="1.0"?>')
    end
  end

  def test_fix_mode_preserves_valid_files
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('good.xml', XcopTestFixture::VALID_XML) do |file|
      original = File.read(file)
      fixture.assert_fixed(file)
      assert_equal(original, File.read(file))
    end
  end

  def test_fix_quiet
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('bad.xml', XcopTestFixture::INVALID_XML) do |file|
      original = File.read(file)
      fixture.assert_quiet_run('--fix', '--quiet', file)
      refute_equal(original, File.read(file))
    end
  end

  def test_file_permissions
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('readonly.xml', XcopTestFixture::VALID_XML) do |file|
      File.chmod(0o444, file)
      fixture.assert_looks_good(file)
    ensure
      File.chmod(0o644, file) if File.exist?(file)
    end
  end

  def test_fix_readonly_file_fails_gracefully
    fixture = XcopTestFixture.new(self)
    fixture.with_xml_file('readonly.xml', XcopTestFixture::INVALID_XML) do |file|
      File.chmod(0o444, file)
      stdout, stderr, status = fixture.run_xcop('--fix', file)
      assert_empty(stdout)
      assert_includes(stderr, 'Permission denied')
      assert_equal(1, status.exitstatus)
    ensure
      File.chmod(0o644, file) if File.exist?(file)
    end
  end

  def test_no_arguments
    fixture = XcopTestFixture.new(self)
    fixture.assert_quiet_run
  end
end
