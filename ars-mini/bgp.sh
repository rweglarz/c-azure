#!/bin/bash


H="azure-ars-mini-sdgw-A1 azure-ars-mini-sdgw-A2 azure-ars-mini-sdgw-B"


echo "$1"
case "$1" in
  ars)
    for h in $H; do
      echo ==== $h
      ssh $h sudo birdc enable '\"ars*\"'
      ssh $h sudo birdc disable '\"peer*\"'
      echo
    done
    ;;

  bird)
    for h in $H; do
      echo ==== $h
      ssh $h sudo birdc disable '\"ars*\"'
      ssh $h sudo birdc enable '\"peer*\"'
      echo
    done
    ;;

  *)
    echo not sure what do you want...
    ;;
esac

