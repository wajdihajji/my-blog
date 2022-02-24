---
title: "NetApp Trident setup"
date: "2022-02-21"
draft: false
path: "/blog/netapp-trident"
---

To set up NetApp trident to provision volumes on NetApp SVMs, follow the instructions below.

### Create an SVM
```
vserver create -vserver trident-dev-1
```
### Set aggregate list of the created SVM
Replace `<aggregate-name>` with an aggregate name of your choice.
```
vserver modify -vserver trident-dev-1 -aggr-list <aggregate-name>
```

### Create mgt and NFS interfaces
```
network interface create -vserver trident-dev-1 -lif trident-dev-1-mgt -role data -data-protocol none -subnet-name <subnet> -status-admin up -firewall-policy mgmt
network interface create -vserver trident-dev-1 -lif trident-dev-1-nfs -role data -data-protocol nfs -subnet-name <subnet> -status-admin up -firewall-policy data
```

### Create NFS server
```
nfs create -vserver trident-dev-1
```

### Make sure port 443 is open on the mgt interface to the traffic coming from your docker client

### Create a new Trident role
```
security login role create -vserver trident-dev-1 -role trident_role -cmddirname DEFAULT -access none
```
### Grant common Trident permissions
```
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "event generate-autosupport-log" -access all
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "network interface" -access readonly
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "version" -access readonly
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "vserver" -access readonly
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "vserver nfs show" -access readonly
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "volume" -access all
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "snapmirror" -access all
```
### Grant ontap-san Trident permissions
```
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "vserver iscsi show" -access readonly
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "lun" -access all
```
### Grant ontap-nas-economy Trident permissions
```
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "vserver export-policy create" -access all
security login role create -vserver trident-dev-1 -role trident_role -cmddirname "vserver export-policy rule create" -access all
```

### Create a new Trident user with Trident role
```
security login create -vserver trident-dev-1 -username trident_user -role trident_role -application ontapi -authmethod password
```

# Testing

Add the file `/etc/netappdvp/config.json` which should be in the following format:
```json
{
    "version": 1,
    "storageDriverName": "ontap-nas",
    "managementLIF": "mgt-ip",
    "username": "user",
    "password": "password"
}
```
Then, install the NetApp plugin and create a testing volume.
```bash
docker plugin install --grant-all-permissions --alias netapp netapp/trident-plugin:18.07 config=/etc/netappdvp/config.json
docker volume create -d netapp --name firstVolume
```
A volume called `firstVolume` should be created under the SVM `trident-dev-1`.
