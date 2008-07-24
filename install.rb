require 'fileutils'

src = File.expand_path(File.join(File.dirname(__FILE__),'locales'))
dst = File.expand_path(File.join(File.dirname(__FILE__),'../../../app/'))

FileUtils.cp_r(src, dst, :verbose => true)
