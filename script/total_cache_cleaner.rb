# coding: utf-8
require 'optparse'

options = {}
opt = OptionParser.new
opt.on('-e ENV', '--env=ENV', 'execute env, equal to PADRINO_ENV=env'){|v| options[:env] = v}
opt.parse!(ARGV)

PADRINO_ENV = options[:env] if options[:env]

require File.expand_path("../../config/boot.rb", __FILE__)

ROGv::TotalResult.caches.each(&:destroy)

exit
