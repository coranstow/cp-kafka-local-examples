# Multi DC Example using k8s Clusters

This demo is designed to demonstrate the deployment of Confluent Platform stretched across two Kubernetes clusters. This driven by the intersection of two separate business requirements:
1. Standardise everything onto Kubernetes as a common Platform.
2. Stretch Confluent Platform across regions to provide HA/DR. See https://docs.confluent.io/platform/current/multi-dc-deployments/index.html

One of the challenges is that for all its strengths as an application platform, Kubernetes actually gets in the way a bit for middleware systems that are distributed and stateful.

In the case of a single Kubernetes cluster we can use StatefulSets to manage the ZooKeeper and Kafka nodes, each of which must have a distinct ID. When we are stretching the Confluent cluster acres multiple Kubernetes Clusters, however, we need to more carefully manage how ZooKeeper and Kafka IDs are created so that they don't collide.

We also have to go to some effort to ensure that all of the nodes in each cluster that need to talk to each other can do so. For this we need to configure our Kubernetes services so that all the nodes can talk to all f the other nodes that they need to talk to.

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

I don't think the Confluent Operator will support what we're trying to do here, so we'll use Helm for the installation instead of the Confluent Operator.

## Process

There are two Kubernetes clusters to work on in parallel - be prepared for some context switching, or multiple, independent shells.

| **Step** | **cluster-0** | **cluster-1** |
|---|---|---|
| 1 | Deploy the Load Balancer Services<br>`Multi-K8s-Stretch % kubectl apply -f cluster0`<br>`step1-loadbalancer-services.yml`<br>`service/zookeeper-0 created`<br>`service/zookeeper-1 created`<br>`service/zookeeper-2 created` |  |
| 2 | Get the External names of the LB Services for each ZooKeeper Node. <br>`Multi-K8s-Stretch % kubectl get services -n confluent`<br>`NAME                              TYPE           CLUSTER-IP       EXTERNAL-IP                                                            PORT(S)                                        AGE`<br>`confluent-cp-control-center       ClusterIP      10.100.190.198   <none>                                                                         9021/TCP                                       11m`<br>`confluent-cp-kafka                ClusterIP      10.100.199.118   <none>                                                                         9092/TCP,5556/TCP                              11m`<br>`confluent-cp-kafka-connect        ClusterIP      10.100.205.25    <none>                                                                         8083/TCP,5556/TCP                              11m`<br>`confluent-cp-kafka-headless       ClusterIP      None             <none>                                                                         9092/TCP                                       11m`<br>`confluent-cp-kafka-rest           ClusterIP      10.100.38.87     <none>                                                                         8082/TCP,5556/TCP                              11m`<br>`confluent-cp-ksql-server          ClusterIP      10.100.104.135   <none>                                                                         8088/TCP,5556/TCP                              11m`<br>`confluent-cp-schema-registry      ClusterIP      10.100.15.47     <none>                                                                         8081/TCP,5556/TCP                              11m`<br>`confluent-cp-zookeeper            ClusterIP      10.100.56.194    <none>                                                                         2181/TCP,5556/TCP                              11m`<br>`confluent-cp-zookeeper-headless   ClusterIP      None             <none>                                                                         2888/TCP,3888/TCP                              11m`<br>`zookeeper-0                       LoadBalancer   10.100.38.75     a794d70b9c6b149d6af30435cd63ee90-1206107056.ap-southeast-2.elb.amazonaws.com   2181:30300`<br>`TCP,2888:31502/TCP,3888:30572/TCP   6m42s`<br>`zookeeper-1                       LoadBalancer   10.100.170.137   aec688be18d7747d5929828996bd3d88-1662494941.ap-southeast-2.elb.amazonaws.com   2181:30001/TCP,2888:31011/TCP,3888:31615/TCP   6m42s`<br>`zookeeper-2                       LoadBalancer   10.100.176.110   a4b9d8fa9a1384363be3a23aab161839-1023604300.ap-southeast-2.elb.amazonaws.com   2181:32589/TCP,2888:31122/TCP,3888:30464/TCP   6m42s` |  |
| 3 |  | Update the ExtnernalName resources in the `cluster-1` services yaml file to add the endpoints of the `cluster-0` LoadBalancers |
| 4 |  | Deploy the Services yaml file<br>`Multi-K8s-Stretch$ kubectl apply -f cluster1/step4-services.yml`<br>`service/zookeeper-3 created`<br>`service/zookeeper-4 created`<br>`service/zookeeper-5 created`<br>`service/zookeeper-0 created`<br>`service/zookeeper-1 created`<br>`service/zookeeper-2 created`|
| 5 |  | Get the External names of the LB Services for each ZooKeeper Node |
| 6 | Update the ExternalName resources in the  `cluster-0`  services yaml file to add the endpoints of the  `cluster-1`  LoadBalancers |  |
| 7 | Deploy the ExternalName Services to `cluster-0` |  |
| 8 | Update the ZooKeeper Stateful set to replace the zookeeper server string with the service names of the LoadBalancer and ExternalName services. This also applies a Hierarchical Quorum setting to the nodes in `cluster-0`, weighted to essentially ignore the nodes in `cluster-1` Expect a ZooKeeper outage as the rolling restart of the Stateful set  |  |
| 9 | Check that after the restart the ensemble is working despite three nodes not existing yet. |  |
| 10 |  | Create the stateful set in `cluster-1` by applying the yaml file.  Expect that none of the servers actually serve clients yet because they cannot participate in leader elections.  Sending them the 4lw `srvr` should get the response `This ZooKeeper instance is not currently serving requests` |
| 11 |  | Monitor the stateful set to ensure it has come up. |
| 12 | Update the ZooKeeper Stateful set to set the final zookeeper Hierarchical Quorum settings. Expect an outage while the settings in the two clusters are inconsistent.  | Update the ZooKeeper Stateful set to set the final zookeeper Hierarchical Quorum settings. Expect an outage while the settings in the two clusters are inconsistent. |
| 13 | Zookeeper should now be available on all nodes. | Zookeeper should now be available on all nodes. |
