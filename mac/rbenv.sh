function notice() {
  echo "$1" >&2
}

function error() {
  if [ "$1" ]
  then
    notice "$1"
  else
    notice "[ ] Please email Matt."
  fi
  exit 1
}

# Silence STDOUT
exec 1>/dev/null

# Check for LLVM GCC 4.2
GCC=`/usr/bin/gcc --version 2> /dev/null | head -n1 | grep GCC | grep 4.2 | grep LLVM`

# Install GCC
if [ ! "$GCC" ]
then
  error "[ ] Please install Command Line Tools for Xcode and re-run this script"
fi

# Install homebrew
if [[ ! -x "/usr/local/bin/brew" ]]
then
  /usr/bin/ruby -e "$(curl -fsSkL raw.github.com/mxcl/homebrew/go)" || error
  notice "[✔] Installed Homebrew"
else
  /usr/local/bin/brew update || error
  notice "[✔] Updated Homebrew"
fi

# Install git
if [[ ! -x "/usr/local/bin/git" ]]
then
  /usr/local/bin/brew install git || error
  notice "[✔] Installed git"
else
  OUTPUT=`/usr/local/bin/brew upgrade git 2>&1` || (echo "$OUTPUT" | grep "already installed") || error
  notice "[✔] Updated git"
fi

# Install rbenv
if [[ ! -s "$HOME/.rbenv" ]]
then
  /usr/local/bin/git clone -q git://github.com/sstephenson/rbenv.git ~/.rbenv || error
  notice "[✔] Installed rbenv"
else
  ( cd ~/.rbenv && /usr/local/bin/git pull -q origin master ) || error
  notice "[✔] Updated rbenv"
fi

# Install rbenv-vars
if [[ ! -s "$HOME/.rbenv/plugins/rbenv-vars" ]]
then
  mkdir -p ~/.rbenv/plugins
  /usr/local/bin/git clone -q git://github.com/sstephenson/rbenv-vars.git ~/.rbenv/plugins/rbenv-vars || error
  notice "[✔] Installed rbenv-vars"
else
  ( cd ~/.rbenv/plugins && /usr/local/bin/git pull -q origin master ) || error
  notice "[✔] Updated rbenv-vars"
fi

# Install ruby-build
if [[ ! -s "$HOME/.ruby-build" ]]
then
  /usr/local/bin/git clone -q git://github.com/sstephenson/ruby-build.git ~/.ruby-build || error
  notice "[✔] Installed ruby-build"
else
  ( cd ~/.ruby-build && /usr/local/bin/git pull -q origin master ) || error
  notice "[✔] Updated ruby-build"
fi

# Install Pow if it hasn't been installed yet
if [[ ! -s "$HOME/.pow" ]]
then
  ( curl get.pow.cx | sh ) || error
  notice "[✔] Installed Pow"
fi

# Add rbenv to .profile
if [[ ! -s "$HOME/.profile" ]] || ! grep -q "rbenv" $HOME/.profile
then
  echo "export PATH=\"$HOME/.rbenv/shims:$HOME/.rbenv/bin:\$PATH"\" >> ~/.profile || error
fi

# Add rbenv to .zprofile
if [[ ! -s "$HOME/.zprofile" ]] || ! grep -q "rbenv" $HOME/.zprofile
then
  echo "export PATH=\"$HOME/.rbenv/shims:$HOME/.rbenv/bin:\$PATH"\" >> ~/.zprofile || error
fi

# Add ruby-build to .profile
if [[ ! -s "$HOME/.profile" ]] || ! grep -q "ruby-build" $HOME/.profile
then
  echo 'export PATH="$HOME/.ruby-build/bin:$PATH"' >> ~/.profile || error
fi

# Add ruby-build to .zprofile
if [[ ! -s "$HOME/.zprofile" ]] || ! grep -q "ruby-build" $HOME/.zprofile
then
  echo 'export PATH="$HOME/.ruby-build/bin:$PATH"' >> ~/.zprofile || error
