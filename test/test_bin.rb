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
  end

  def run_xcop(args, expect_success: true)
    cmd = "#{@ruby_cmd} #{args}"
    stdout, stderr, status = Open3.capture3(cmd, chdir: File.join(__dir__, '..'))

    if expect_success && !status.success?
      flunk "Command failed: #{cmd}\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    end

    stdout
  end

  def run_xcop_expecting_failure(args)
    cmd = "#{@ruby_cmd} #{args}"
    stdout, stderr, status = Open3.capture3(cmd, chdir: File.join(__dir__, '..'))

    refute status.success?, "Command should have failed: #{cmd}"
    stdout + stderr
  end

  def test_process_single_file
    Dir.mktmpdir 'test_bin' do |dir|
      xml_file = File.join(dir, 'test.xml')
      File.write(xml_file, "<?xml version=\"1.0\"?>\n<test>Content</test>\n")

      output = run_xcop(xml_file)

      assert_includes(output, 'test.xml looks good')
    end
  end

  def test_process_directory
    Dir.mktmpdir 'test_bin' do |dir|
      subdir = File.join(dir, 'subdir')
      FileUtils.mkdir_p(subdir)

      xml_file = File.join(dir, 'file.xml')
      nested_xml = File.join(subdir, 'nested.xml')
      File.write(xml_file, "<?xml version=\"1.0\"?>\n<test>Content</test>\n")
      File.write(nested_xml, "<?xml version=\"1.0\"?>\n<nested>Content</nested>\n")

      output = run_xcop(dir)

      assert_includes(output, 'file.xml looks good')
      assert_includes(output, 'nested.xml looks good')
    end
  end

  def test_process_mixed_input
    Dir.mktmpdir 'test_bin' do |dir|
      subdir = File.join(dir, 'subdir')
      FileUtils.mkdir_p(subdir)

      individual_file = File.join(dir, 'individual.xml')
      nested_file = File.join(subdir, 'nested.xml')
      File.write(individual_file, "<?xml version=\"1.0\"?>\n<individual>Content</individual>\n")
      File.write(nested_file, "<?xml version=\"1.0\"?>\n<nested>Content</nested>\n")

      output = run_xcop("#{individual_file} #{subdir}")

      assert_includes(output, 'individual.xml looks good')
      assert_includes(output, 'nested.xml looks good')
    end
  end

  def test_ignores_non_xml_files
    Dir.mktmpdir 'test_bin' do |dir|
      File.write(File.join(dir, 'readme.txt'), 'Not XML')
      File.write(File.join(dir, 'script.rb'), 'puts "Hello"')

      output = run_xcop(dir)

      assert_equal('', output.strip)
    end
  end

  def test_nonexistent_path_shows_error
    output = run_xcop_expecting_failure('/nonexistent/path')
    assert_includes(output, 'Path does not exist')
  end

  def test_exclude_by_filename
    Dir.mktmpdir 'test_bin' do |dir|
      FileUtils.mkdir_p(File.join(dir, 'src'))
      FileUtils.mkdir_p(File.join(dir, 'test'))
      File.write(File.join(dir, 'src', 'main.xml'), "<?xml version=\"1.0\"?>\n<main>Content</main>\n")
      File.write(File.join(dir, 'test', 'test1.xml'), "<?xml version=\"1.0\"?>\n<test>Content</test>\n")
      File.write(File.join(dir, 'test', 'test2.xml'), "<?xml version=\"1.0\"?>\n<test>Content</test>\n")

      output = run_xcop("#{dir} --exclude test1.xml")

      assert_includes(output, 'main.xml looks good')
      assert_includes(output, 'test2.xml looks good')
      refute_includes(output, 'test1.xml')
    end
  end

  def test_exclude_by_directory_pattern
    Dir.mktmpdir 'test_bin' do |dir|
      FileUtils.mkdir_p(File.join(dir, 'src'))
      FileUtils.mkdir_p(File.join(dir, 'test'))
      FileUtils.mkdir_p(File.join(dir, 'config'))
      File.write(File.join(dir, 'src', 'main.xml'), "<?xml version=\"1.0\"?>\n<main>Content</main>\n")
      File.write(File.join(dir, 'test', 'test1.xml'), "<?xml version=\"1.0\"?>\n<test>Content</test>\n")
      File.write(File.join(dir, 'test', 'test2.xml'), "<?xml version=\"1.0\"?>\n<test>Content</test>\n")
      File.write(File.join(dir, 'config', 'settings.xml'), "<?xml version=\"1.0\"?>\n<config>Content</config>\n")

      output = run_xcop("#{dir} --exclude '**/test/**'")

      assert_includes(output, 'main.xml looks good')
      assert_includes(output, 'settings.xml looks good')
      refute_includes(output, 'test1.xml')
      refute_includes(output, 'test2.xml')
    end
  end

  def test_exclude_multiple_patterns
    Dir.mktmpdir 'test_bin' do |dir|
      FileUtils.mkdir_p(File.join(dir, 'src'))
      FileUtils.mkdir_p(File.join(dir, 'test'))
      FileUtils.mkdir_p(File.join(dir, 'config'))
      File.write(File.join(dir, 'src', 'main.xml'), "<?xml version=\"1.0\"?>\n<main>Content</main>\n")
      File.write(File.join(dir, 'test', 'test1.xml'), "<?xml version=\"1.0\"?>\n<test>Content</test>\n")
      File.write(File.join(dir, 'config', 'settings.xml'), "<?xml version=\"1.0\"?>\n<config>Content</config>\n")

      output = run_xcop("#{dir} --exclude test1.xml --exclude settings.xml")

      assert_includes(output, 'main.xml looks good')
      refute_includes(output, 'test1.xml')
      refute_includes(output, 'settings.xml')
    end
  end

  def test_fix_functionality_with_directory
    Dir.mktmpdir 'test_bin' do |dir|
      FileUtils.mkdir_p(File.join(dir, 'src'))
      FileUtils.mkdir_p(File.join(dir, 'test'))

      # Create badly formatted XML files
      File.write(File.join(dir, 'src', 'main.xml'), '<main><content>needs fixing</content></main>')
      File.write(File.join(dir, 'test', 'test1.xml'), '<test><case>also needs fixing</case></test>')

      output = run_xcop("#{dir} --exclude '**/test/**' --fix")

      assert_includes(output, 'main.xml fixed')
      refute_includes(output, 'test1.xml')

      # Verify the file was actually fixed
      content = File.read(File.join(dir, 'src', 'main.xml'))
      assert_includes(content, '<?xml version="1.0"?>')

      # Verify excluded file was not touched
      test_content = File.read(File.join(dir, 'test', 'test1.xml'))
      refute_includes(test_content, '<?xml version="1.0"?>')
    end
  end

  def test_include_pattern_with_directory
    Dir.mktmpdir 'test_bin' do |dir|
      FileUtils.mkdir_p(File.join(dir, 'src'))
      FileUtils.mkdir_p(File.join(dir, 'docs'))

      File.write(File.join(dir, 'src', 'main.xml'), "<?xml version=\"1.0\"?>\n<main>Content</main>\n")
      File.write(File.join(dir, 'docs', 'guide.xml'), "<?xml version=\"1.0\"?>\n<docs>Content</docs>\n")

      output = run_xcop("--include '#{dir}/docs/*.xml' #{dir}/src/")

      assert_includes(output, 'main.xml looks good')
      assert_includes(output, 'guide.xml looks good')
    end
  end

  def test_quiet_mode
    Dir.mktmpdir 'test_bin' do |dir|
      File.write(File.join(dir, 'test.xml'), "<?xml version=\"1.0\"?>\n<test>Content</test>\n")

      output = run_xcop("#{dir} --quiet")

      assert_equal('', output.strip)
    end
  end
end
