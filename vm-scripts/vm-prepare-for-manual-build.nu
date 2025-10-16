use ./util/vm-constants.nu *
use ./session-types/graphene-os/set-up-vm-for-graphene.nu

set-up-vm-for-graphene

"export PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin"
| save --append ~/.bashrc
