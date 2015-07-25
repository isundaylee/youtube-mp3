#!/usr/bin/env ruby

require 'bundler/setup'
require 'trollop'
require 'fileutils'
require_relative 'lib/id3_writer'

def usage
  print "Usage: youtube-mp3 URL OUTPUT"
  exit
end

def run(title, command, verbose)
  command += ' 2>&1 >/dev/null' unless verbose
  puts title + " ..."
  puts command if verbose
  `#{command}`
end

opts = Trollop::options do
  banner <<-EOS
  Download YouTube videos as MP3 songs.

  Usage:
         youtube-mp3 [options] <url>

  where [options] are:
  EOS

  opt :import, "Import into iTunes. "
  opt :output, "Output file. Defaults to song.mp3.", type: String
  opt :verbose, "Output verbose log. "
end

if ARGV.size < 1
  Trollop::die :url
end

url = ARGV[0]
output = opts[:output] || "song.mp3"

output_m4a = File.join(File.dirname(output), "#{File.basename(output, '.*')}.m4a")
output_ogg = File.join(File.dirname(output), "#{File.basename(output, '.*')}.ogg")
output_mp3 = File.join(File.dirname(output), "#{File.basename(output, '.*')}.mp3")

FileUtils.rm_f(output_mp3)
run('Downloading', "youtube-dl -x '#{url}' -o #{output}", opts[:verbose])

if !File.exists?(output_mp3)
  input_file = nil

  input_file = output_m4a if File.exist?(output_m4a)
  input_file = output_ogg if File.exist?(output_ogg)

  if input_file.nil?
    puts 'FATAL: Neither m4a nor ogg file is present. '
  end

  run('Converting', "ffmpeg -i #{input_file} -q:a 0 -f mp3 #{output_mp3}", opts[:verbose])
  FileUtils.rm_f(output_m4a)
end

run('Tagging', 'echo', opts[:verbose])
info = {
  album: 'YouTube',
  title: `youtube-dl -e '#{url}'`.strip,
  album_artist: 'YouTube',
  genre: 'YouTube',
  cover: File.join(__dir__, 'assets', 'YouTube.png')
}
ID3Writer.write_id3(output_mp3, info)

if opts[:import]
  run('Importing', "mv #{output_mp3} ~/Music/iTunes/iTunes\\ Media/Automatically\\ Add\\ to\\ iTunes.localized/", opts[:verbose])
end