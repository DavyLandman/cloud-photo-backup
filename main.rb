require 'set'



class BackupJob
  def initialize(original, target)
    @original = original
    @target = target
  end
end

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

img_base_dir = "/Users/davy/Pictures/"
target_dir = "/Users/davy/Dropbox/Pictures Backup/"

all = getImages(img_base_dir)
backup_actions = createJobs(all, img_base_dir, target_dir)

puts "#{backup_actions.size} to actually backup"
