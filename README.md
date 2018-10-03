# Fortigate Config Parser

A simple parser for Fortigate firewall configuration files.

This utility is written in Perl, it should run on most systems.

It taks as it's input a full Fortigate configuration file and parses
it into a single humungous hash. The hash can then use walked to find
configuration items and used by other programs to perform more complex
analysis and changes to the configutation.

