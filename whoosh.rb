require 'pathname'
require 'fileutils'
# require 'dir'
# require 'file'

$base_path = Pathname.new(ARGV[0]).realpath
$target_path = Pathname.new(ARGV[1]).realpath
$refactors = Hash.new


def resolve_import(import, resource)
    saved_import = import

    if import.start_with? "."
        path_parts = resource["path"].realpath.to_path.split File::SEPARATOR

        while import.start_with? "." do
            path_parts.pop
            import = import[1..-1]
        end
    else
        path_parts = $base_path.split
    end

    path_parts.concat import.split "."
    path = File.join *path_parts

    if File.directory? path
        path = File.join path, "__init__"
    end

    path += ".py"
    if $refactors.has_key? path
        return $refactors[path]["new_name"].chomp(".py")
    end

    return saved_import
end

def fix_line(line, data)
    m = line.match(/from ([a-z\.\_].*) import/i)
    if m != nil
        return line.sub(m[1], resolve_import(m[1], data)), nil
    end

    m = line.match(/import ([a-z\.\_].*)/i)
    if m != nil
        resolved = resolve_import(m[1], data)
        return line.sub(m[1], resolved), [m[1], resolved]
    end

    return line, nil
end

puts "Discovering files in #{$base_path}"

Dir.glob(File.join($base_path, "**/*.py")) do |file|
    path = Pathname.new file
    relative = path.relative_path_from $base_path

    $refactors[path.realpath.to_path] = {
        "path" => path,
        "parts" => relative.split(),
        "new_name" => relative.to_path.gsub(File::SEPARATOR, '_')
    }
end

puts "Refactoring files to target directory #{$target_path}"

FileUtils.mkdir_p $target_path
$refactors.each do |path, data|
    File.open(File.join($target_path, data["new_name"]), "w") do |target|
        trickles = Hash.new
        File.readlines(path).each do |line|
            output, trickle = fix_line(line, data)
            
            if trickle != nil
                trickles[trickle[0]] = trickle[1]
            end
            trickles.each do |find, replace|
                output.sub! find, replace
            end

            target.puts output
        end
    end
    
    puts "    Refactored #{path}"
end
