require 'set'
require 'fileutils'

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

  def start
    puts "From #{@original} to #{@target}"
    dir = File.dirname(@target)
    FileUtils.mkpath(dir)  unless File.directory?(dir)
    @running ||= IO.popen("convert -resize 1800x1800 \"#{@original}\" \"#{@target}\"")
  end

  def finished?
    IO.select([@running], nil, nil, 0.1) and @running.eof?
  end
end

#img_base_dir = "/Users/davy/Pictures/"
#target_dir = "/Users/davy/Dropbox/Pictures Backup/"
img_base_dir = "input/"
target_dir = "output/"

all = getImages(img_base_dir)
backup_actions = createJobs(all, img_base_dir, target_dir)

backup_actions.each do |a|
  a.start
  puts "waiting for it to finish"
  while !a.finished?
    sleep 0.1
    puts "waiting"
  end
end

puts "#{backup_actions.size} to actually backup"
