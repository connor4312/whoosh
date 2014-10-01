class PythonModule
    def initialize(path)
        @path = path

        relative = path.relative_path_from $base_path
        @parts = relative.split()
        @new_name = relative.to_path.gsub(File::SEPARATOR, '_')
        @trickles = {}
    end

    def get_new_name
        @new_name
    end

    def get_path
        @path
    end

    def parsed
        File.readlines(@path).each do |line|
            yield parse_line(line)
        end
    end

    def make_import_path(import)
        if import.start_with? "."
            path_parts = @path.realpath.to_path.split File::SEPARATOR

            while import.start_with? "." do
                path_parts.pop
                import = import[1..-1]
            end
        else
            path_parts = $base_path.split
        end

        path_parts.concat import.split(".")
        path = File.join *path_parts

        if File.directory? path
            path = File.join path, "__init__"
        end

        path += ".py"
    end

    def resolve_import(import)
        path = make_import_path import

        if $refactors.has_key? path
            return $refactors[path].get_new_name.chomp ".py"
        end

        return import
    end

    def handle_imports(line)

        m = line.match(/from ([a-z\.\_].*) import/i)
        if m != nil
            return line.sub m[1], resolve_import(m[1])
        end

        m = line.match(/import ([a-z\.\_].*)/i)
        if m != nil
            resolved = resolve_import m[1]
            @trickles[m[1]] = resolved

            return line.sub m[1], resolved
        end

        return line
    end

    def parse_line(line)
        line = handle_imports line

        @trickles.each do |find, replace|
            line.sub! find, replace
        end

        return line
    end
end