# Require GCC / Xcode
`which gcc 1> /dev/null` || (echo "Please install Xcode before continuing: http://developer.apple.com/technologies/xcode.html" && exit)

# Install homebrew
[[ ! -x "/usr/local/bin/brew" ]] && /usr/bin/ruby -e "$(curl -fsSL https://raw.github.com/gist/323731)"

# Install git
[[ ! -x "/usr/local/bin/git" ]] && /usr/local/bin/brew install git

# Attempt to load .profile
[[ -s "$HOME/.profile" ]] && source ~/.profile

# Install rbenv
[[ ! -s "$HOME/.rbenv" ]] && /usr/local/bin/git clone git://github.com/sstephenson/rbenv.git ~/.rbenv

# Install ruby-build
[[ ! -s "$HOME/.ruby-build" ]] && /usr/local/bin/git clone git://github.com/sstephenson/ruby-build.git ~/.ruby-build

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
# See: https://github.com/37signals/pow/issues/202
if [[ ! -s "$HOME/.powconfig" ]] || ! grep -q "rbenv" $HOME/.powconfig
then
  echo "export PATH=\"$HOME/.rbenv/shims:$HOME/.rbenv/bin:\$PATH"\" >> ~/.powconfig
fi

# Infer project name
NAME=`basename "\`pwd\`"`

# Detect Ruby version
VERSION=`~/.rbenv/bin/rbenv local`

[ ! $VERSION ] && echo ".rbenv-version file missing. Please re-run this from the project directory once you’ve cloned it with git." && exit

# Install Ruby if necessary
[ $VERSION ] && [[ ! -s "$HOME/.rbenv/versions/$VERSION" ]] && ~/.ruby-build/bin/ruby-build $VERSION ~/.rbenv/versions/$VERSION/ && ~/.rbenv/bin/rbenv rehash

# Install bundler
[[ ! -s "$HOME/.rbenv/shims/bundle" ]] && ~/.rbenv/bin/rbenv exec gem install bundler && ~/.rbenv/bin/rbenv rehash

# Install powify
[[ ! -s "$HOME/.rbenv/shims/powify" ]] && ~/.rbenv/bin/rbenv exec gem install powify && ~/.rbenv/bin/rbenv rehash

# Install gems
~/.rbenv/bin/rbenv exec bundle check || ~/.rbenv/bin/rbenv exec bundle install --without=production

# Copy database config
[[ ! -s "config/database.yml" ]] && cp config/database.yml{.example,}

# Run project setup
~/.rbenv/bin/rbenv exec bundle exec rake db:setup

# Add to Pow
[[ ! -s "$HOME/.pow/$NAME" ]] && ln -s "`pwd`" ~/.pow/

# Restart Pow
~/.rbenv/bin/rbenv exec powify server restart

# Open project in default browser
open -g http://$NAME.dev
