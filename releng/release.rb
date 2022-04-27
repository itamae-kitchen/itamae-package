#!/usr/bin/env ruby
require 'shellwords'
require 'yaml'
require 'fileutils'
require 'octokit'
require 'logger'
require 'aws-sdk-s3'
require 'net/http'
require 'net/https'
require 'uri'

BintrayTarget = Struct.new(:gh_organization, :bintray_repo, keyword_init: true)
NullTarget = Struct.new(:null)

Change = Struct.new(
  :path,
  :changes,
  :dsc,
  :change_arch,
  :package_name,
  :version,
  :distro,
  :arch,
  :repo,
  :tag,
  :files,
  keyword_init: true,
)

DebFile = Struct.new(:package, :version, :distro, :arch, :path, :name, keyword_init: true)

def parse_debian_metafile(str)
  if str.start_with?('-----BEGIN PGP SIGNED MESSAGE-----')
    raw = str.match(/-----BEGIN PGP SIGNED MESSAGE-----\n.+?\n\n(.+)-----BEGIN PGP SIGNATURE-----/m)[1]
  else
    raw = str
  end

  pairs = raw.each_line.map(&:chomp).reject(&:empty?).slice_before { |_| _[0] != ' ' }.map { |_| key, val = _.first.split(': ', 2); [key.sub(/: ?\z/,''), [val.nil? || val.empty? ? nil : val, *_[1..-1].map{ |_| _.sub(/^ /,'') }].compact] }
  Hash[pairs]
end

