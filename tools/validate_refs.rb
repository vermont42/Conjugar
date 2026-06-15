#!/usr/bin/env ruby
# Validate that every group-relative / source-root file reference in the project
# resolves to a file that actually exists on disk. Catches a broken pbxproj
# (a moved file whose reference wasn't updated) without a full build.
#   ruby validate_refs.rb <PROJECT_DIR>
require 'xcodeproj'

proj_dir = ARGV[0]
Dir.chdir(proj_dir)
project = Xcodeproj::Project.open('Conjugar.xcodeproj')

checked = 0
missing = []
project.files.each do |f|
  next unless ['<group>', 'SOURCE_ROOT'].include?(f.source_tree)
  # products (.app/.xctest) live under BUILT_PRODUCTS_DIR, already excluded by source_tree
  path = begin
    f.real_path
  rescue StandardError
    nil
  end
  checked += 1
  if path.nil? || !File.exist?(path)
    missing << "#{f.display_name} -> #{path.inspect}"
  end
end

if missing.empty?
  puts "VALIDATION OK: #{checked} group/source-root file refs all resolve on disk"
else
  puts "VALIDATION FAILED (#{missing.size} missing):"
  missing.each { |m| puts "  #{m}" }
  exit 1
end
