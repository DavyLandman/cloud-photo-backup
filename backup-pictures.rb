#!/usr/bin/env ruby
require 'set'
require 'fileutils'
require 'thread'
require 'optparse'

def getImages(img_base_dir)
  puts "Checking input directory #{img_base_dir} for images to backup"
  all_images = Dir.glob("#{img_base_dir}**/*.{jpg,jpeg,png,tiff,tif,psd}", File::FNM_CASEFOLD)
  puts "Got #{all_images.size} amount of images to progress"
  return all_images
end

def createJobs(all, size, img_base_dir, target_dir)
  backup_actions = Set.new

  all.each do |current_image|
    target_filename = current_image.gsub(img_base_dir, target_dir)
    target_filename += ".jpg"  unless /\.(jpg|jpeg)/.match(File.extname(target_filename).downcase)
       
    unless File.exists?(target_filename) || File.exists?(target_filename.gsub(".jpg", "-0.jpg"))
      backup_actions << BackupJob.new(current_image, target_filename, size) 
    end
  end

  return backup_actions
end

class BackupJob
  def initialize(original, target, size)
    @original = original
    @target = target
    @size = size
  end

  def Run 
    dir = File.dirname(@target)
    FileUtils.mkpath(dir)  unless File.directory?(dir)
    `convert -interlace Plane -quality 85 -resize #{@size}x#{@size} \"#{@original}\" \"#{@target}\"`
  end

end

def genc(amount, c)
  "#{(0..amount-1).map{c}}"
end

def printProgress(prog)
  progb = (50*prog).round
  print "Progress: [#{genc(progb,"=")}#{genc(50-progb," ")}] #{(100*prog).round}%\r"
end

def runJobs(jobs, split)
  queue = Queue.new
  jobs.each { |j| queue.push j }


  threads = []
  jobs_finished = 0.0

  split.times do
    threads << Thread.new do
      until queue.empty?
        # pop with the non-blocking flag set, this raises
        # an exception if the queue is empty, in which case
        # work_unit will be set to nil
        work_unit = queue.pop(true) rescue nil
        if work_unit
          work_unit.Run
          jobs_finished += 1
        end
      end
    end
  end

  last = 0.0
  jobs_size = jobs.size
  STDOUT.sync = true
  printProgress(0)
  until threads.map{ |t| t.join(0.1) }.all?
    prog = (jobs_finished / jobs_size)
    printProgress(prog) if prog > last
    last = prog 
  end
  printProgress(1.0)
  puts "\nFinished"
end


options = {}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: backup-pictures.rb [options] source-folder target-folder"

  options[:cores] = 4 
  opts.on( '-c', '--cores NUM', Integer, 'Number of cpu cores to use (default 4)' ) do |c|
    options[:cores] = c
  end

  options[:size] = 152
  opts.on( '-s', '--size MM', Integer, 'Longest edge size in milimeters (default 152mm for 10x15 format)' ) do |c|
    options[:size] = c
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse! # remove options

if ARGV.size != 2
  puts "Please provide source and target folder"
  puts optparse.help
  exit
end
ARGV.each { |d| optparse.abort("#{d} is not a valid directory")  if not File.directory?(d)}
img_base_dir = ARGV[0]
target_dir = ARGV[1]
optparse.abort("I have no write rights in #{target_dir}, fix rights or run as a different user.") if not File.writable?(target_dir)


target_size = (((options[:size] / 25.4) * 300) /100).ceil * 100


all = getImages(img_base_dir)
backup_actions = createJobs(all, target_size, img_base_dir, target_dir)
puts "#{backup_actions.size} to actually backup"

runJobs(backup_actions, options[:cores])  if backup_actions.size > 0
