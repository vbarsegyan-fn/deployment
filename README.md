# Generating a verification key using your mnemonic
If you want to use an existing wallet for pledging, please follow these instructions. Do your best not to expose any of the generated keys online. 

## Prerequisites
* Docker running on your local machine

## Build and exec into the Cardano image

```
# this will take a while
docker build -t cardano-node .
mkdir ~/wallet
docker rm cardano-node || true
docker run -it -v ~/wallet:/wallet --name cardano-node cardano-node /bin/bash
```

## Generate a verification key

```
# in the running container
./generateOwnerKeys.sh /wallet/$YOUR_NAME "$YOUR_MNEMONIC_PHRASE"
cd /wallet/$YOUR_NAME
cp stake.vkey $YOUR_NAME.vkey
exit
```

## Securely send Varderes `~/wallet/$YOUR_NAME.vkey`

Store everything in `~/wallet/$YOUR_NAME` somewhere safe.