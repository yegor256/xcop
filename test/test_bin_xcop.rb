# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'open3'

# Test for bin/xcop executable.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestBinXcop < Minitest::Test
  VALID_XML = "<?xml version=\"1.0\"?>\n<root>content</root>\n".freeze
  INVALID_XML = '<root>  content  </root>'.freeze
  MALFORMED_XML = '<unclosed>'.freeze

  def test_valid_file
    with_xml_file('test.xml', VALID_XML) do |file|
      assert_looks_good(file)
    end
  end

  def test_invalid_file
    with_xml_file('bad.xml', INVALID_XML) do |file|
      assert_invalid_xml(file, /Invalid XML formatting in.*bad\.xml/)
    end
  end

  def test_empty_xml_file
    with_xml_file('empty.xml', '') do |file|
      assert_invalid_xml(file, /Invalid XML formatting in.*empty\.xml/)
    end
  end

  def test_malformed_xml_file
    with_xml_file('malformed.xml', MALFORMED_XML) do |file|
      assert_invalid_xml(file, /Invalid XML formatting in.*malformed\.xml/)
    end
  end

  def test_large_xml_file
    with_xml_file('large.xml', build_large_xml(1000)) do |file|
      assert_looks_good(file)
    end
  end

  def test_quiet_mode
    with_xml_file('test.xml', VALID_XML) do |file|
      assert_quiet_run('--quiet', file)
    end
  end

  def test_quiet_with_errors
    with_xml_file('bad.xml', INVALID_XML) do |file|
      stdout, stderr, status = run_xcop('--quiet', file)
      assert_match(/Invalid XML formatting/, stdout)
      assert_empty(stderr)
      assert_equal(1, status.exitstatus)
    end
  end

  def test_fix_mode
    with_xml_file('bad.xml', INVALID_XML) do |file|
      original = File.read(file)
      assert_fixed(file)
      refute_equal(original, File.read(file))
      assert_includes(File.read(file), '<?xml version="1.0"?>')
    end
  end

  def test_fix_mode_preserves_valid_files
    with_xml_file('good.xml', VALID_XML) do |file|
      original = File.read(file)
      assert_fixed(file)
      assert_equal(original, File.read(file))
    end
  end

  def test_fix_quiet
    with_xml_file('bad.xml', INVALID_XML) do |file|
      original = File.read(file)
      assert_quiet_run('--fix', '--quiet', file)
      refute_equal(original, File.read(file))
    end
  end

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

  def test_nonexistent_file
    stdout, stderr, status = run_xcop('nonexistent.xml')
    assert_empty(stdout)
    assert_includes(stderr, 'Path does not exist')
    assert_equal(1, status.exitstatus)
  end

  def test_multiple_files
    with_temp_dir do |dir|
      file1 = create_xml_in_dir(dir, 'first.xml', VALID_XML)
      file2 = create_xml_in_dir(dir, 'second.xml', VALID_XML)
      stdout, stderr, status = run_xcop(file1, file2)
      expected = ["#{file1} looks good", "#{file2} looks good"]
      actual = stdout.strip.split("\n")
      assert_equal(expected.sort, actual.sort)
      assert_empty(stderr)
      assert_equal(0, status.exitstatus)
    end
  end

  def test_mixed_files
    with_temp_dir do |dir|
      valid_file = create_xml_in_dir(dir, 'good.xml', VALID_XML)
      invalid_file = create_xml_in_dir(dir, 'bad.xml', INVALID_XML)
      stdout, stderr, status = run_xcop(valid_file, invalid_file)
      assert_includes(stdout, "#{valid_file} looks good")
      assert_match(/Invalid XML formatting in.*bad\.xml/, stdout)
      assert_empty(stderr)
      assert_equal(1, status.exitstatus)
    end
  end

  def test_file_permissions
    with_xml_file('readonly.xml', VALID_XML) do |file|
      File.chmod(0444, file)
      assert_looks_good(file)
    ensure
      File.chmod(0644, file) if File.exist?(file)
    end
  end

  def test_fix_readonly_file_fails_gracefully
    with_xml_file('readonly.xml', INVALID_XML) do |file|
      File.chmod(0444, file)
      stdout, stderr, status = run_xcop('--fix', file)
      assert_empty(stdout)
      assert_includes(stderr, 'Permission denied')
      assert_equal(1, status.exitstatus)
    ensure
      File.chmod(0644, file) if File.exist?(file)
    end
  end

  def test_unicode_content
    unicode_xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root>тест 测试 🚀</root>\n"
    with_xml_file('unicode.xml', unicode_xml) { |file| assert_looks_good(file) }
  end

  def test_no_arguments
    assert_quiet_run()
  end

  private

  def normalize_path(path)
    File.realpath(path)
  end

  def with_temp_dir
    Dir.mktmpdir { |dir| yield(dir) }
  end

  def with_xml_file(filename, content)
    with_temp_dir { |dir| yield(create_xml_in_dir(dir, filename, content)) }
  end

  def create_xml_in_dir(dir, filename, content)
    File.write(File.join(dir, filename), content)
    File.join(dir, filename)
  end

  def create_xml_in_subdir(dir, subdir, filename, content)
    FileUtils.mkdir_p(File.join(dir, subdir))
    create_xml_in_dir(File.join(dir, subdir), filename, content)
  end

  def create_file_in_dir(dir, filename, content)
    File.write(File.join(dir, filename), content)
    File.join(dir, filename)
  end

  def create_non_xml_file(dir, filename)
    create_file_in_dir(dir, filename, 'not xml')
  end

  def create_empty_subdir(dir, subdir)
    FileUtils.mkdir_p(File.join(dir, subdir))
    File.join(dir, subdir)
  end

  def create_config_file(dir, content)
    File.write(File.join(dir, '.xcop'), content)
  end

  def build_large_xml(items_count)
    content = "<?xml version=\"1.0\"?>\n<root>\n"
    items_count.times { |i| content += "  <item id=\"#{i}\">data</item>\n" }
    content + "</root>\n"
  end

  def run_xcop(*args)
    xcop_dir = File.join(__dir__, '..')
    xcop_path = File.join(xcop_dir, 'bin', 'xcop')
    absolute_args = args.map do |arg|
      if arg.start_with?('-')
        arg
      else
        begin
          File.absolute_path(arg)
        rescue Errno::ENOENT
          arg
        end
      end
    end
    Open3.capture3('bundle', 'exec', 'ruby', xcop_path, *absolute_args, chdir: xcop_dir)
  end

  def run_xcop_in_dir(dir, *args)
    xcop_dir = File.join(__dir__, '..')
    xcop_path = File.join(xcop_dir, 'bin', 'xcop')
    env = { 'BUNDLE_GEMFILE' => File.join(xcop_dir, 'Gemfile') }
    Open3.capture3(env, 'bundle', 'exec', 'ruby', xcop_path, *args, chdir: dir)
  end

  def assert_looks_good(file)
    stdout, stderr, status = run_xcop(file)
    assert_equal("#{file} looks good\n", stdout)
    assert_empty(stderr)
    assert_equal(0, status.exitstatus)
  end

  def assert_invalid_xml(file, pattern)
    stdout, stderr, status = run_xcop(file)
    assert_match(pattern, stdout)
    assert_empty(stderr)
    assert_equal(1, status.exitstatus)
  end

  def assert_fixed(file)
    stdout, stderr, status = run_xcop('--fix', file)
    assert_equal("#{file} fixed\n", stdout)
    assert_empty(stderr)
    assert_equal(0, status.exitstatus)
  end

  def assert_quiet_run(*args)
    stdout, stderr, status = run_xcop(*args)
    assert_empty(stdout)
    assert_empty(stderr)
    assert_equal(0, status.exitstatus)
  end

  def assert_success(*args)
    _, stderr, status = run_xcop(*args)
    assert_empty(stderr)
    assert_equal(0, status.exitstatus)
  end
end
