<img alt="XCOP logo" src="/logo.svg" width="64px"/>

[![EO principles respected here](https://www.elegantobjects.org/badge.svg)](https://www.elegantobjects.org)
[![DevOps By Rultor.com](https://www.rultor.com/b/yegor256/xcop)](https://www.rultor.com/p/yegor256/xcop)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/xcop/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/xcop/actions/workflows/rake.yml)
[![PDD status](https://www.0pdd.com/svg?name=yegor256/xcop)](https://www.0pdd.com/p?name=yegor256/xcop)
[![Gem Version](https://badge.fury.io/rb/xcop.svg)](https://badge.fury.io/rb/xcop)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/xcop/blob/master/LICENSE.txt)
[![Maintainability](https://api.codeclimate.com/v1/badges/396ec0584e0a84adc723/maintainability)](https://codeclimate.com/github/yegor256/xcop/maintainability)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/xcop.svg)](https://codecov.io/github/yegor256/xcop?branch=master)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/xcop)](https://hitsofcode.com/view/github/yegor256/xcop)

This command line tool validates your XML files for proper formatting.
If they are not formatted correctly, it prints the difference and
exits with an error. You can use it in two ways: 1) to fail your build
if any XML-ish files (for example, XML, XSD, XSL, or XHTML) are not formatted correctly,
and 2) to format them correctly using the `--fix` option.

Read this blog post first:
[_XCOP—XML Style Checker_](https://www.yegor256.com/2017/08/29/xcop.html).

Make sure you have [Ruby installed](https://www.ruby-lang.org/en/documentation/installation/)
and then install the tool:

```bash
$ gem install xcop
```

Run it locally and read its output:

```bash
$ xcop --help
```

To validate formatting of your XML files just pass their names
as arguments:

```bash
$ xcop file1.xml file2.xml
```

If your files are not formatted correctly and `xcop` complains, you
can ask it to "beautify" them using the `--fix` option:

```bash
$ xcop --fix broken-file.xml
```

To fix all files in a directory, you can do the following
([this won't work](https://askubuntu.com/questions/343727/) if your file names contain spaces):

```bash
$ xcop --fix $(find . -name '*.xml')
```

## Defaults

You can put command line options into a `.xcop` file in the directory
where you start `xcop`. Each option should take a single line in the file.
They will all be _added_ to the list of options you specify. For example,
as suggested in [this blog post](https://www.yegor256.com/2022/07/20/command-line-defaults.html):

```
--nocolor
--quiet
--include=**/*
--exclude=**/*.xsl
--exclude=**/*.html
```

You can also create `~/.xcop` file (in your personal home directory), which
will also be read and _added_ to the command line options.

## How to use in `Rakefile`?

This is what you need there:

```ruby
require 'xcop/rake_task'
desc 'Run XCop on all XML/XSL files in all directories'
Xcop::RakeTask.new(:xcop) do |task|
  task.quiet = true # FALSE by default
  task.includes = ['**/*.xml', '**/*.xsl'] # xml|xsd|xhtml|xsl|html by default
  task.excludes = ['target/**/*'] # empty by default
end
```

## How to use as GitHub action?

Create a new workflow file in your repository under `.github/workflows/xcop.yml`:

```yaml
---
name: XCOP
"on":
  # run on push to master events
  push:
    branches:
      - master
  # run on pull requests to master
  pull_request:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: g4s8/xcop-action@master
```

To customize the files pattern, use the `files` parameter:

```yaml
- uses: g4s8/xcop-action@master
  with:
    files: "src/*.xml"
```

## How to use in Maven `pom.xml`?

You can integrate it with the help of
[maven-antrun-plugin](http://maven.apache.org/plugins/maven-antrun-plugin/):

```xml
<project>
  [...]
  <build>
    [...]
    <plugins>
      [...]
      <plugin>
        <artifactId>maven-antrun-plugin</artifactId>
        <version>1.8</version>
        <executions>
          <execution>
            <phase>verify</phase>
            <configuration>
              <target>
                <apply executable="xcop" failonerror="true">
                  <fileset dir=".">
                    <include name="**/*.xml"/>
                    <include name="**/*.xsd"/>
                    <exclude name="target/**/*"/>
                    <exclude name=".idea/**/*"/>
                  </fileset>
                </apply>
              </target>
            </configuration>
            <goals>
              <goal>run</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

## How to use in Ant `project.xml`?

Something like this should work:

```xml
<project>
  [...]
  <target name="xcop">
    <apply executable="xcop" failonerror="true">
      <fileset dir=".">
        <include name="**/*.xml"/>
        <include name="**/*.xsd"/>
        <exclude name="target/**/*"/>
        <exclude name=".idea/**/*"/>
      </fileset>
    </apply>
  </target>
</project>
```

## How to contribute

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure your build is green before you contribute
your pull request. You will need to have [Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```
$ bundle update
$ bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.
