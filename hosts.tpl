[web1]
${web1} ansible_user=${user} 

[web2]
${web2} ansible_user=${user} 

[apache2:children]
web1
web2
