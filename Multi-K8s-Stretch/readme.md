# Multi DC Example using k8s Clusters

This demo is designed to demonstrate the deployment of Confluent Platform stretched across two Kubernetes clusters. This driven by the intersection of two separate business requirements:
1. Standardise everything onto Kubernetes as a common Platform.
2. Stretch Confluent Platform across regions to provide HA/DR. See https://docs.confluent.io/platform/current/multi-dc-deployments/index.html

One of the challenges is that for all its strengths as an application platform, Kubernetes actually gets in the way a bit for middleware systems that are distributed and stateful.

In the case of a single Kubernetes cluster we can use StatefulSets to manage the ZooKeeper and Kafka nodes, each of which must have a distinct ID. When we are stretching the Confluent cluster across multiple Kubernetes Clusters, however, we need to more carefully manage how ZooKeeper and Kafka IDs are created so that they don't collide.

We also have to go to some effort to ensure that all of the nodes in each cluster that need to talk to each other can do so. For this we need to configure our Kubernetes services so that all the nodes can talk to all of the other nodes that they need to talk to.

We do this by creating an externally reachable service for each Node in the hosting Kubernetes Cluster (in this case a LoadBalancer because it's easy enough to demonstrate with, even though the official documentation advises against that) and an ExternalName service for each node in the Kubernetes cluster that does not host that node.

Why even use Kubernetes when this would be much simpler with just some VMs? Well, because sometimes you are told to use Kubernetes and that's all there is to it.

## Assumes
* You have access to one or more Kubernetes Clusters
* You have Clusters admin access to the k8s Clusters

## Prerequisites

This was developed and tested on Kubernetes Clusters on AWS.

1. Helm
2. Kubectl


## Preparation

1. Prepare two Kubernetes clusters, henceforth referred to as `cluster-0` and `cluster-1`.
2. Deploy Confluent Platform to `cluster-0` using the Helm charts at https://github.com/confluentinc/cp-helm-charts.

I don't think the Confluent Operator will support what we're trying to do here, so use Helm for the installation instead of the Confluent Operator.

Note also that there will be an outage for Zookeeper during this process, at least at the point that the StatefulSet restarts to apply the final Zookeeper Hierarchical Quorums setttings. It _might_ be possible to avoid an outage by setting the StatefulSet restart policy to `onDelete` and manually deleting pods in turn and waiting for ZooKeeper to stabilise between deletes.

## Process

There are two Kubernetes clusters to work on in parallel - be prepared for some context switching, or multiple, independent shells.

| **Step** | **cluster-0** | **cluster-1** |
|---|---|---|
| 1 | Deploy the Load Balancer Services<br>`Multi-K8s-Stretch % kubectl apply -f cluster0`<br>`step1-loadbalancer-services.yml`<br>`service/zookeeper-0 created`<br>`service/zookeeper-1 created`<br>`service/zookeeper-2 created` |  |
| 2 | Get the External names of the LB Services for each ZooKeeper Node. <br>`Multi-K8s-Stretch % kubectl get services -n confluent`<br>`NAME                              TYPE           CLUSTER-IP       EXTERNAL-IP                                                            PORT(S)                                        AGE`<br>`confluent-cp-control-center       ClusterIP      10.100.190.198   <none>                                                                         9021/TCP                                       11m`<br>`confluent-cp-kafka                ClusterIP      10.100.199.118   <none>                                                                         9092/TCP,5556/TCP                              11m`<br>`confluent-cp-kafka-connect        ClusterIP      10.100.205.25    <none>                                                                         8083/TCP,5556/TCP                              11m`<br>`confluent-cp-kafka-headless       ClusterIP      None             <none>                                                                         9092/TCP                                       11m`<br>`confluent-cp-kafka-rest           ClusterIP      10.100.38.87     <none>                                                                         8082/TCP,5556/TCP                              11m`<br>`confluent-cp-ksql-server          ClusterIP      10.100.104.135   <none>                                                                         8088/TCP,5556/TCP                              11m`<br>`confluent-cp-schema-registry      ClusterIP      10.100.15.47     <none>                                                                         8081/TCP,5556/TCP                              11m`<br>`confluent-cp-zookeeper            ClusterIP      10.100.56.194    <none>                                                                         2181/TCP,5556/TCP                              11m`<br>`confluent-cp-zookeeper-headless   ClusterIP      None             <none>                                                                         2888/TCP,3888/TCP                              11m`<br>`zookeeper-0                       LoadBalancer   10.100.38.75     a794d70b9c6b149d6af30435cd63ee90-1206107056.ap-southeast-2.elb.amazonaws.com   2181:30300`<br>`TCP,2888:31502/TCP,3888:30572/TCP   6m42s`<br>`zookeeper-1                       LoadBalancer   10.100.170.137   aec688be18d7747d5929828996bd3d88-1662494941.ap-southeast-2.elb.amazonaws.com   2181:30001/TCP,2888:31011/TCP,3888:31615/TCP   6m42s`<br>`zookeeper-2                       LoadBalancer   10.100.176.110   a4b9d8fa9a1384363be3a23aab161839-1023604300.ap-southeast-2.elb.amazonaws.com   2181:32589/TCP,2888:31122/TCP,3888:30464/TCP   6m42s` |  |
| 3 |  | Update the ExtnernalName resources in the `cluster-1` services yaml file to add the endpoints of the `cluster-0` LoadBalancers |
| 4 |  | Deploy the Services yaml file<br>`Multi-K8s-Stretch$ kubectl apply -f cluster1/step4-services.yml`<br>`service/zookeeper-3 created`<br>`service/zookeeper-4 created`<br>`service/zookeeper-5 created`<br>`service/zookeeper-0 created`<br>`service/zookeeper-1 created`<br>`service/zookeeper-2 created`|
| 5 |  | Get the External names of the LB Services for each ZooKeeper Node <br>```Multi-K8s-Stretch$ kubectl get services -n confluent`<br>`NAME          TYPE           CLUSTER-IP       EXTERNAL-IP                                                                    PORT(S)                                        AGE<br>    zookeeper-0   ExternalName   <none>           a794d70b9c6b149d6af30435cd63ee90-1206107056.ap-southeast-2.elb.amazonaws.com   <none>                                         2m39s    zookeeper-1   ExternalName   <none>           aec688be18d7747d5929828996bd3d88-1662494941.ap-southeast-2.elb.amazonaws.com   <none>                                         2m39s    zookeeper-2   ExternalName   <none>           a4b9d8fa9a1384363be3a23aab161839-1023604300.ap-southeast-2.elb.amazonaws.com   <none>                                         2m39s    zookeeper-3   LoadBalancer   10.100.176.202   a286e214220874742bd52914a956c93e-1486539011.ap-northeast-2.elb.amazonaws.com   2181:32358/TCP,2888:31082/TCP,3888:30745/TCP   2m40s    zookeeper-4   LoadBalancer   10.100.158.98    a6a41845f998a4cbc9a8e7e349f427aa-1927252033.ap-northeast-2.elb.amazonaws.com   2181:31086/TCP,2888:30182/TCP,3888:31358/TCP   2m40s    zookeeper-5   LoadBalancer   10.100.174.29    aeea51b96d07548eda29af126f558c3f-1967556870.ap-northeast-2.elb.amazonaws.com   2181:32563/TCP,2888:32456/TCP,3888:30596/TCP   2m39s```|
| 6 | Update the ExternalName resources in the  `cluster-0`  services yaml file to add the endpoints of the  `cluster-1`  LoadBalancers |  |
| 7 | Deploy the ExternalName Services to `cluster-0`: <br>```Multi-K8s-Stretch % kubectl apply -f cluster0/step7-externalname-services.yml    service/zookeeper-3 created    service/zookeeper-4 created    service/zookeeper-5 created```|  |
| 8 | We now have services on both clusters in the form "zookeeper-[0-5]" that refer to the pod name within the StatefulSet.<br>Update the ZooKeeper Stateful set to replace the zookeeper server string with the service names of the LoadBalancer and ExternalName services. This also applies a Hierarchical Quorum setting to the nodes in `cluster-0`, weighted to essentially ignore the nodes in `cluster-1` Expect a ZooKeeper outage as the rolling restart of the Stateful set:<br>```    Multi-K8s-Stretch % kubectl apply -f cluster0/step8-update-zk.yml    statefulset.apps/confluent-cp-zookeeper configured```  |  |
| 9 | Check that after the restart the ensemble is working despite three nodes not existing yet. The Hierarchical Quorums feature will ignore the missing servers for now.|  |
| 10 |  | Create the stateful set in `cluster-1` by applying the yaml file.  As the same Hierarchical Quorum settings are applied to both StatefulSets, these servers should come up as Followers.<br> ```kubectl apply -f cluster1/step10-deploy-zk.yml    poddisruptionbudget.policy/confluent-cp-zookeeper-pdb configured    service/confluent-cp    zookeeper-headless created    service/confluent-cp-zookeeper created    configmap/confluent-cp-zookeeper-jmx-configmap created    statefulset.apps/confluent-cp-zookeeper created```|
| 11 |  | Monitor the stateful set to ensure it has come up. |
| 12 | Update the ZooKeeper Stateful set to set the final zookeeper Hierarchical Quorum settings. Expect an outage while the settings in the two clusters are inconsistent and the StatefulSets are restarting. <br>```Multi-K8s-Stretch % kubectl apply -f cluster0/step12-set-final-hq.yml    statefulset.apps/confluent-cp-zookeeper configured```  | Update the ZooKeeper Stateful set to set the final zookeeper Hierarchical Quorum settings. Expect an outage while the settings in the two clusters are inconsistent and the StatefulSets are restarting.<br> <br>```Multi-K8s-Stretch$ kubectl apply -f cluster1/step12-set-final-hq.yml    statefulset.apps/confluent-cp-zookeeper configured```|
| 13 | Zookeeper should now be available on all nodes.  | Zookeeper should now be available on all nodes. |
