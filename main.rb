require 'set'


imgBaseDir = "/Users/davy/Pictures/"
targetDir = "/Users/davy/Dropbox/Pictures Backup/"

allImages = Dir.glob("#{imgBaseDir}**/*.{jpg,jpeg,png,tiff,tif,psd}", File::FNM_CASEFOLD)
puts "Got #{allImages.size} amount of images to progress"

Action = Struct.new(:original, :target)

backupActions = Set.new

allImages.each do |currentImage|
	newFileName = currentImage.gsub(imgBaseDir, targetDir)
	newFileName += ".jpg" if (File.extname(newFileName).downcase != ".jpg")
	if !(File.exists?(newFileName)) && !(File.exists?(newFileName.gsub(".jpg", "-0.jpg")))
		ac = Action.new
		ac.original = currentImage
		ac.target = newFileName
		backupActions << ac
	end
end
puts "#{backupActions.size} to actually backup"
