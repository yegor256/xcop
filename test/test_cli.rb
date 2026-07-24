# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/xcop/cli'

# Tests for CLI class.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2026 Yegor Bugayenko
# License:: MIT
class CLITest < Minitest::Test
  def test_run_valid_file_no_exception
    Dir.mktmpdir('test_valid') do |dir|
      f = File.join(dir, 'valid.xml')
      File.write(f, "<?xml version=\"1.0\"?>\n<root>\n  <item>test</item>\n</root>\n")
      cli = Xcop::CLI.new([f])
      result = nil
      cli.run { |file| result = file }
      assert_equal(f, result, "Expected to run the valid XML '#{f}', but received '#{result}' instead")
    end
  end

  def test_run_invalid_file_exception
    Dir.mktmpdir('test_invalid') do |dir|
      f = File.join(dir, 'invalid.xml')
      File.write(f, '<root><item>test</item></root>')
      cli = Xcop::CLI.new([f])
      assert_raises(
        StandardError,
        "Expected to raise an error for invalid file '#{f}', but no error was raised"
      ) { cli.run }
    end
  end

  def test_run_nonexistent_file_exception
    f = '/tmp/nonexistent_file.xml'
    cli = Xcop::CLI.new([f])
    assert_raises(
      Errno::ENOENT,
      "Expected to raise an error for nonexistent file '#{f}', but no error was raised"
    ) { cli.run }
  end

  def test_run_empty_file_runtime_error
    Dir.mktmpdir('test_empty') do |dir|
      f = File.join(dir, 'empty.xml')
      File.write(f, '')
      cli = Xcop::CLI.new([f])
      assert_raises(
        StandardError,
        "Expected to raise an error for empty file '#{f}', but no error was raised"
      ) { cli.run }
    end
  end

  def test_run_multiple_files_no_exceptions
    Dir.mktmpdir('test_multiple') do |dir|
      one = File.join(dir, 'file1.xml')
      two = File.join(dir, 'file2.xml')
      File.write(one, "<?xml version=\"1.0\"?>\n<root>\n  <item>1</item>\n</root>\n")
      File.write(two, "<?xml version=\"1.0\"?>\n<root>\n  <item>2</item>\n</root>\n")
      processed = []
      cli = Xcop::CLI.new([one, two])
      cli.run { |file| processed << file }
      assert_equal(2, processed.length, "Expected 2 processed files, got '#{processed.length}'")
      assert_includes(processed, one, "Expected '#{one}' to be processed")
      assert_includes(processed, two, "Expected '#{two}' to be processed")
    end
  end

  def test_run_invalid_file_exception_and_messages
    Dir.mktmpdir('test_error') do |dir|
      f = File.join(dir, 'bad_format.xml')
      File.write(f, '<?xml version="1.0"?><root><item>no proper indenting</item></root>')
      cli = Xcop::CLI.new([f])
      error =
        assert_raises(
          StandardError,
          "Expected to raise an error for invalid file '#{f}', but no error was raised"
        ) { cli.run }
      assert_match(
        /Invalid XML formatting/,
        error.message,
        "Expected to match '/Invalid XML formatting/' error message, got '#{error.message}'"
      )
      assert_match(
        /bad_format.xml/,
        error.message,
        "Expected to match '/bad_format.xml/' error message, got '#{error.message}'"
      )
    end
  end

  def test_fix_valid_file_no_changes
    Dir.mktmpdir('test_no_fix') do |dir|
      f = File.join(dir, 'valid.xml')
      content = "<?xml version=\"1.0\"?>\n<root>\n  <item>test</item>\n</root>\n"
      File.write(f, content)
      Xcop::CLI.new([f]).fix
      assert_equal(content, File.read(f), "Expected to not fix valid file - '#{f}'")
    end
  end

  def test_fix_invalid_file_changing_file
    Dir.mktmpdir('test_fix') do |dir|
      f = File.join(dir, 'invalid.xml')
      File.write(f, '<root><item>test</item></root>')
      before = File.read(f)
      Xcop::CLI.new([f]).fix
      refute_equal(before, File.read(f), "Expected to fix invalid file - '#{f}'")
    end
  end

  def test_run_on_directory_recursively
    Dir.mktmpdir('test_dir_input') do |dir|
      nested = File.join(dir, 'nested')
      FileUtils.mkdir_p(nested)
      one = File.join(dir, 'top.xml')
      two = File.join(nested, 'deep.xsl')
      File.write(one, "<?xml version=\"1.0\"?>\n<root>\n  <item>1</item>\n</root>\n")
      File.write(two, "<?xml version=\"1.0\"?>\n<root>\n  <item>2</item>\n</root>\n")
      processed = []
      cli = Xcop::CLI.new([dir])
      cli.run { |file| processed << file }
      assert_includes(processed, one, "Expected to include '#{one}' when directory '#{dir}' is given")
      assert_includes(processed, two, "Expected to include '#{two}' when directory '#{dir}' is given")
    end
  end

  def test_run_on_directory_ignores_non_xml_files
    Dir.mktmpdir('test_dir_skip') do |dir|
      xml = File.join(dir, 'good.xml')
      File.write(xml, "<?xml version=\"1.0\"?>\n<root>\n  <item>1</item>\n</root>\n")
      File.write(File.join(dir, 'notes.txt'), 'not xml')
      processed = []
      cli = Xcop::CLI.new([dir])
      cli.run { |file| processed << file }
      assert_equal([xml], processed, "Expected only '#{xml}' to be processed, got '#{processed}'")
    end
  end

  def test_fix_multiple_invalid_files
    Dir.mktmpdir('test_fix_multiple') do |dir|
      one = File.join(dir, 'invalid1.xml')
      two = File.join(dir, 'invalid2.xml')
      File.write(one, '<root><item>test1</item></root>')
      File.write(two, '<data><value>test2</value></data>')
      first = File.read(one)
      second = File.read(two)
      fixed = []
      cli = Xcop::CLI.new([one, two])
      cli.fix { |file| fixed << file }
      refute_equal(first, File.read(one), "Expected to fix invalid file - '#{one}'")
      refute_equal(second, File.read(two), "Expected to fix invalid file - '#{two}'")
    end
  end

  def test_fix_yields_malformed_status_for_broken_file
    Dir.mktmpdir('test_fix_malformed_cli') do |dir|
      f = File.join(dir, 'broken.xml')
      File.write(f, "this is not XML\n")
      status = nil
      Xcop::CLI.new([f]).fix { |_file, sym| status = sym }
      assert_equal(:malformed, status, "Expected '#{f}' to be reported malformed, got '#{status}'")
    end
  end

  def test_fix_keeps_broken_file_intact
    Dir.mktmpdir('test_fix_intact_cli') do |dir|
      f = File.join(dir, 'broken.xml')
      File.write(f, "this is not XML\n")
      Xcop::CLI.new([f]).fix
      assert_equal("this is not XML\n", File.read(f), "Expected broken file '#{f}' to remain intact")
    end
  end

  def test_fix_yields_status_for_each_file
    Dir.mktmpdir('test_fix_yield_status') do |dir|
      good = File.join(dir, 'good.xml')
      bad = File.join(dir, 'bad.xml')
      File.write(good, "<?xml version=\"1.0\"?>\n<root>\n  <item>1</item>\n</root>\n")
      File.write(bad, '<root><item>2</item></root>')
      seen = {}
      Xcop::CLI.new([good, bad]).fix { |file, status| seen[file] = status }
      assert_equal(:untouched, seen[good], "Expected '#{good}' to be reported untouched")
      assert_equal(:fixed, seen[bad], "Expected '#{bad}' to be reported fixed")
    end
  end
end
