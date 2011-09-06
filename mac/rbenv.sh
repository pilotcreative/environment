# Attempt to load .profile
[[ -s "$HOME/.profile" ]] && source ~/.profile

# Install rbenv
[[ ! -s "$HOME/.rbenv" ]] && git clone git://github.com/sstephenson/rbenv.git ~/.rbenv

# Install ruby-build
[[ ! -s "$HOME/.ruby-build" ]] && git clone git://github.com/sstephenson/ruby-build.git ~/.ruby-build

# Install Pow if it hasn't been installed yet
[[ ! -s "$HOME/.pow" ]] && curl get.pow.cx | sh

# Add rbenv to .profile
if [[ ! -s "$HOME/.profile" ]] || ! grep -q "rbenv" $HOME/.profile
then
  echo "export PATH=\"$HOME/.rbenv/shims:$HOME/.rbenv/bin:\$PATH"\" >> ~/.profile
fi

# Add ruby-build to .profile
if [[ ! -s "$HOME/.profile" ]] || ! grep -q "ruby-build" $HOME/.profile
then
  echo 'export PATH="$HOME/.ruby-build/bin:$PATH"' >> ~/.profile
fi

# Add rbenv to .powconfig
if [[ ! -s "$HOME/.powconfig" ]] || ! grep "rbenv" $HOME/.powconfig
then
  echo "export PATH=\"$HOME/.rbenv/shims:$HOME/.rbenv/bin:\$PATH"\" >> ~/.powconfig
fi

# Infer project name
NAME=`basename \`pwd\``

# Detect Ruby version
VERSION=`~/.rbenv/bin/rbenv local`

# Install Ruby if necessary
[ $VERSION ] && [[ ! -s "$HOME/.rbenv/versions/$VERSION" ]] && ~/.ruby-build/bin/ruby-build $VERSION ~/.rbenv/versions/$VERSION/ && ~/.rbenv/bin/rbenv rehash

# Install bundler
[[ ! -s "$HOME/.rbenv/shims/bundle" ]] && ~/.rbenv/bin/rbenv exec gem install bundler && ~/.rbenv/bin/rbenv rehash

# Install gems
~/.rbenv/bin/rbenv exec bundle check || ~/.rbenv/bin/rbenv exec bundle install --without=production

# Copy database config
[[ ! -s "config/database.yml" ]] && cp config/database.yml{.example,}

# Run project setup
~/.rbenv/bin/rbenv exec bundle exec rake db:setup

# Add to Pow
[[ ! -s "$HOME/.pow/$NAME" ]] && ln -s "`pwd`" ~/.pow/

# Open project in default browser
open http://$NAME.dev
