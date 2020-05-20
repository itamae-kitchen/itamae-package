#!/bin/bash -xe

dpkg -i /work/out/itamae_*.deb || :
apt-get install -f -y

cat <<-EOF > /tmp/recipe.rb
execute "sha256sum /etc/test > /etc/test.sha256sum" do
  action :nothing
end

file "/etc/test" do
  content "test\n"
  owner "root"
  group "root"
  mode  "0644"
  notifies :run, 'execute[sha256sum /etc/test > /etc/test.sha256sum]'
end
EOF

itamae local /tmp/recipe.rb

if [[ "_$(sha256sum /etc/test)" = "_$(cat /etc/test.sha256sum)" ]]; then
  echo ok
else
  echo not ok
  exit 1
fi
