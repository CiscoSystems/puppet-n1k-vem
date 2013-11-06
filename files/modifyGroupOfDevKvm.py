#!/usr/bin/python
import grp, pwd, os, tempfile

fname = '/dev/kvm'
if os.path.isfile(fname) == True:
  log_file = tempfile.NamedTemporaryFile(delete=False)
  stat_info = os.stat(fname)
  uid = stat_info.st_uid
  gid = stat_info.st_gid

  user = pwd.getpwuid(uid)[0]
  group = grp.getgrgid(gid)[0]
  str = "user is " + user + ", group is " + group + "\n"
  log_file.write(str)

  if group == "root":
    log_file.write("group is root\n")
    log_file.write("Doing rmmod kvm_intel kvm\n")
    os.system("rmmod kvm_intel kvm")
    log_file.write("Doing modprobe kvm_intel\n")
    os.system("modprobe kvm_intel")
  else:
    log_file.write("group is not root\n")

  log_file.close()
