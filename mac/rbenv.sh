# Define notice and error function

function notice() {
  echo "$1" >&2
}

function error() {
  notice "$1"
  exit 1
}

# Silence STDOUT
exec 1>/dev/null

# Check for LLVM GCC 4.2
GCC=`/usr/bin/gcc --version 2> /dev/null | head -n1 | grep GCC | grep 4.2 | grep LLVM`

# Install GCC
if [ ! "$GCC" ]
then
  error "[ ] Please install Command Line Tools for Xcode and re-run this script."
fi

# Install homebrew
if [[ ! -x "/usr/local/bin/brew" ]]
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.github.com/gist/323731)" || error "[ ] Please contact Matt"
  notice "[✔] Installed Homebrew"
else
  /usr/local/bin/brew update || error "[ ] Please contact Matt"
  notice "[✔] Updated Homebrew"
fi

# Install git
if [[ ! -x "/usr/local/bin/git" ]]
then
  /usr/local/bin/brew install git || error "[ ] Please contact Matt"
  notice "[✔] Installed git"
else
  /usr/local/bin/brew upgrade git || error "[ ] Please contact Matt"
  notice "[✔] Updated git"
fi

# Attempt to load .profile
if [[ -s "$HOME/.profile" ]]
then 
  source ~/.profile || error "[ ] Please contact Matt"
fi

# Install rbenv
if [[ ! -s "$HOME/.rbenv" ]]
then
  /usr/local/bin/git clone -q git://github.com/sstephenson/rbenv.git ~/.rbenv || error "[ ] Please contact Matt"
  notice "[✔] Installed rbenv"
else
  ( cd ~/.rbenv && /usr/local/bin/git pull -q origin master ) || error "[ ] Please contact Matt"
  notice "[✔] Updated rbenv"
fi

# Install rbenv-vars
if [[ ! -s "$HOME/.rbenv/plugins/rbenv-vars" ]]
then
  mkdir -p ~/.rbenv/plugins
  /usr/local/bin/git clone -q git://github.com/sstephenson/rbenv-vars.git ~/.rbenv/plugins/rbenv-vars || error "[ ] Please contact Matt"
  notice "[✔] Installed rbenv-vars"
else
  ( cd ~/.rbenv/plugins && /usr/local/bin/git pull -q origin master ) || error "[ ] Please contact Matt"
  notice "[✔] Updated rbenv-vars"
fi

# Install ruby-build
if [[ ! -s "$HOME/.ruby-build" ]]
then
  /usr/local/bin/gidt clone -q git://github.com/sstephenson/ruby-build.git ~/.ruby-build || error "[ ] Please contact Matt"
  notice "[✔] Installed ruby-build"
else
  ( cd ~/.ruby-build && /usr/local/bin/git pull -q origin master ) || error "[ ] Please contact Matt"
  notice "[✔] Updated ruby-build"
fi

# Install Pow if it hasn't been installed yet
if [[ ! -s "$HOME/.pow" ]]
then
  ( curl get.pow.cx | sh ) || error "[ ] Please contact Matt"
  notice "[✔] Installed Pow"
fi

# Add rbenv to .profile
if [[ ! -s "$HOME/.profile" ]] || ! grep -q "rbenv" $HOME/.profile
then
  echo "export PATH=\"$HOME/.rbenv/shims:$HOME/.rbenv/bin:\$PATH"\" >> ~/.profile || error "[ ] Please contact Matt"
fi

# Add ruby-build to .profile
if [[ ! -s "$HOME/.profile" ]] || ! grep -q "ruby-build" $HOME/.profile
then
  echo 'export PATH="$HOME/.ruby-build/bin:$PATH"' >> ~/.profile || error "[ ] Please contact Matt"
fi

# Add rbenv to .powconfig
# See: https://github.com/37signals/pow/issues/202
if [[ ! -s "$HOME/.powconfig" ]] || ! grep -q "rbenv" $HOME/.powconfig
then
  echo "export PATH=\"\$HOME/.rbenv/shims:\$HOME/.rbenv/bin:\$PATH"\" >> ~/.powconfig || error "[ ] Please contact Matt"
fi

# Infer project name
NAME=`basename "\`pwd\`"`

# Detect Ruby version
VERSION=`~/.rbenv/bin/rbenv local 2> /dev/null`

[ ! "$VERSION" ] && error "[ ] .ruby-version file is missing. Please re-run this script from the project directory once you’ve cloned it with git."

# Install Ruby if necessary
if [ "$VERSION" ] && [[ ! -s "$HOME/.rbenv/versions/$VERSION" ]]
then
  ( ~/.rbenv/bin/rbenv install $VERSION && ~/.rbenv/bin/rbenv rehash ) || error "[ ] Please contact Matt"
  notice "[✔] Installed Ruby $VERSION"
fi

# Install bundler
if ( ~/.rbenv/bin/rbenv which bundle )
then
  ( ~/.rbenv/bin/rbenv exec gem update bundler --pre && ~/.rbenv/bin/rbenv rehash ) || error "[ ] Please contact Matt"
  notice "[✔] Updated bundler"
else
  ( ~/.rbenv/bin/rbenv exec gem install bundler --pre && ~/.rbenv/bin/rbenv rehash ) || error "[ ] Please contact Matt"
  notice "[✔] Installed bundler"
fi

# Install powify
if ( ~/.rbenv/bin/rbenv which powify )
then
  ( ~/.rbenv/bin/rbenv exec gem update powify && ~/.rbenv/bin/rbenv rehash ) || error "[ ] Please contact Matt"
  notice "[✔] Updated powify"
else
  ( ~/.rbenv/bin/rbenv exec gem install powify && ~/.rbenv/bin/rbenv rehash ) || error "[ ] Please contact Matt"
  notice "[✔] Installed powify"
fi

# Install gems
( ~/.rbenv/bin/rbenv exec bundle check > /dev/null || ~/.rbenv/bin/rbenv exec bundle install --without=production ) || error "[ ] Please contact Matt"
notice "[✔] Updated gems"

# Copy database config
if [[ ! -s "config/database.yml" ]]
then
  cp config/database.yml{.example,} || error "[ ] Please contact Matt"
  notice "[✔] Copied sample database configuration"
fi

# Copy env
if [[ ! -s ".rbenv-vars" ]]
then
  cp config/vars .rbenv-vars || error "[ ] Please contact Matt"
fi

# Migrate migrations or run project setup
if ( ~/.rbenv/bin/rbenv exec bundle exec rake db:migrate:status 1>/dev/null )
then
  ( ~/.rbenv/bin/rbenv exec bundle exec rake db:migrate ) || error "[ ] Please contact Matt"
  notice "[✔] Ran database migrations"
else
  ( ~/.rbenv/bin/rbenv exec bundle exec rake db:setup ) || error "[ ] Please contact Matt"
  notice "[✔] Ran database setup"
fi

# Add to Pow
if [[ ! -s "$HOME/.pow/$NAME" ]]
then
  ln -s "`pwd`" ~/.pow/ || error "[ ] Please contact Matt"
  notice "[✔] Added ‘$NAME’ to Pow"
fi

# Restart Pow
( ~/.rbenv/bin/rbenv exec powify server restart ) || error "[ ] Please contact Matt"
notice "[✔] Restarted Pow"

# Open project in default browser
open -g http://$NAME.dev
