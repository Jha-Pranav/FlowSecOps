FROM nginx:latest

# Install strace and ltrace
RUN apt update && apt-get install -y strace ltrace

# CMD ["sh", "-c", "strace -f -o /var/log/nginx/strace_output.log -e trace=open,openat,read,write nginx -g 'daemon off;' & ltrace -f -o /var/log/nginx/ltrace_output.log nginx -g 'daemon off;'"]
