[[ ! -s .rvmrc ]] && echo "You're not in a project directory (.rvmrc is missing)." && exit

# Install RVM if ~/.rvm doesn't exist
[[ ! -s "$HOME/.rvm/" ]] && curl -s https://rvm.beginrescueend.com/install/rvm -o rvm-installer && sh rvm-installer --version latest && rm rvm-installer

# Attempt to load RVM from .profile
[[ ! $rvm_loaded_flag == 1 ]] && source ~/.profile

# If it hasn't loaded still, add it to .profile and try again
[[ ! $rvm_loaded_flag == 1 ]] && echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' >> ~/.profile && source ~/.profile

# Add bundler to the global gemset
[ ! $(cat ~/.rvm/gemsets/global.gems | grep "bundler") ] && echo "bundler" >> ~/.rvm/gemsets/global.gems

# Determine project name from current directory
project_name=`basename \`pwd\``

# Determine Ruby version that needs to be installed
missing_ruby=`source .rvmrc | grep "rvm install" | sed "s/.*'rvm install \([^']*\)'.*/\1/"`

# Install Ruby if missing
[ $missing_ruby ] && rvm install $missing_ruby

# Select current Ruby version
source .rvmrc

# Install gems
bundle check || bundle install --without production

# Use sample database config
[[ ! -s "config/database.yml" ]] && cp config/database.yml{.example,}

# Load database schema and seeds
bundle exec rake db:setup

# Install Pow if it hasn't been installed yet
[[ ! -s "$HOME/.pow/" ]] && curl get.pow.cx | sh

# Add to Pow
[[ ! -s "$HOME/.pow/$project_name" ]] && ln -s "`pwd`" ~/.pow/

# Open project in default browser
open http://$project_name.dev