. /etc/bash_completion

PS1="\u@[qserv-deploy]:\w # "

# k8s cli helpers
. /etc/kubectl.completion
alias k='kubectl'

alias kshell='kubectl run -i --rm --tty shell --image=busybox --restart=Never -- sh'
