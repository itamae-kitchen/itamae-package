class << Gem
  OPERATING_SYSTEM_DEFAULTS = {
    ssl_ca_cert: '/etc/ssl/certs/ca-certificates.crt'
  }.freeze

  alias upstream_ruby ruby
  def ruby
    "/opt/itamae/embedded/bin/ruby"
  end

  def default_bindir
    ENV['ITAMAE_PACKAGE_INSTALL_GEM_TO_OPT'] ? '/opt/itamae/bin' : '/var/lib/itamae/bin'
  end

  alias upstream_default_dir default_dir
  def default_dir
    File.join(
      *[
        ENV['ITAMAE_PACKAGE_INSTALL_GEM_TO_OPT'] ? [ENV['ITAMAE_DESTDIR'] || '/', "opt/itamae/embedded/lib/ruby/gems"] : 'var/lib/itamae/gems',
        RbConfig::CONFIG['ruby_version'],
      ].flatten,
    )
  end

  alias upstream_default_path default_path
  def default_path
    [
      user_dir,
      "/var/lib/itamae/gems/#{RbConfig::CONFIG['ruby_version']}",
      "/opt/itamae/embedded/lib/ruby/gems/#{RbConfig::CONFIG['ruby_version']}",
    ]
  end

  alias upstream_default_specifications_dir default_specifications_dir
  def default_specifications_dir
    "/opt/itamae/embedded/lib/ruby/gems/#{RbConfig::CONFIG['ruby_version']}/specifications/default"
  end

  alias upstream_user_dir user_dir
  def user_dir
    File.join(Gem.user_home, '.itamae-embedded-ruby/gems', Gem.ruby_engine, RbConfig::CONFIG['ruby_version'])
  end
end

