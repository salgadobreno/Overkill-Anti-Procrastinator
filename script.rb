require 'rubygems'
require 'tempfile'
require 'date'
require 'fileutils'
require 'observer'
require 'ruby-debug'


class TimeNotifier
  #"09:30:00..11:30:00"
  #"12:00:00..14:00:00"
  #"14:30:00..16:30:00"
  #"17:00:00..19:00:00"

  CLOSED = [["09:30", "11:30"],["12","14"], ["14:30","16:30"], ["17:00","19:00"]]
  BLOCKS = ["twitter.com", "facebook.com", "9gag.com", "g1.com.br", "globoesporte.com"]

  def update(actual_time)
    p "update"
    ranges = get_ranges(CLOSED)
    success = false
    ranges.each do |r|
      if r === actual_time
        disable_procrastinators() unless @procrastination_disabled
        @procrastination_disabled = true
        @procrastination_enabled = nil
        success = true
        break
      else
        enable_procrastinators() unless @procrastination_enabled
        @procrastination_enabled = true
        @procrastination_disabled = nil
        success = true
      end
      break if success
      p @procrastination_enabled
      p @procrastination_disabled
    end
  end

  private

  def disable_procrastinators
    p "procrastinators disabled"

    temp = Tempfile.new('file')
    lines = File.open('/etc/hosts', 'r') do |f|
      f.readlines
    end
    regexp = "(" + BLOCKS.join("|") + ")"
    lines.reject! {|l| l =~ Regexp.new(regexp) }

    BLOCKS.each do |block|
      temp.puts "127.0.0.1 #{block}"
    end
    temp.puts lines
    temp.close

    FileUtils.mv temp.path, "failou.txt"
  end

  def enable_procrastinators
    p "procrastinators enabled"

    temp = Tempfile.new('file')
    lines = File.open('/etc/hosts', 'r') do |f|
      f.readlines
    end
    regexp = "(" + BLOCKS.join("|") + ")"
    lines.reject! {|l| l =~ Regexp.new(regexp) }

    temp.puts lines
    temp.close

    FileUtils.mv temp.path, "failou.txt"
  end

  def get_ranges(ary)
    now = Time.now
    ranges = ary.map do |arr|
      arrr = arr.map do |t|
        DateTime.civil(now.year, now.month, now.day, t[0..1].to_i, t[3..4].to_i)
      end
      arrr[0]..arrr[1]
    end
  end
end

class ActualTime < DateTime
  class << ActualTime
    include Observable
  end
    add_observer TimeNotifier.new

  def self.fetch_time
    time = DateTime.now
    changed
    notify_observers time
  end
end

while true
  p "sleep"
  ActualTime.fetch_time()
  sleep 5
end