class ReleaseDescription
  def initialize(changes_by_arch: {}, dsc: nil)
    @changes_by_arch = changes_by_arch
    @dsc = dsc
  end

  attr_accessor :changes_by_arch, :dsc

  def to_s
    [].tap do |body|
      body.push('### Changes', '')
      @changes_by_arch.to_a.sort_by(&:first).each do |(arch, changes)|
        body.push("#### #{arch}", '', '```', changes.chomp, '```', '')
      end
      if @dsc
        body.push('### dsc', '', '```', @dsc.chomp, '```')
      end
    end.join("\n")
  end

  def self.parse(str)
    str = str.gsub(/\r\n/, "\n")
    dsc = str.match(/^### dsc\n\n```\n(.+?)\n```/m)&.to_a&.at(1)

    changes_by_arch = {}
    changes_part = str.match(/^### Changes\n(.+?)\n(?:### |\z)/m)&.to_a&.at(1)
    # Backward compat
    changes_str = changes_part.include?('#### ') ? changes_part : "#### amd64\n#{changes_part}"
    changes_str.scan(/#### (.+?)\n\n```\n(.+?)\n```/m).each do |(arch, changes)|
      changes_by_arch[arch] = changes
    end

    new(dsc: dsc, changes_by_arch: changes_by_arch)
  end
end
####

if ARGV.size < 2
  abort 'Usage: nkmi-deb-release repo [path/to.changes ...]'
end

octo = Octokit::Client.new(access_token: ENV.fetch('GITHUB_ACCESS_TOKEN'))

puts "=> Destination"
puts

target = NullTarget.new
repo_name = 'itamae-package'
puts "   bintray #{target.inspect}"

deb_files = []

target_changes = ARGV.map do |change_path|
  changes = File.read(change_path)
  change_arch = change_path.match(/_([a-z0-9]+?)\.changes\z/)[1]

  change_fields = parse_debian_metafile(changes)
  
  package_name = change_fields['Source'][0]
  version = change_fields['Version'][0]
  distro = change_fields['Distribution'][0]
  arch = change_fields['Architecture'][0].split(/\s+/).grep_v('source').first

  repo = "#{target.gh_organization}/#{repo_name}"

  tag = "debian/#{version.gsub(?:,?%).gsub(?~,?_)}"
  files = change_fields['Files'].map { |_| _.split.last }
  
  dsc = nil
  dsc_file = files.find{|_| _.end_with?('.dsc') }
  if dsc_file
    dsc = File.read(File.join(File.dirname(File.expand_path(change_path)), dsc_file))
    dsc_fields = parse_debian_metafile(dsc)
    files += dsc_fields['Files'].map { |_| _.split.last }
  end

  files.uniq!
  files.map! {|_| File.join(File.dirname(File.expand_path(change_path)), _) }

  Change.new(
    path: change_path,
    changes: changes,
    dsc: dsc,
    change_arch: change_arch,
    package_name: package_name,
    version: version,
    distro: distro,
    arch: arch,
    repo: repo,
    tag: tag,
    files: files,
  )
end

target_changes.flat_map(&:files).each do |file|
  unless File.exist?(file)
    raise "File #{file.inspect} is missing"
  end
end

target_changes.group_by do |change|
  change.tag
end.each do |tag, changes| 
  raise "!?" if changes.map {|_| [_.package_name, _.version, _.distro] }.uniq.size != 1

  package_name = changes.first.package_name
  version = changes.first.version
  distro = changes.first.distro
  repo = changes.first.repo
 
  puts "=> Releasing the following package:"
  puts
  puts " #{package_name} #{version}"
  puts
  puts " * git tag: #{tag}"
  puts " * files: #{changes.map {|_| _[:files] }.join(', ')}"
  puts
  puts " * distro: #{distro}"
  puts " * arch: #{changes.map {|_| _[:arch] }.uniq.join(', ')}"
  puts " * change arch: #{changes.map {|_| _[:change_arch] }.uniq.join(', ')}"
  puts

  puts "=> Checking tag #{tag} exists on GitHub"
  octo.ref(repo, "tags/#{tag}")

  release = begin
    octo.release_for_tag(repo, tag)
  rescue Octokit::NotFound
    nil
  end

  description = if release
    puts " * Adding to existing release..."
    ReleaseDescription.parse(release.body)
  else
    ReleaseDescription.new
  end

  changes.each do |c|
    raise "#{c.change_arch} already released" if description.changes_by_arch[c.change_arch]
    description.changes_by_arch[c.change_arch] = c.changes
  end

  dsc = changes.map(&:dsc).find(&:itself)
  if dsc
    raise "source package already released" if description.dsc
    description.dsc = dsc
  end

  puts "=> Releasing to GitHub #{repo}: #{tag}"
  
  if ENV['NO_GITHUB']
    puts ' ! SKIPPING GitHub Release'
    next
  end

  release ||= octo.create_release(repo, tag, body: "")
  
  puts
  puts " * release: #{release[:html_url]}"
  
  changes.each do |change|
    [change.path, *change.files].each do |file|
      content_type = {
        'deb' => 'application/vnd.debian.binary-package',
        'ddeb' => 'application/vnd.debian.binary-package',
        'changes' => 'text/plain',
        'dsc' => 'text/plain',
        'buildinfo' => 'text/plain',
        'xz' => 'application/x-xz',
        'gz' => 'application/x-gzip',
      }[file.split(?.).last]

      if changes.size == 1
        name = File.basename(file)
      else
        name = "#{change.change_arch}--#{File.basename(file)}"
      end

      deb_files << DebFile.new(
        package: package_name,
        version: version,
        distro: distro,
        arch: change.arch,
        path: file,
        name: name,
      )

      asset = begin
        octo.upload_asset(release.url, file, content_type: content_type, name: name)
      rescue Octokit::UnprocessableEntity => e
        if e.errors[0][:code] == 'already_exists'
          puts " * asset: #{name} (Skipped due to #{e.class} #{e.errors.inspect})"
          next
        end
        raise
      end

      puts " * asset: #{asset.name} #{asset.browser_download_url}"
    end
  end
  puts

  octo.update_release(release[:url], body: description.to_s)
end

case target
when NullTarget
  puts "=> Not pushing to repository (NullTarget)"
when BintrayTarget
  puts "=> Adding to bintray #{target.bintray_repo}"

  deb_files.each do |deb|
    next unless deb.path.end_with?('.deb')
    url = URI("https://api.bintray.com/content/#{target.bintray_repo}/" \
              "#{URI.encode_www_form_component(deb.package)}/" \
              "#{URI.encode_www_form_component(deb.version)}/" \
              "#{URI.encode_www_form_component(deb.distro)}/pool/#{deb.package[0]}/#{URI.encode_www_form_component(deb.name)};" \
              "deb_distribution=#{URI.encode_www_form_component(deb.distro)};" \
              "deb_architecture=#{URI.encode_www_form_component(deb.arch)};" \
              "deb_component=contrib;" \
              "publish=1;override=1")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == 'https'
    http.start do
      print "* #{deb.path} => #{url.path} ... "
      File.open(deb.path, 'r') do |io|
        req = Net::HTTP::Put.new(url)
        req.basic_auth(*ENV['BINTRAY_API_KEY'].split(?:))
        req['Content-Type'] = 'application/vnd.debian.binary-package'
        # req['X-GPG-PASSPHRASE'] = config['bintray_gpg_key_passphrase']
        req['Transfer-Encoding'] = 'chunked'
        req.body_stream = io
        http.request(req)
      end
      puts "done"
    end
  end
else
  raise
end
