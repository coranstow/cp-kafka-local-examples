#!/bin/bash

aws eks update-kubeconfig --region ap-southeast-2 --name eks-cstow-dc0

#aws eks update-kubeconfig --region ap-southeast-2 --name eks-cluster-dc0 --role-arn arn:aws:iam::492737776546:role/ConfluentSAAdminRole
