require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib ri_cal]))
require 'cgi'

module Kernel
  def rputs(*args)
    puts *["<pre>", args.collect {|a| CGI.escapeHTML(a.to_s)}, "</pre>"] #if RiCal.debug
  end
end
