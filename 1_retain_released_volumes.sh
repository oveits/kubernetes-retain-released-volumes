
RELEASED_PVS=$(kubectl get pv | grep " Released " | awk '{print $1}')

# install jq, if not already installed:
sudo yum list installed | grep -q jq.x86_64 \
  || sudo yum install jq || exit 1

for VOL in $RELEASED_PVS; do
  VOL_PATH=$(kubectl get pv $VOL -o yaml | grep '^[ ]*path' | awk '{print $2}')
  echo "rm -rf $VOL_PATH/* "
  test -e ${VOL_PATH} && rm -rf ${VOL_PATH}/..?* ${VOL_PATH}/.[!.]* ${VOL_PATH}/*  && test -z "$(ls -A ${VOL_PATH})" || exit 1

  # save and delete the persistent volume:
  kubectl get pv $VOL -o json > pv.json
  kubectl delete -f pv.json

  # to recreate a fresh PV, delete .spec.claimRef and .status from the json:
  cat pv.json | jq 'del(.spec.claimRef)|del(.status)' > pv.reset.json
  kubectl apply -f pv.reset.json
done

rm pv.json pv.reset.json 2>/dev/null
