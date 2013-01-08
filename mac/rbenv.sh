# Silence STDOUT

exec 1>/dev/null

# Check for LLVM GCC 4.2
GCC=`/usr/bin/gcc --version 2> /dev/null | head -n1 | grep GCC | grep 4.2 | grep LLVM`

# Install GCC
if [ ! "$GCC" ]
then
  echo "[ ] Please install Command Line Tools for Xcode and re-run this script." >&2 && exit
fi

# Install homebrew
if [[ ! -x "/usr/local/bin/brew" ]]
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.github.com/gist/323731)" || exit
  echo "[✔] Installed Homebrew" >&2
else
  /usr/local/bin/brew update || exit
  echo "[✔] Updated Homebrew" >&2
fi

# Install git
if [[ ! -x "/usr/local/bin/git" ]] 
then 
  /usr/local/bin/brew install git || exit
  echo "[✔] Installed git" >&2
else
  /usr/local/bin/brew upgrade git || exit
  echo "[✔] Updated git" >&2
fi

# Attempt to load .profile
if [[ -s "$HOME/.profile" ]]
then 
  source ~/.profile || exit
fi

# Install rbenv
if [[ ! -s "$HOME/.rbenv" ]]
then
  /usr/local/bin/git clone -q git://github.com/sstephenson/rbenv.git ~/.rbenv || exit
  echo "[✔] Installed rbenv" >&2
else
  ( cd ~/.rbenv && /usr/local/bin/git pull -q origin master ) || exit
  echo "[✔] Updated rbenv" >&2
fi

# Install rbenv-vars
if [[ ! -s "$HOME/.rbenv/plugins/rbenv-vars" ]]
then
  mkdir -p ~/.rbenv/plugins
  /usr/local/bin/git clone -q git://github.com/sstephenson/rbenv-vars.git ~/.rbenv/plugins/ || exit
  echo "[✔] Installed rbenv-vars" >&2
else
  ( cd ~/.rbenv/plugins && /usr/local/bin/git pull -q origin master ) || exit
  echo "[✔] Updated rbenv-vars" >&2
fi

# Install ruby-build
if [[ ! -s "$HOME/.ruby-build" ]]
then
  /usr/local/bin/git clone -q git://github.com/sstephenson/ruby-build.git ~/.ruby-build || exit
  echo "[✔] Installed ruby-build" >&2
else
  ( cd ~/.ruby-build && /usr/local/bin/git pull -q origin master ) || exit
  echo "[✔] Updated ruby-build" >&2
fi

# Install Pow if it hasn't been installed yet
if [[ ! -s "$HOME/.pow" ]]
then
  ( curl get.pow.cx | sh ) || exit
  echo "[✔] Installed Pow" >&2
fi

# Add rbenv to .profile
if [[ ! -s "$HOME/.profile" ]] || ! grep -q "rbenv" $HOME/.profile
then
  echo "export PATH=\"$HOME/.rbenv/shims:$HOME/.rbenv/bin:\$PATH"\" >> ~/.profile || exit
fi

# Add ruby-build to .profile
if [[ ! -s "$HOME/.profile" ]] || ! grep -q "ruby-build" $HOME/.profile
then
  echo 'export PATH="$HOME/.ruby-build/bin:$PATH"' >> ~/.profile || exit
fi

# Add rbenv to .powconfig
# See: https://github.com/37signals/pow/issues/202
if [[ ! -s "$HOME/.powconfig" ]] || ! grep -q "rbenv" $HOME/.powconfig
then
  echo "export PATH=\"\$HOME/.rbenv/shims:\$HOME/.rbenv/bin:\$PATH"\" >> ~/.powconfig || exit
fi

# Infer project name
NAME=`basename "\`pwd\`"`

# Detect Ruby version
VERSION=`~/.rbenv/bin/rbenv local 2> /dev/null`

[ ! "$VERSION" ] && echo "[ ] .rbenv-version file missing. Please re-run this script from the project directory once you’ve cloned it with git." >&2 && exit

# Install Ruby if necessary
if [ "$VERSION" ] && [[ ! -s "$HOME/.rbenv/versions/$VERSION" ]]
then
  ( ~/.rbenv/bin/rbenv install $VERSION && ~/.rbenv/bin/rbenv rehash ) || exit
  echo "[✔] Installed Ruby $VERSION" >&2
fi

# Install bundler
if ( ~/.rbenv/bin/rbenv which bundle )
then
  ( ~/.rbenv/bin/rbenv exec gem update bundler --pre && ~/.rbenv/bin/rbenv rehash ) || exit
  echo "[✔] Updated bundler" >&2
else
  ( ~/.rbenv/bin/rbenv exec gem install bundler --pre && ~/.rbenv/bin/rbenv rehash ) || exit
  echo "[✔] Installed bundler" >&2
fi

# Install powify
if ( ~/.rbenv/bin/rbenv which powify )
then
  ( ~/.rbenv/bin/rbenv exec gem update powify && ~/.rbenv/bin/rbenv rehash ) || exit  
  echo "[✔] Updated powify" >&2
else
  ( ~/.rbenv/bin/rbenv exec gem install powify && ~/.rbenv/bin/rbenv rehash ) || exit
  echo "[✔] Installed powify" >&2
fi

# Install gems
( ~/.rbenv/bin/rbenv exec bundle check > /dev/null || ~/.rbenv/bin/rbenv exec bundle install --without=production ) || exit
echo "[✔] Updated gems" >&2

# Copy database config
if [[ ! -s "config/database.yml" ]]
then
  cp config/database.yml{.example,} || exit
  echo "[✔] Copied sample database configuration" >&2
fi

# Copy env
if [[ ! -s ".rbenv-vars" ]]
then
  cp config/vars .rbenv-vars || exit
fi

# Migrate migrations or run project setup
if ( ~/.rbenv/bin/rbenv exec bundle exec rake db:migrate:status 1>/dev/null )
then
  ( ~/.rbenv/bin/rbenv exec bundle exec rake db:migrate ) || exit
  echo "[✔] Ran database migrations" >&2
else
  ( ~/.rbenv/bin/rbenv exec bundle exec rake db:setup ) || exit
  echo "[✔] Ran database setup" >&2
fi

# Add to Pow
if [[ ! -s "$HOME/.pow/$NAME" ]]
then
  ln -s "`pwd`" ~/.pow/ || exit
  echo "[✔] Added ‘$NAME’ to Pow" >&2
fi

# Restart Pow
( ~/.rbenv/bin/rbenv exec powify server restart ) || exit
echo "[✔] Restarted Pow" >&2

# Open project in default browser
open -g http://$NAME.dev
