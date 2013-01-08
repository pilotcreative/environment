# Check for LLVM GCC 4.2
GCC=`/usr/bin/gcc --version 2> /dev/null | head -n1 | grep GCC | grep 4.2 | grep LLVM`

# Install GCC
if [ ! "$GCC" ]
then
  echo "Please install Command Line Tools for Xcode and re-run this script." && exit
fi

# Install homebrew
if [[ ! -x "/usr/local/bin/brew" ]]
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.github.com/gist/323731)" || exit
else
  /usr/local/bin/brew update || exit
fi

# Install git
if [[ ! -x "/usr/local/bin/git" ]] 
then 
  /usr/local/bin/brew install git || exit
else
  /usr/local/bin/brew upgrade git || exit
fi

# Attempt to load .profile
if [[ -s "$HOME/.profile" ]]
then 
  source ~/.profile || exit
fi

# Install rbenv
if [[ ! -s "$HOME/.rbenv" ]]
then
  /usr/local/bin/git clone git://github.com/sstephenson/rbenv.git ~/.rbenv || exit
else
  ( cd ~/.rbenv && /usr/local/bin/git pull origin master ) || exit
fi

# Install rbenv-vars
if [[ ! -s "$HOME/.rbenv/plugins/rbenv-vars" ]]
then
  mkdir -p ~/.rbenv/plugins
  /usr/local/bin/git clone git://github.com/sstephenson/rbenv-vars.git ~/.rbenv/plugins/ || exit
else
  ( cd ~/.rbenv/plugins && /usr/local/bin/git pull origin master ) || exit
fi

# Install ruby-build
if [[ ! -s "$HOME/.ruby-build" ]]
then
  /usr/local/bin/git clone git://github.com/sstephenson/ruby-build.git ~/.ruby-build || exit
else
  ( cd ~/.ruby-build && /usr/local/bin/git pull origin master ) || exit
fi

# Install Pow if it hasn't been installed yet
if [[ ! -s "$HOME/.pow" ]]
then
  ( curl get.pow.cx | sh ) || exit
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

[ ! "$VERSION" ] && echo ".rbenv-version file missing. Please re-run this script from the project directory once you’ve cloned it with git." && exit

# Install Ruby if necessary
if [ "$VERSION" ] && [[ ! -s "$HOME/.rbenv/versions/$VERSION" ]]
then
  ( ~/.ruby-build/bin/rbenv install $VERSION && ~/.rbenv/bin/rbenv rehash ) || exit
fi

# Install bundler
if [[ ! -s "$HOME/.rbenv/shims/bundle" ]]
then
  ( ~/.rbenv/bin/rbenv exec gem install bundler && ~/.rbenv/bin/rbenv rehash ) || exit
else
  ( ~/.rbenv/bin/rbenv exec gem update bundler && ~/.rbenv/bin/rbenv rehash ) || exit
fi

# Install powify
if [[ ! -s "$HOME/.rbenv/shims/powify" ]]
then
  ( ~/.rbenv/bin/rbenv exec gem install powify && ~/.rbenv/bin/rbenv rehash ) || exit
else
  ( ~/.rbenv/bin/rbenv exec gem update powify && ~/.rbenv/bin/rbenv rehash ) || exit
fi

# Install gems
( ~/.rbenv/bin/rbenv exec bundle check > /dev/null || ~/.rbenv/bin/rbenv exec bundle install --without=production ) || exit

# Copy database config
if [[ ! -s "config/database.yml" ]]
then
  cp config/database.yml{.example,} || exit
fi

# Copy env
if [[ ! -s ".rbenv-vars" ]]
then
  cp config/vars .rbenv-vars || exit
fi

# Run project setup
( ~/.rbenv/bin/rbenv exec bundle exec rake db:setup ) || exit

# Add to Pow
if [[ ! -s "$HOME/.pow/$NAME" ]]
then
  ln -s "`pwd`" ~/.pow/ || exit
fi

# Restart Pow
( ~/.rbenv/bin/rbenv exec powify server restart ) || exit

# Open project in default browser
open -g http://$NAME.dev
