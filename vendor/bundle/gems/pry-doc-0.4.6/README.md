pry-doc
=======

(C) John Mair (banisterfiend) 2013

_Provides YARD and extended documentation support for Pry_

* Install the [gem](https://rubygems.org/gems/pry-doc): `gem install pry-doc`
* Read the [documentation](http://rdoc.info/github/pry/pry-doc/master/file/README.md)
* See the [source code](http://github.com/pry/pry-doc)

Example: Provide access to Ruby core documentation and source code from within Pry
--------

    [1] pry(main)> show-doc puts

    From: io.c (C Method):
    Owner: Kernel
    Visibility: private
    Signature: puts(*arg1)
    Number of lines: 3

    Equivalent to

        $stdout.puts(obj, ...)
    [2] pry(main)> show-source puts

    From: io.c (C Method):
    Owner: Kernel
    Visibility: private
    Number of lines: 8

    static VALUE
    rb_f_puts(int argc, VALUE *argv, VALUE recv)
    {
        if (recv == rb_stdout) {
        return rb_io_puts(argc, argv, recv);
        }
        return rb_funcall2(rb_stdout, rb_intern("puts"), argc, argv);
    }
    [3] pry(main)>

Contact
-------

Problems or questions contact me at [github](http://github.com/banister)


License
-------

(The MIT License)

Copyright (c) 2013 John Mair (banisterfiend)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
