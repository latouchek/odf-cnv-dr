for i in 0 1 2
do
oc label node ocp4-worker$i.cluster1.lab.local cluster.ocs.openshift.io/openshift-storage=''
oc label node ocp4-worker$i.cluster1.lab.local cluster.ocs.openshift.io/openshift-storage=''
done