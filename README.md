Pronto Inspec
=============
[Pronto](https://github.com/prontolabs/pronto) Runner for Inspec tests.

How-To:
-------

Create a .pronto-inspec.yml where your kitchen file is and specify which suites should be run if which file has been changed.


To trigger the suite only if specifc files have been changed use : `files: ['my/cookbook/specifc_file.rb']`

By using `files: ['my/cookbook/*']` the suite defined for this `files` will be used if any file has been changed.

You can also specify `files: ['**']` to run the suite in any case.

I would also advise to always trigger the suite if any test cases in that suite have changed, e.g. `files: [test/my_tests_for_suite/*a]`

Example:
--------

See [this example file](.pronto-inspec.sample.yml)

Usage:
------

pronto run -r inspec

Requirements:
-------------

The format for the inspec-verifier has to be set to: `format: junit`.


`chef`, `test-kitchen` and `inspec` all need to be installed and configured-
