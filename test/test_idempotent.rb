# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/xcop/document'

# Tests that already-canonical documents survive --fix untouched.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2026 Yegor Bugayenko
# License:: MIT
class IdempotentTest < Minitest::Test
  FIXTURES = File.expand_path('../fixtures/idempotent', __dir__).freeze

  def test_fixtures_directory_is_not_empty
    refute_empty(
      Dir.glob(File.join(FIXTURES, '*.xml')),
      'Idempotent fixtures cannot be absent from the fixtures directory'
    )
  end

  Dir.glob(File.join(FIXTURES, '*.xml')).sort.each do |fixture|
    define_method("test_#{File.basename(fixture, '.xml').tr('-', '_')}_survives_fix_unchanged") do
      Dir.mktmpdir('idempotent') do |dir|
        copy = File.join(dir, File.basename(fixture))
        FileUtils.cp(fixture, copy)
        before = File.read(copy)
        Xcop::Document.new(copy).fix
        assert_equal(
          before,
          File.read(copy),
          "Idempotent fixture #{File.basename(fixture)} must not be changed by --fix"
        )
      end
    end
  end
end
