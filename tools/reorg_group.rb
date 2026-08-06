#!/usr/bin/env ruby
# Reorganize one app-target virtual group into a real folder.
#   ruby reorg_group.rb <PROJECT_DIR> <GROUP_UUID> <FOLDER_NAME>
# - Moves each group-relative file ref from Conjugar/<file> to Conjugar/<FOLDER>/<file> on disk.
# - Reparents files that must stay flat (Info.plist, SOURCE_ROOT-relative refs,
#   and PBXVariantGroups like LaunchScreen.storyboard) into the top-level Conjugar group instead.
# - Flips the group from virtual (name=) to folder-backed (path=).
require 'xcodeproj'
require 'fileutils'

proj_dir   = ARGV[0]
group_uuid = ARGV[1]
folder     = ARGV[2]

CONJUGAR_GROUP_UUID = 'E1F06AD61E8F05F300ADD2E1'.freeze

Dir.chdir(proj_dir)
project = Xcodeproj::Project.open('Conjugar.xcodeproj')
conjugar_group = project.objects_by_uuid[CONJUGAR_GROUP_UUID]
group = project.objects_by_uuid[group_uuid]
raise "no group for #{group_uuid}" unless group
raise "no Conjugar group" unless conjugar_group

base = 'Conjugar'
dest = File.join(base, folder)
FileUtils.mkdir_p(dest)

moved = []
relocated = []

group.children.dup.each do |child|
  reparent =
    child.isa == 'PBXVariantGroup' ||
    (child.respond_to?(:source_tree) && child.source_tree == 'SOURCE_ROOT') ||
    (child.respond_to?(:path) && child.path && File.basename(child.path) == 'Info.plist')

  if reparent
    group.children.delete(child)
    conjugar_group.children << child
    relocated << child.display_name
    next
  end

  # normal group-relative file: move on disk from Conjugar/<file> to Conjugar/<folder>/<file>
  fname = child.path
  src = File.join(base, fname)
  dst = File.join(dest, fname)
  if File.exist?(src)
    FileUtils.mv(src, dst)
  elsif !File.exist?(dst)
    raise "missing file on disk (neither src nor dst exists): #{src}"
  end
  moved << fname
end

# flip virtual group -> folder-backed group
group.name = nil
group.path = folder
group.source_tree = '<group>'

project.save
puts "GROUP #{folder}: moved=#{moved.size} files; relocated=#{relocated.inspect}"
