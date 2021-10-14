#!/bin/bash

# Create Stack in the local region
aws cloudformation create-stack --region ap-southeast-2 --stack-name eks-cstow-vpc-stack --template-url https://amazon-eks.s3.ap-southeast-2.amazonaws.com/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml

# Create stack in a differnt region
aws cloudformation create-stack --region ap-southeast-1 --stack-name eks-cstow-vpc-stack --template-url https://amazon-eks.s3.ap-southeast-1.amazonaws.com/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml
