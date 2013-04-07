# coding: utf-8
require 'optparse'

options = {}
opt = OptionParser.new
opt.on('-e ENV', '--env=ENV', 'execute env, equal to PADRINO_ENV=env'){|v| options[:env] = v}
opt.on('-f DATE', '--from=DATE', 'export from DATE'){|v| options[:from] = v}
opt.on('-t DATE', '--to=DATE', 'export to DATE'){|v| options[:to] = v}
opt.parse!(ARGV)

PADRINO_ENV = options[:env] if options[:env]

require File.expand_path("../../config/boot.rb", __FILE__)

def date_parse(d)
  d && d.match(/\A\d{8}\z/) ? d : nil
end

sdate = date_parse(options[:from])
edate = date_parse(options[:to])

exec = ROGv::Exporter.new
exec.start_date = sdate if sdate
exec.end_date = edate if edate
exec.execute

exit
