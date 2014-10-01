require 'pathname'
require 'fileutils'
require_relative 'pymodule'

$base_path = Pathname.new(ARGV[0]).realpath
$target_path = Pathname.new(ARGV[1]).realpath
$refactors = Hash.new


puts "Discovering files in #{$base_path}"

Dir.glob(File.join($base_path, "**/*.py")) do |file|
    path = Pathname.new file
    

    $refactors[path.realpath.to_path] = PythonModule.new path
end

puts "Refactoring files to target directory #{$target_path}"

FileUtils.mkdir_p $target_path
$refactors.each do |path, mod|
    File.open(File.join($target_path, mod.get_new_name), "w") do |target|
        mod.parsed do |output|
            target.puts output
        end
    end
    
    puts "    Refactored #{path}"
end
