#!/usr/bin/env python3

import os, sys, subprocess

login = os.environ.get('SEMAPHORE_ADMIN')
password = os.environ.get('SEMAPHORE_ADMIN_PASSWORD')
name = os.environ.get('SEMAPHORE_ADMIN_NAME')
email = os.environ.get('SEMAPHORE_ADMIN_EMAIL')

if login is not None and password is not None and name is not None and email is not None:
  try:
    users = subprocess.check_output(["semaphore","user","list"]).decode()
  except Exception as e:
      output = str(e.output)
      print(output)
      raise e
  
  if login in users.split('\n'):
    print("User ",login," already exists", flush=True)
  else:
    print("We do not have user ", login, " yet. Creating...")
    out = subprocess.check_output(["semaphore","user","add","--login",login,"--password",password,"--name",name, "--email",email,"--admin"]).decode()
    print(out, flush=True, end="")
  os.system("semaphore server")
  sys.exit(0)

if login is None and password is None and name is None and email is None:
  os.system("semaphore server")
  sys.exit(0)

print("SEMAPHORE_ADMIN, SEMAPHORE_ADMIN_PASSWORD, SEMAPHORE_ADMIN_NAME and SEMAPHORE_ADMIN_EMAIL environment variables should either be all set or all unset")
sys.exit(1)
