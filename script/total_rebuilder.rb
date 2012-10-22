# coding: utf-8
require 'optparse'

options = {}
opt = OptionParser.new
opt.on('-e ENV', '--env=ENV', 'execute env, equal to PADRINO_ENV=env'){|v| options[:env] = v}
opt.on('-f FROM', '--from=FROM', 'totalize from this date to recent'){|v| options[:from] = v}
opt.on('-s', '--silent', 'silent (no output and no wait) mode, '){|v| options[:silent] = v}
opt.parse!(ARGV)

PADRINO_ENV = options[:env] if options[:env]
from =  lambda do |f|
  (f && f.match(/\A\d{8}\z/)) ? f : nil
end.call(options[:from])

unless options[:silent]
  puts '集計処理を全てやり直します'
  puts '　※データ量に応じてそれなりの時間がかかります'
  puts '　※既存の集計値は削除されます（手動で入力した結果を除く）'
  puts ''
  puts 'よろしければ y または Y を入力してEnterを押してください'

  ans = gets.chomp!
  unless ['y', 'Y'].include?(ans)
    puts '実行を中止しました'
    exit
  end
end

require File.expand_path("../../config/boot.rb", __FILE__)

exec = ROGv::TotalRebuilder.new
exec.from = from if from
exec.silent = true if options[:silent]
exec.execute

exit
