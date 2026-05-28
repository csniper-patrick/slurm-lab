# This script automatically generates SSH keys for normal users (UID >= 1000)
# and adds the public key to authorized_keys if it's not already there.
# This facilitates passwordless SSH within the cluster.

# Only run for normal users
if [[ $UID -ge 1000 ]]; then
    # Generate RSA SSH key pair if it doesn't exist
    if [[ ! -f ~/.ssh/id_rsa ]] ; then
            ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N "" ; 
    fi

    # Ensure public key exists
    if [[ ! -f ~/.ssh/id_rsa.pub ]] ; then
            ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub ;
    fi

    # Initialize authorized_keys with the public key if it doesn't exist
    if [[ ! -f ~/.ssh/authorized_keys ]] ; then
            cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys ;
    # Otherwise, append the public key if it's not already present
    elif ! grep -qF "$(cat ~/.ssh/id_rsa.pub)" ~/.ssh/authorized_keys ; then
            cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys ;
    fi
fi