fi

# Infer project name
NAME=`basename "\`pwd\`"`

# Detect Ruby version
VERSION=`~/.rbenv/bin/rbenv local 2> /dev/null`

[ ! "$VERSION" ] && error "[ ] .ruby-version file is missing. Please re-run this script from the project directory once you’ve cloned it with git."

# Copy database config
if [[ ! -s "config/database.yml" ]]
then
  cp config/database.yml{.example,} || error
  notice "[✔] Copied sample database configuration"
fi

# Copy env
if [[ ! -s ".rbenv-vars" ]]
then
  cp config/vars .rbenv-vars || error
  notice "[✔] Copied sample environment variables"
  error "[ ] Please set your environment variables in .rbenv-vars"
fi

# Install Ruby if necessary
if [ "$VERSION" ] && [[ ! -s "$HOME/.rbenv/versions/$VERSION" ]]
then
  ( ~/.rbenv/bin/rbenv install $VERSION && ~/.rbenv/bin/rbenv rehash ) || error
  notice "[✔] Installed Ruby $VERSION"
fi

# Install Postgres if necessary
if ( cat config/database.yml | grep postgresql ) && ! ( [[ -s /Applications/Postgres.app ]] || [[ -s ~/Applications/Postgres.app ]] )
then
  error "[ ] Please install Postgres.app from http://postgresapp.com"
fi

# Make sure Postgres is running
if ( psql -h localhost -l 2>/dev/null )
then
  notice "[✔] Postgres.app running"
else
  error "[ ] Please make sure Postgres.app is running"
fi

# Install bundler
if ( ~/.rbenv/bin/rbenv which bundle )
then
  ( ~/.rbenv/bin/rbenv exec gem update bundler --pre && ~/.rbenv/bin/rbenv rehash ) || error
  notice "[✔] Updated bundler"
else
  ( ~/.rbenv/bin/rbenv exec gem install bundler --pre && ~/.rbenv/bin/rbenv rehash ) || error
  notice "[✔] Installed bundler"
fi

# Install powify
if ( ~/.rbenv/bin/rbenv which powify )
then
  ( ~/.rbenv/bin/rbenv exec gem update powify && ~/.rbenv/bin/rbenv rehash ) || error
  notice "[✔] Updated powify"
else
  ( ~/.rbenv/bin/rbenv exec gem install powify && ~/.rbenv/bin/rbenv rehash ) || error
  notice "[✔] Installed powify"
fi

# Install gems
( ~/.rbenv/bin/rbenv exec bundle check > /dev/null || ~/.rbenv/bin/rbenv exec bundle install --without=production ) || error
notice "[✔] Updated gems"

# Install Heroku
if ( which heroku )
then
  notice "[✔] Heroku Toolbelt installed"
else
  error "[ ] Please install Heroku Toolbelt from https://toolbelt.heroku.com"
fi

# Migrate migrations or run project setup
if ( ~/.rbenv/bin/rbenv exec bundle exec rake db:migrate:status 2>/dev/null )
then
  ( ~/.rbenv/bin/rbenv exec bundle exec rake db:migrate ) || error
  notice "[✔] Ran database migrations"
else
  ( ~/.rbenv/bin/rbenv exec bundle exec rake db:setup ) || error
  notice "[✔] Ran database setup"
fi

# Add to Pow
if [[ ! -s "$HOME/.pow/$NAME" ]]
then
  ln -s "`pwd`" ~/.pow/ || error
  notice "[✔] Added $NAME to Pow"
fi

# Restart Pow
( ~/.rbenv/bin/rbenv exec powify server restart ) && ( ~/.rbenv/bin/rbenv exec powify restart ) || error
notice "[✔] Restarted Pow"

# Wait
( sleep 5s )

# Open project in default browser
open -g http://$NAME.dev
