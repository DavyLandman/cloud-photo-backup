require 'set'

img_base_dir = "/Users/davy/Pictures/"
target_dir = "/Users/davy/Dropbox/Pictures Backup/"

puts "Checking input directory #{img_base_dir} for images to backup"
all_images = Dir.glob("#{img_base_dir}**/*.{jpg,jpeg,png,tiff,tif,psd}", File::FNM_CASEFOLD)
puts "Got #{all_images.size} amount of images to progress"

Action = Struct.new(:original, :target)

backup_actions = Set.new

all_images.each do |current_image|
  newFileName = current_image.gsub(img_base_dir, target_dir)
  newFileName += ".jpg" if (File.extname(newFileName).downcase != ".jpg")
  if !(File.exists?(newFileName)) && !(File.exists?(newFileName.gsub(".jpg", "-0.jpg")))
    ac = Action.new
    ac.original = current_image
    ac.target = newFileName
    backup_actions << ac
  end
end
puts "#{backup_actions.size} to actually backup"
