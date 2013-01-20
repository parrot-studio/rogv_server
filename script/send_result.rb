# coding: utf-8
require 'optparse'

options = {}
opt = OptionParser.new
opt.on('-e ENV', '--env=ENV', 'execute env, equal to PADRINO_ENV=env'){|v| options[:env] = v}
opt.on('-d DATE', '--date=DATE', 'date of add total (this is usually unnecessary)'){|v| options[:date] = v}
opt.parse!(ARGV)

PADRINO_ENV = options[:env] if options[:env]
date =  lambda do |f|
  (f && f.match(/\A\d{8}\z/)) ? f : nil
end.call(options[:date])

require File.expand_path("../../config/boot.rb", __FILE__)

wr = if date
  ROGv::WeeklyResult.for_date(date)
else
  ROGv::WeeklyResult.sort(:gv_date.desc).first
end
exit unless wr

c = HTTPClient.new
res = c.post("http://#{ROGv::ServerSettings.viewer_target}/update", :result => wr.to_json)
raise "update error" unless HTTP::Status.successful?(res.status)

exit
