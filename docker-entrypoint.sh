#!/bin/bash

set -e



#for loop for sourcing all files in vault/secrets

if [ "$(ls -A /vault/secrets)" ]
then
    for FILE in /vault/secrets/*
    do
        echo "sourcing $FILE"
        source $FILE
    done
else 
     echo "Vault secrets directory is empty"
fi

if [ "$(ls -A /app/secrets)" ]
then
    for FILE2 in /app/secrets/*
    do
        echo "sourcing $FILE2"
        source $FILE2
    done
else 
     echo "App secrets directory is empty"
fi

npm start
