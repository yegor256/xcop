# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'

bin_file_content = File.read(File.join(__dir__, '..', 'bin', 'xcop'))
functions_code = bin_file_content.split('args = config')[0]
functions_code = functions_code.split('def config').drop(1).join('def config')
functions_code = "def config#{functions_code}"
eval(functions_code)

class TestBinFunctions < Minitest::Test
  def test_expand_single_file
    Dir.mktmpdir 'test_bin' do |dir|
      xml_file = File.join(dir, 'test.xml')
      File.write(xml_file, "<?xml version=\"1.0\"?>\n<test>Content</test>\n")
      result = expand_directories_to_xml_files([xml_file])
      assert_equal(1, result.size)
      assert_includes(result, xml_file)
    end
  end

  def test_expand_directory
    Dir.mktmpdir 'test_bin' do |dir|
      subdir = File.join(dir, 'subdir')
      FileUtils.mkdir_p(subdir)
      xml_file = File.join(dir, 'file.xml')
      nested_xml = File.join(subdir, 'nested.xml')
      File.write(xml_file, "<?xml version=\"1.0\"?>\n<test>Content</test>\n")
      File.write(nested_xml, "<?xml version=\"1.0\"?>\n<nested>Content</nested>\n")
      result = expand_directories_to_xml_files([dir])
      assert_equal(2, result.size)
      assert_includes(result, xml_file)
      assert_includes(result, nested_xml)
    end
  end

  def test_expand_mixed_input
    Dir.mktmpdir 'test_bin' do |dir|
      subdir = File.join(dir, 'subdir')
      FileUtils.mkdir_p(subdir)
      individual_file = File.join(dir, 'individual.xml')
      nested_file = File.join(subdir, 'nested.xml')
      File.write(individual_file, "<?xml version=\"1.0\"?>\n<individual>Content</individual>\n")
      File.write(nested_file, "<?xml version=\"1.0\"?>\n<nested>Content</nested>\n")
      result = expand_directories_to_xml_files([individual_file, subdir])
      assert_equal(2, result.size)
      assert_includes(result, individual_file)
      assert_includes(result, nested_file)
    end
  end

  def test_expand_ignores_non_xml
    Dir.mktmpdir 'test_bin' do |dir|
      File.write(File.join(dir, 'readme.txt'), 'Not XML')
      File.write(File.join(dir, 'script.rb'), 'puts "Hello"')
      result = expand_directories_to_xml_files([dir])
      assert_equal(0, result.size)
    end
  end

  def test_expand_nonexistent_throws_error
    assert_raises(RuntimeError) do
      expand_directories_to_xml_files(['/nonexistent/path'])
    end
  end

  def test_exclude_no_patterns
    files = ['/src/main.xml', '/test/test1.xml']
    result = apply_exclude_patterns(files, [])
    assert_equal(2, result.size)
    assert_includes(result, '/src/main.xml')
    assert_includes(result, '/test/test1.xml')
  end

  def test_exclude_by_filename
    files = ['/src/main.xml', '/test/test1.xml', '/test/test2.xml']
    result = apply_exclude_patterns(files, ['test1.xml'])
    assert_equal(2, result.size)
    assert_includes(result, '/src/main.xml')
    assert_includes(result, '/test/test2.xml')
    refute_includes(result, '/test/test1.xml')
  end

  def test_exclude_by_directory_pattern
    files = ['/src/main.xml', '/test/test1.xml', '/test/test2.xml', '/config/settings.xml']
    result = apply_exclude_patterns(files, ['**/test/**'])
    assert_equal(2, result.size)
    assert_includes(result, '/src/main.xml')
    assert_includes(result, '/config/settings.xml')
    refute_includes(result, '/test/test1.xml')
    refute_includes(result, '/test/test2.xml')
  end

  def test_exclude_multiple_patterns
    files = ['/src/main.xml', '/test/test1.xml', '/config/settings.xml']
    result = apply_exclude_patterns(files, ['test1.xml', 'settings.xml'])
    assert_equal(1, result.size)
    assert_includes(result, '/src/main.xml')
    refute_includes(result, '/test/test1.xml')
    refute_includes(result, '/config/settings.xml')
  end

  def test_integration_expand_and_exclude
    Dir.mktmpdir 'test_bin' do |dir|
      src_dir = File.join(dir, 'src')
      test_dir = File.join(dir, 'test')
      FileUtils.mkdir_p([src_dir, test_dir])
      main_file = File.join(src_dir, 'main.xml')
      test_file = File.join(test_dir, 'test1.xml')
      File.write(main_file, "<?xml version=\"1.0\"?>\n<main>Content</main>\n")
      File.write(test_file, "<?xml version=\"1.0\"?>\n<test>Content</test>\n")
      expanded = expand_directories_to_xml_files([dir])
      result = apply_exclude_patterns(expanded, ['**/test/**'])
      assert_equal(1, result.size)
      assert_includes(result, main_file)
      refute_includes(result, test_file)
    end
  end
end
