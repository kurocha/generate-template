
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

teapot_version "2.0"

define_target "generators" do |target|
	target.description = <<-EOF
		Provides basic functionality for generating project files from templates.
	EOF
	
	target.provides "Generate/Copy" do
		define Rule, "generate.copy" do
			# The input prefix where template are copied from:
			input :source, multiple: true
			
			# The output prefix where files will be copied to:
			parameter :prefix
			
			# Substitutions that are applied during the copy process:
			parameter :substitutions, default: Build::Text::Substitutions.new
			
			apply do |arguments|
				substitutions = arguments[:substitutions]
				
				arguments[:source].each do |path|
					# We apply the substitutions to the relative path:
					destination_path = arguments[:prefix] + substitutions.apply(path.relative_path)

					if path.directory?
						unless destination_path.exist?
							mkpath(destination_path)
						end
					else
						generate source_file: path, destination_path: destination_path, substitutions: substitutions
					end
				end
			end
		end
		
		define Rule, "generate.file" do
			parameter :source_file
			
			output :destination_path
			
			# Substitutions that are applied during the copy process:
			parameter :substitutions, optional: true
			
			apply do |arguments|
				mkpath(File.dirname(arguments[:destination_path]))
				
				if arguments[:destination_path].exist?
					text = File.read(arguments[:source_file])
					
					if substitutions = arguments[:substitutions]
						text = substitutions.apply(text)
					end
					
					merged = Build::Text::Merge::combine(arguments[:destination_path].read.lines, text.lines)
					
					write(arguments[:destination_path], merged.join)
				else
					if substitutions = arguments[:substitutions]
						text = File.read(arguments[:source_file])
						write(arguments[:destination_path], substitutions.apply(text))
					else
						cp(arguments[:source_file], arguments[:destination_path])
					end
				end
			end
		end
	end
end
