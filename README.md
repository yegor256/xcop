[![Managed by Zerocracy](http://www.zerocracy.com/badge.svg)](http://www.zerocracy.com)
[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/xcop)](http://www.rultor.com/p/yegor256/xcop)
[![We recommend RubyMine](http://img.teamed.io/rubymine-recommend.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/yegor256/xcop.svg)](https://travis-ci.org/yegor256/xcop)
[![Build status](https://ci.appveyor.com/api/projects/status/orvfo2qgmd1d7a2i?svg=true)](https://ci.appveyor.com/project/yegor256/xcop)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/xcop)](http://www.0pdd.com/p?name=yegor256/xcop)
[![Gem Version](https://badge.fury.io/rb/xcop.svg)](http://badge.fury.io/rb/xcop)
[![Dependency Status](https://gemnasium.com/yegor256/xcop.svg)](https://gemnasium.com/yegor256/xcop)
[![Code Climate](http://img.shields.io/codeclimate/github/yegor256/xcop.svg)](https://codeclimate.com/github/yegor256/xcop)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/xcop.svg)](https://codecov.io/github/yegor256/xcop?branch=master)

## What this is for?

This command line tool validates your XML files for proper formatting.
If they are not formatted correctly, it prints the difference and
returns with an error. You can use it two ways: 1) to fail your build
if any X-like files (XML, XSD, XSL, XHTML) are not formatted correctly,
and 2) to format them correctly.

## How to install?

Install it first:

```bash
$ gem install xcop
```

## How to run?

Run it locally and read its output:

```bash
$ xcop --help
```

## How to contribute?

Just submit a pull request. Make sure `rake` passes.

## License

(The MIT License)

Copyright (c) 2017 Yegor Bugayenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
