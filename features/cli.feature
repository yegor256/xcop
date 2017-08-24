Feature: Command Line Processing
  As an author of XML I want to be able to
  call XCOP as a command line tool

  Scenario: Help can be printed
    When I run bin/xcop with "-h"
    Then Exit code is zero
    And Stdout contains "--help"

  Scenario: Version can be printed
    When I run bin/xcop with "--version"
    Then Exit code is zero

  Scenario: Validating correct XML file
    Given I have a "test.xml" file with content:
    """
<?xml version="1.0"?>
<hello>Hello, world!</hello>

"""
    When I run bin/xcop with "test.xml"
    Then Stdout contains "OK"
    And Exit code is zero
    And Stdout contains "Validating test.xml..."

  Scenario: Validating incorrect XML file
    Given I have a "abc.xml" file with content:
    """
    <a><b>something</b>
    </a>
    """
    When I run bin/xcop with "abc.xml"
    Then Exit code is not zero
