'use client'

import {getDevkitflowProgram, getDevkitflowProgramId} from '@project/anchor'
import {useConnection} from '@solana/wallet-adapter-react'
import {Cluster, Keypair, PublicKey} from '@solana/web3.js'
import {useMutation, useQuery} from '@tanstack/react-query'
import {useMemo} from 'react'
import toast from 'react-hot-toast'
import {useCluster} from '../cluster/cluster-data-access'
import {useAnchorProvider} from '../solana/solana-provider'
import {useTransactionToast} from '../ui/ui-layout'

export function useDevkitflowProgram() {
  const { connection } = useConnection()
  const { cluster } = useCluster()
  const transactionToast = useTransactionToast()
  const provider = useAnchorProvider()
  const programId = useMemo(() => getDevkitflowProgramId(cluster.network as Cluster), [cluster])
  const program = getDevkitflowProgram(provider)

  const accounts = useQuery({
    queryKey: ['devkitflow', 'all', { cluster }],
    queryFn: () => program.account.devkitflow.all(),
  })

  const getProgramAccount = useQuery({
    queryKey: ['get-program-account', { cluster }],
    queryFn: () => connection.getParsedAccountInfo(programId),
  })

  const initialize = useMutation({
    mutationKey: ['devkitflow', 'initialize', { cluster }],
    mutationFn: (keypair: Keypair) =>
      program.methods.initialize().accounts({ devkitflow: keypair.publicKey }).signers([keypair]).rpc(),
    onSuccess: (signature) => {
      transactionToast(signature)
      return accounts.refetch()
    },
    onError: () => toast.error('Failed to initialize account'),
  })

  return {
    program,
    programId,
    accounts,
    getProgramAccount,
    initialize,
  }
}

export function useDevkitflowProgramAccount({ account }: { account: PublicKey }) {
  const { cluster } = useCluster()
  const transactionToast = useTransactionToast()
  const { program, accounts } = useDevkitflowProgram()

  const accountQuery = useQuery({
    queryKey: ['devkitflow', 'fetch', { cluster, account }],
    queryFn: () => program.account.devkitflow.fetch(account),
  })

  const closeMutation = useMutation({
    mutationKey: ['devkitflow', 'close', { cluster, account }],
    mutationFn: () => program.methods.close().accounts({ devkitflow: account }).rpc(),
    onSuccess: (tx) => {
      transactionToast(tx)
      return accounts.refetch()
    },
  })

  const decrementMutation = useMutation({
    mutationKey: ['devkitflow', 'decrement', { cluster, account }],
    mutationFn: () => program.methods.decrement().accounts({ devkitflow: account }).rpc(),
    onSuccess: (tx) => {
      transactionToast(tx)
      return accountQuery.refetch()
    },
  })

  const incrementMutation = useMutation({
    mutationKey: ['devkitflow', 'increment', { cluster, account }],
    mutationFn: () => program.methods.increment().accounts({ devkitflow: account }).rpc(),
    onSuccess: (tx) => {
      transactionToast(tx)
      return accountQuery.refetch()
    },
  })

  const setMutation = useMutation({
    mutationKey: ['devkitflow', 'set', { cluster, account }],
    mutationFn: (value: number) => program.methods.set(value).accounts({ devkitflow: account }).rpc(),
    onSuccess: (tx) => {
      transactionToast(tx)
      return accountQuery.refetch()
    },
  })

  return {
    accountQuery,
    closeMutation,
    decrementMutation,
    incrementMutation,
    setMutation,
  }
}
