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

def add_total(d)
  raise 'not exist date' unless ROGv::Situation.date_list.include?(d)
  ROGv::Situation.repair_duplication!(d)
  wr = ROGv::WeeklyResult.for_date(d)
  wr ||= ROGv::WeeklyResult.analyze_for(d)
  raise 'totalize failed' unless wr
  wr.save! if wr.new_record?
  ROGv::TotalResult.add_result_to_all_total!(d)
  ROGv::FortResult.add_result(d)
end

if date
  add_total(date)
else
  last_date = ROGv::TotalResult.all_total.gv_dates.max
  dlist = ROGv::Situation.date_list.select{|d| d > last_date}
  dlist.each{|d| add_total(d)}
end

exit
