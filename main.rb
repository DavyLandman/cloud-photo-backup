require 'set'
require 'fileutils'
require 'thread'

def getImages(img_base_dir)
  puts "Checking input directory #{img_base_dir} for images to backup"
  all_images = Dir.glob("#{img_base_dir}**/*.{jpg,jpeg,png,tiff,tif,psd}", File::FNM_CASEFOLD)
  puts "Got #{all_images.size} amount of images to progress"
  return all_images
end

def createJobs(all, img_base_dir, target_dir)
  backup_actions = Set.new

  all.each do |current_image|
    target_filename = current_image.gsub(img_base_dir, target_dir)
    target_filename += ".jpg"  unless /\.(jpg|jpeg)/.match(File.extname(target_filename).downcase)
       
    unless File.exists?(target_filename) || File.exists?(target_filename.gsub(".jpg", "-0.jpg"))
      backup_actions << BackupJob.new(current_image, target_filename) 
    end
  end

  return backup_actions
end

class BackupJob
  def initialize(original, target)
    @original = original
    @target = target
    @running = nil
  end

  def Run 
    dir = File.dirname(@target)
    FileUtils.mkpath(dir)  unless File.directory?(dir)
    `convert -interlace Plane -quality 85 -resize 1800x1800 \"#{@original}\" \"#{@target}\"`
  end

end


def runJobs(jobs, split = 4)
  queue = Queue.new
  jobs.each { |j| queue.push j }


  threads = []
  progress = 0.0

  split.times do
    threads << Thread.new do
      # loop until there are no more things to do
      until queue.empty?
        # pop with the non-blocking flag set, this raises
        # an exception if the queue is empty, in which case
        # work_unit will be set to nil
        work_unit = queue.pop(true) rescue nil
        if work_unit
          # do work
          work_unit.Run
          progress += 1
        end
      end
      # when there is no more work, the thread will stop
    end
  end

  last = 0
  jobs_size = jobs.size
  puts  "0%|#{(0..49).map{"_"}}|100%"
  STDOUT.sync = true
  print "   "
  until threads.map{ |t| t.join(0.05) }.all?
    step = (50 * (progress / jobs_size)).round
    print (last..step-1).map{"#"} 
    last = step
  end

  print (last..49).map{"#"} 
  puts "\nFinished"
end

#img_base_dir = "/Users/davy/Pictures/"
#target_dir = "/Users/davy/Dropbox/Pictures Backup/"
img_base_dir = "input/"
target_dir = "output/"

all = getImages(img_base_dir)
backup_actions = createJobs(all, img_base_dir, target_dir)
puts "#{backup_actions.size} to actually backup"

runJobs(backup_actions)  if backup_actions.size > 0
