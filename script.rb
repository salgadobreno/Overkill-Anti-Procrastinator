#!/usr/bin/ruby
require 'rubygems'
require 'tempfile'
require 'fileutils'
require 'observer'
require 'ruby-debug'


class TimeNotifier
  #"09:30:00..11:30:00"
  #"12:00:00..14:00:00"
  #"14:30:00..16:30:00"
  #"17:00:00..19:00:00"

  CLOSED = [["09:30", "11:30"],["12","14"], ["14:30","16:30"], ["17:00","19:00"]]
  BLOCKS = ["twitter.com", "facebook.com", "www.facebook.com","9gag.com", "g1.com.br", "globoesporte.com", "globoesporte.globo.com", "g1.globo.com"]

  def update(actual_time)
    ranges = get_ranges(CLOSED)
    success = false
    ranges.each do |r|
      if r.include? actual_time
        disable_procrastinators() unless @procrastination_disabled
        @procrastination_disabled = true
        @procrastination_enabled = nil
        success = true
      end
      break if success
    end
    unless success
      enable_procrastinators() unless @procrastination_enabled
      @procrastination_enabled = true
      @procrastination_disabled = nil
    end
  end

  private

  def disable_procrastinators
    p "procrastinators disabled"
    system("notify-send #{5000} 'Procrastinators disabled.'")

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

    FileUtils.mv temp.path, "/etc/hosts"
    FileUtils.chmod(0644, "/etc/hosts")
  end

  def enable_procrastinators
    p "procrastinators enabled"
    system("notify-send -t #{5000} 'Procrastinators enabled.'")

    temp = Tempfile.new('file')
    lines = File.open('/etc/hosts', 'r') do |f|
      f.readlines
    end
    regexp = "(" + BLOCKS.join("|") + ")"
    lines.reject! {|l| l =~ Regexp.new(regexp) }

    temp.puts lines
    temp.close

    FileUtils.mv temp.path, "/etc/hosts"
    FileUtils.chmod(0644, "/etc/hosts")
  end

  def get_ranges(ary)
    now = Time.now
    ranges = ary.map do |arr|
      arrr = arr.map do |t|
        Time.local(now.year, now.month, now.day, t[0..1].to_i, t[3..4].to_i)
      end
      arrr[0]..arrr[1]
    end
  end
end

class TimeFetcher < Time
  class << TimeFetcher
    include Observable
  end
    add_observer TimeNotifier.new

  def self.fetch_time
    time = now
    changed unless weekend?
    notify_observers time
  end

  def weekend?
    [6,7].include?(wday)
  end
end

loop do
  TimeFetcher.fetch_time()
  sleep 60
end
