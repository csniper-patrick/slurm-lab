# for normal user only
if [[ $UID -ge 1000 ]]; then
    # Generate ssh key pair if not exist
    if [[ ! -f ~/.ssh/id_rsa ]] ; then
            ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N "" ; 
    fi

    if [[ ! -f ~/.ssh/id_rsa.pub ]] ; then
            ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub ;
    fi

    # Add public to authorized_keys of the file doesnt exist
    if [[ ! -f ~/.ssh/authorized_keys ]] ; then
            cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys ;
    elif [[ $( cat ~/.ssh/authorized_keys ~/.ssh/id_rsa.pub | sort | uniq | wc -l ) -gt $( cat ~/.ssh/authorized_keys | wc -l ) ]] ; then
            cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys ;
    fi
fi
