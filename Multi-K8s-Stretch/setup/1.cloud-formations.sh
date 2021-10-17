#!/bin/bash

# Create Stack in the local region
aws cloudformation create-stack --region ap-southeast-2 --stack-name eks-cstow-vpc-stack --template-url https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml
#{
#    "StackId": "arn:aws:cloudformation:ap-southeast-2:492737776546:stack/eks-cstow-vpc-stack/72dbe840-2d54-11ec-9052-069c0e22aa7c"
#}
# Create stack in a differnt region
aws cloudformation create-stack --region ap-northeast-2 --stack-name eks-cstow-vpc-stack --template-url https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml
#{
#    "StackId": "arn:aws:cloudformation:ap-northeast-2:492737776546:stack/eks-cstow-vpc-stack/aa81b1b0-2d51-11ec-853e-0a6a7510121c"
#}

# Manual create of EKS cluster in each region
# ap-southeast-2 = eks-cluster-dc0
# ap-northeast-2 = eks-cluster-dc1

#Other setup of roles

aws eks update-addon --region ap-southeast-2 --cluster-name eks-cluster-dc0 --addon-name vpc-cni --service-account-role-arn arn:aws:iam::492737776546:role/cstowAmazonEKSClusterRole

aws eks update-addon --region ap-northeast-2 --cluster-name eks-cluster-dc1 --addon-name vpc-cni --service-account-role-arn arn:aws:iam::492737776546:role/cstowAmazonEKSClusterRole 
