# Generating a verification key using your mnemonic
If you want to use an existing wallet for pledging, please follow these instructions. Do your best not to expose any of the generated keys online. 

## Build and exec into the Cardano image

```
docker build -t cardano-node .

mkdir ~/cardano

docker run -it -v ~/cardano:/cardano --name cardano-node cardano-node /bin/bash
```

## Generate a verification key

```
./extractPoolStakingKeys.sh $YOUR_NAME "$YOUR_MNEMONIC_PHRASE"
cd $YOUR_NAME
mv stake.vkey $YOUR_NAME.vkey
```

## Securely send Varderes `$YOUR_NAME.vkey`
