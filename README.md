Pronto Inspec
=============
[Pronto](https://github.com/prontolabs/pronto) Runner for Inspec tests.

How-To:
-------

Create a .pronto-inspec.yml where your kitchen file is and specify which suites should be run if which file has been changed.


For example: `files: ['test/setup.rb']`


You can also specify `files: ['*']` to run the suite in any case.

Requirements:
-------------

The format for the inspec-verifier has to be set to: `format: junit`.


`chef`, `test-kitchen` and `inspec` all need to be installed and configured-

Usage:
------

pronto run -r inspec
