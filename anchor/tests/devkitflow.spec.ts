import * as anchor from '@coral-xyz/anchor'
import {Program} from '@coral-xyz/anchor'
import {Keypair} from '@solana/web3.js'
import {Devkitflow} from '../target/types/devkitflow'

describe('devkitflow', () => {
  // Configure the client to use the local cluster.
  const provider = anchor.AnchorProvider.env()
  anchor.setProvider(provider)
  const payer = provider.wallet as anchor.Wallet

  const program = anchor.workspace.Devkitflow as Program<Devkitflow>

  const devkitflowKeypair = Keypair.generate()

  it('Initialize Devkitflow', async () => {
    await program.methods
      .initialize()
      .accounts({
        devkitflow: devkitflowKeypair.publicKey,
        payer: payer.publicKey,
      })
      .signers([devkitflowKeypair])
      .rpc()

    const currentCount = await program.account.devkitflow.fetch(devkitflowKeypair.publicKey)

    expect(currentCount.count).toEqual(0)
  })

  it('Increment Devkitflow', async () => {
    await program.methods.increment().accounts({ devkitflow: devkitflowKeypair.publicKey }).rpc()

    const currentCount = await program.account.devkitflow.fetch(devkitflowKeypair.publicKey)

    expect(currentCount.count).toEqual(1)
  })

  it('Increment Devkitflow Again', async () => {
    await program.methods.increment().accounts({ devkitflow: devkitflowKeypair.publicKey }).rpc()

    const currentCount = await program.account.devkitflow.fetch(devkitflowKeypair.publicKey)

    expect(currentCount.count).toEqual(2)
  })

  it('Decrement Devkitflow', async () => {
    await program.methods.decrement().accounts({ devkitflow: devkitflowKeypair.publicKey }).rpc()

    const currentCount = await program.account.devkitflow.fetch(devkitflowKeypair.publicKey)

    expect(currentCount.count).toEqual(1)
  })

  it('Set devkitflow value', async () => {
    await program.methods.set(42).accounts({ devkitflow: devkitflowKeypair.publicKey }).rpc()

    const currentCount = await program.account.devkitflow.fetch(devkitflowKeypair.publicKey)

    expect(currentCount.count).toEqual(42)
  })

  it('Set close the devkitflow account', async () => {
    await program.methods
      .close()
      .accounts({
        payer: payer.publicKey,
        devkitflow: devkitflowKeypair.publicKey,
      })
      .rpc()

    // The account should no longer exist, returning null.
    const userAccount = await program.account.devkitflow.fetchNullable(devkitflowKeypair.publicKey)
    expect(userAccount).toBeNull()
  })
})
