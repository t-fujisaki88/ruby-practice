# frozen_string_literal: true

require 'optparse'
require 'etc'

# 表示列の最大数をココで変更
COLUMN = 3

MODE_TABLE = {
  '01' => 'p',
  '02' => 'c',
  '04' => 'd',
  '06' => 'b',
  '10' => '-',
  '12' => 'l',
  '14' => 's',

  '0' => '',
  '1' => '--x',
  '2' => '-w-',
  '3' => '-wx',
  '4' => 'r--',
  '5' => 'r-x',
  '6' => 'rw-',
  '7' => 'rwx'
}.freeze

MONTH_TABLE = {
  '1' => 'Jan',
  '2' => 'Feb',
  '3' => 'Mar',
  '4' => 'Apr',
  '5' => 'May',
  '6' => 'Jun',
  '7' => 'Jul',
  '8' => 'Aug',
  '9' => 'Sep',
  '10' => 'Oct',
  '11' => 'Nov',
  '12' => 'Dec'
}.freeze

# 表示時に必要な行数rowを求める
def calc_row(num)
  (num % 3).zero? ? num / 3 : (num / 3) + 1
end

# ファイル一覧をlsのルールに従い表示
def display(files, row)
  row.times do |y|
    COLUMN.times { |x| printf(files[x * row + y].to_s.ljust(files.map(&:size).max + 3)) }
    puts
  end
end

# lオプションの機能：全体
def long_format_option(sorted_files)
  # ブロックの合計値
  total = sorted_files.size.times.sum do |i|
    File::Stat.new(sorted_files[i]).blocks.to_i
  end
  puts "total #{total}"

  # 各項目の最大文字数を求めるための一時記憶配列
  nlink_str_size = []
  uid_str_size = []
  gid_str_size = []
  filesize_str_size = []

  sorted_files.each do |sorted_file|
    fs = File::Stat.new(sorted_file)
    nlink_str_size << fs.nlink.to_s.size
    uid_str_size << Etc.getpwuid(fs.uid).name.to_s.size
    gid_str_size << Etc.getgrgid(fs.gid).name.to_s.size
    filesize_str_size << fs.size.to_s.size
  end

  nlink_blank = nlink_str_size.max
  uid_blank = uid_str_size.max
  gid_blank = gid_str_size.max
  filesize_blank = filesize_str_size.max

  blank = {"nlink": nlink_blank, "uid": uid_blank, "gid": gid_blank, "filesize": filesize_blank}
  long_format_option_make_contents(sorted_files, blank)
end

# lオプションの機能：文字列生成
def long_format_option_make_contents(sorted_files, blank)
  # 表示
  sorted_files.each do |sorted_file|
    fs = File::Stat.new(sorted_file)
    # 権限
    mode = ''
    permission_num = format('%06d', fs.mode.to_s(8)).split('')
    permission_num = [permission_num[0..1].join, permission_num[2..5]].flatten
    permission_num.each do |permission_part|
      mode += MODE_TABLE[permission_part]
    end

    long_format_option_display(fs, blank, mode)
    puts sorted_file
  end
end

# lオプションの機能：表示
def long_format_option_display(file_stats, blank, mode)
  print mode.ljust(12)
  print file_stats.nlink.to_s.rjust(blank[:nlink].to_i)
  print ' '
  print Etc.getpwuid(file_stats.uid).name.ljust(blank[:uid].to_i)
  print '  '
  print Etc.getgrgid(file_stats.gid).name.ljust(blank[:gid].to_i)
  print '  '
  print file_stats.size.to_s.rjust(blank[:filesize].to_i)
  print MONTH_TABLE[file_stats.mtime.to_a.slice(4).to_s].rjust(4)
  print file_stats.mtime.to_a.slice(3).to_s.rjust(3)
  print Time.now - file_stats.mtime < 15_552_000 ? file_stats.mtime.to_s.slice(11, 5).to_s.rjust(6) : file_stats.mtime.to_a.slice(5).to_s.rjust(6)
  print ' '
end

opt = OptionParser.new
params = {}

opt.on('-a') { |v| params[:a] = v }
opt.on('-l') { |v| params[:l] = v }
opt.on('-r') { |v| params[:r] = v }

opt.parse!(ARGV)

# -a option
files = params[:a] ? Dir.glob('*', File::FNM_DOTMATCH) : Dir.glob('*')
# -r option
sorted_files = params[:r] ? files.sort.reverse : files.sort
# -l option
params[:l] ? long_format_option(sorted_files) : display(sorted_files, calc_row(sorted_files.size))
