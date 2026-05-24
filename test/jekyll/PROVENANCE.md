# Jekyll Compatibility Fixtures

These tests adapt behavior scenarios from Jekyll's upstream Cucumber feature
suite, especially `features/create_sites.feature`.

Source: https://github.com/jekyll/jekyll

Jekyll is licensed under the MIT License:

Copyright (c) 2008-present Tom Preston-Werner and Jekyll contributors

The tests here are not a verbatim copy of Jekyll's Ruby/Cucumber harness. They
are small POSIX shell fixtures that preserve the user-visible behavior being
tested so `posix-pages` can track compatibility without depending on Ruby.
