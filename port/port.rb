#!/usr/bin/env ruby
REGION = ENV.fetch('ITAMAE_CODEBUILD_REGION', 'us-west-2')
PROJECT = ENV.fetch('ITAMAE_CODEBUILD_PROJECT', 'sorah-debuild')

BUCKET = ENV.fetch('ITAMAE_CODEBUILD_SOURCE_BUCKET', 'sorah-codebuild')
SOURCE_KEY = ENV.fetch('ITAMAE_CODEBUILD_SOURCE_KEY', 'sources/sorah-debuild.zip')

BUILDSPEC = File.read(File.join(__dir__, 'buildspec.yml'))

require 'uri'
require 'fileutils'
require 'aws-sdk-s3'
require 'aws-sdk-codebuild'

if ARGV.size < 2
  abort "usage: #$0 docker_repo:distro source_tar"
end

image, source_tar_path = ARGV[0,2]

unless image.include?(':')
  repo = case image
         when 'stretch', 'buster'
           'mirror.gcr.io/library/debian'
         when 'trusty', 'xenial'
           'ubuntu'
         else
           'public.ecr.aws/ubuntu/ubuntu'
         end
  image = "#{repo}:#{image}"
end

puts "===> PID: #$$"

@s3 = Aws::S3::Client.new(region: REGION)
@codebuild = Aws::CodeBuild::Client.new(region: REGION)

source_zip_directory = "tmp/codebuild-src-#$$"

FileUtils.mkdir_p(source_zip_directory)
FileUtils.cp(source_tar_path, File.join(source_zip_directory, "source.tar"))

puts "===> zip source package"

zip_path = File.expand_path("./out/codebuild-src-#$$.zip")
Dir.chdir(source_zip_directory) do
  system("zip", "-r", zip_path, '.', exception: true)
end

puts "===> uploading source"

puts "   * Bucket: #{BUCKET}"
puts "   * Key: #{SOURCE_KEY}"

source_version = File.open(zip_path, 'rb') do |io|
  @s3.put_object(
    bucket: BUCKET,
    key: SOURCE_KEY,
    body: io,
  ).version_id
end

puts "   [ ok ] version=#{source_version}"

File.unlink zip_path
FileUtils.remove_entry_secure source_zip_directory

puts
puts "===> Starting build"

build = @codebuild.start_build(
  project_name: PROJECT,
  source_version: source_version,
  compute_type_override: 'BUILD_GENERAL1_LARGE',
  environment_type_override: 'ARM_CONTAINER',
  image_override: image,
  environment_variables_override: [
    { type: 'PLAINTEXT', name: 'DEBIAN_FRONTEND', value: 'noninteractive' },
    { type: 'PLAINTEXT', name: 'DEBUILD_CODEBUILD_SOURCE', value: 'itamae' },
  ],
  buildspec_override: BUILDSPEC,
  idempotency_token: "#{File.basename($0)}-#{ENV['USER']}-#$$",
).build

puts "   * ARN: #{build.arn}"
puts "   * Log: https://console.aws.amazon.com/codesuite/codebuild/projects/#{URI.encode_www_form_component(build.project_name)}/build/#{URI.encode_www_form_component(build.id)}/log?region=#{REGION}"

sleep 2
puts
puts "===> Waiting build to complete..."

loop do
  build = @codebuild.batch_get_builds(ids: [build.id]).builds[0]
  if build
    puts "   * status: #{build.build_status}, phase: #{build.current_phase}"
    break if build.build_status != 'IN_PROGRESS'
  else
    puts "   * build not found"
  end
  sleep 5
end

unless build.build_status == 'SUCCEEDED'
  raise "build not succeeded"
end

puts
puts "===> Downloading artifacts"

File.open("./out/codebuild-out-#$$.zip", 'wb') do |io|
  m = build.artifacts.location.match(%r{\Aarn:aws:s3:::(.+?)/(.+?)\z})
  unless m
    raise "artifact location not supported"
  end
  @s3.get_object(
    bucket:  m[1],
    key: m[2],
    response_target: io,
  )
end

puts
puts "===> Unzip"

FileUtils.mkdir_p("out/codebuild-out-#$$")
Dir.chdir("out/codebuild-out-#$$") do
  system("unzip", "../codebuild-out-#$$.zip", exception: true)
  File.unlink  "../codebuild-out-#$$.zip"
end

(Dir["./out/codebuild-out-#$$/*"] + Dir["./out/codebuild-out-#$$/.*"]).each do |file|
  next if file.end_with?('/.') || file.end_with?('/..')
  File.rename file, "./out/#{File.basename(file)}"
end

Dir.rmdir "./out/codebuild-out-#$$"
