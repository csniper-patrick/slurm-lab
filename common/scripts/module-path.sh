# This script snippet configures the module path for Lmod.
# It's intended to be sourced in the user's shell environment.

# Add the project's module directory to the MODULEPATH
module use /opt/modules

# Disable the Lmod pager for a smoother CLI experience
export LMOD_PAGER=None
