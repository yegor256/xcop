# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'open3'

# Integration tests for xcop bin functionality
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class TestBin < Minitest::Test
  def setup
    @bin_path = File.join(__dir__, '..', 'bin', 'xcop')
    @ruby_cmd = "bundle exec ruby -Ilib #{@bin_path}"
    @original_home = Dir.home
  end

  def teardown
    ENV['HOME'] = @original_home if @original_home
  end

  def run_xcop(args = '', expect_success: true, chdir: nil)
    cmd = "#{@ruby_cmd} #{args}"
    work_dir = chdir || File.join(__dir__, '..')
    stdout, stderr, status = Open3.capture3(cmd, chdir: work_dir)

    flunk "Command failed: #{cmd}\nSTDOUT: #{stdout}\nSTDERR: #{stderr}" if expect_success && !status.success?

    [stdout, stderr, status]
  end

  def run_xcop_expecting_failure(args = '', chdir: nil)
    stdout, stderr, status = run_xcop(args, expect_success: false, chdir: chdir)
    refute_predicate status, :success?, 'Command should have failed'
    [stdout, stderr, status]
  end

  def test_help_option
    stdout, = run_xcop('--help')
    assert_includes(stdout, 'Usage')
    assert_includes(stdout, 'xcop [options] [files...]')
  end

  def test_version_option
    stdout, = run_xcop('--version')
    assert_match(/\d+\.\d+\.\d+/, stdout.strip)
  end

  def test_process_valid_xml_file
    Dir.mktmpdir do |dir|
      xml_file = File.join(dir, 'test.xml')
      File.write(xml_file, "<?xml version=\"1.0\"?>\n<test>Content</test>\n")

      stdout, = run_xcop(xml_file)
      assert_includes(stdout, 'test.xml looks good')
    end
  end

  def test_process_invalid_xml_file
    Dir.mktmpdir do |dir|
      xml_file = File.join(dir, 'bad.xml')
      File.write(xml_file, '<test>Bad formatting</test>')

      stdout, stderr, = run_xcop_expecting_failure(xml_file)
      output = stdout + stderr
      assert_includes(output, 'Invalid XML formatting in')
    end
  end

  def test_process_directory
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'subdir'))
      File.write(File.join(dir, 'file.xml'), "<?xml version=\"1.0\"?>\n<test>Content</test>\n")
      File.write(File.join(dir, 'subdir', 'nested.xml'), "<?xml version=\"1.0\"?>\n<nested>Content</nested>\n")
      File.write(File.join(dir, 'readme.txt'), 'Not XML')

      stdout, = run_xcop(dir)
      assert_includes(stdout, 'file.xml looks good')
      assert_includes(stdout, 'nested.xml looks good')
      refute_includes(stdout, 'readme.txt')
    end
  end

  def test_exclude_pattern
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'include.xml'), "<?xml version=\"1.0\"?>\n<include>Content</include>\n")
      File.write(File.join(dir, 'exclude.xml'), "<?xml version=\"1.0\"?>\n<exclude>Content</exclude>\n")

      stdout, = run_xcop("#{dir} --exclude exclude.xml")
      assert_includes(stdout, 'include.xml looks good')
      refute_includes(stdout, 'exclude.xml')
    end
  end

  def test_fix_functionality
    Dir.mktmpdir do |dir|
      xml_file = File.join(dir, 'test.xml')
      File.write(xml_file, '<test>Needs fixing</test>')

      stdout, = run_xcop("#{xml_file} --fix")
      assert_includes(stdout, 'test.xml fixed')

      content = File.read(xml_file)
      assert_includes(content, '<?xml version="1.0"?>')
    end
  end
end
